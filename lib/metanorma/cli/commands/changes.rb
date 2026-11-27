# frozen_string_literal: true

require "date"
require "json"
require "open3"
require "pathname"
require "yaml"

require_relative "changes/report"
require_relative "changes/source"

module Metanorma
  module Cli
    module Commands
      # Change report for loose-leaf publications (metanorma-cli#495).
      #
      # Editions and amendment states are git tags over one source tree.
      # Each folder under the units directory is one update unit: its
      # sources plus an amendment register (updates.yaml, keyed by unit
      # anchor, as read by Metanorma::Document::UpdateUnits). Between two
      # refs this derives the changed units (the replacement packet), the
      # amendment records each register gained, and, given a collection
      # manifest, the documents that need rebuilding.
      class Changes
        include Source

        EXIT_OK = 0
        EXIT_ERROR = 2
        INCLUDE = /^\s*include::([^\[\s]+)\[/

        def initialize(from, to = nil, options = {})
          @from = from
          @to = to || "HEAD"
          @options = options
          @repo = File.expand_path(options[:repo] || ".")
          @units_dir = clean(options[:units_dir] || "sections")
          @register = options[:register] || "updates.yaml"
        end

        # @return [Integer] exit status (0 report written, 2 error)
        def run(out = $stdout)
          out.puts Report.new(report, @options).render
          EXIT_OK
        rescue StandardError => e
          warn "metanorma changes: #{e.message}"
          EXIT_ERROR
        end

        # The change report as plain data (string keys).
        def report
          [@from, @to].each { |ref| verify_ref(ref) }
          paths = changed_paths
          units = changed_units(paths)
          { "from" => @from, "to" => @to, "units" => units,
            "documents" => affected_documents(paths, units) }.compact
        end

        private

        def changed_paths
          out, ok = git("diff", "--name-only", "-z", @from, @to)
          raise "git diff #{@from} #{@to} failed" unless ok

          out.split("\0").reject(&:empty?)
        end

        # A unit is a folder directly under the units directory; files
        # lying in the units directory itself belong to no unit.
        def changed_units(paths)
          prefix = "#{@units_dir}/"
          paths.filter_map do |p|
            rest = p.delete_prefix(prefix)
            rest.split("/").first if p.start_with?(prefix) && rest.include?("/")
          end.uniq.sort.map { |name| unit_entry(name) }
        end

        def unit_entry(name)
          path = "#{@units_dir}/#{name}"
          { "unit" => name, "path" => path, "status" => unit_status(path),
            "records" => new_records(records_at(@from, path),
                                     records_at(@to, path)) }
        end

        def unit_status(path)
          was = exists_at?(@from, path)
          now = exists_at?(@to, path)
          return "added" unless was
          return "removed" unless now

          "modified"
        end

        # Records present at TO and not at FROM, by anchor and sequence.
        def new_records(before, after)
          seen = before.to_set { |r| record_key(r) }
          after.reject { |r| seen.include?(record_key(r)) }
            .sort_by { |r| [r["sequence"].to_i, r["anchor"]] }
        end

        def record_key(record)
          [record["anchor"], record["sequence"].to_s]
        end

        def affected_documents(paths, units)
          manifest = @options[:manifest] or return nil
          changed = Changed.new(paths, units.map { |u| "#{u['path']}/" })
          documents(manifest).filter_map do |doc|
            hits = sources(doc).select { |s| changed.include?(s) }
            { "file" => doc, "sources" => hits.sort } unless hits.empty?
          end
        end

        # A source counts as changed when the file itself changed, or
        # when it lies in a changed unit folder: the folder is the update
        # unit, so a register change alone affects the unit's sources.
        Changed = Struct.new(:paths, :dirs) do
          def initialize(paths, dirs)
            super(paths.to_set, dirs)
          end

          def include?(source)
            paths.include?(source) || dirs.any? { |d| source.start_with?(d) }
          end
        end

        # Document files named by the collection manifest (any "fileref"
        # at any depth), resolved against the manifest's folder.
        def documents(manifest)
          text = show(@to, clean(manifest)) or
            raise "no collection manifest #{manifest} at #{@to}"
          base = File.dirname(clean(manifest))
          filerefs(YAML.safe_load(text, permitted_classes: [Date]))
            .map { |f| clean(File.join(base, f)) }.uniq
        end

        def filerefs(node)
          case node
          when Hash then node.flat_map { |k, v| fileref(k, v) }
          when Array then node.flat_map { |v| filerefs(v) }
          else []
          end
        end

        def fileref(key, value)
          return [value] if key.to_s == "fileref" && value.is_a?(String)

          filerefs(value)
        end

        # The file and everything it includes, transitively, at TO.
        # Include targets built from attribute references cannot be
        # resolved here and are skipped.
        def sources(file, seen = Set.new)
          return seen if seen.include?(file)

          seen << file
          text = show(@to, file) or return seen
          text.scan(INCLUDE).flatten.each do |target|
            next if target.include?("{")

            sources(clean(File.join(File.dirname(file), target)), seen)
          end
          seen
        end
      end
    end
  end
end
