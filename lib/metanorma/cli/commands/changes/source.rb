# frozen_string_literal: true

require "date"
require "open3"
require "pathname"
require "yaml"

module Metanorma
  module Cli
    module Commands
      class Changes
        # Reads publication sources and amendment registers at a git ref.
        # Shared by `metanorma changes` and `metanorma amendments`; the
        # including class sets @repo and @register.
        module Source
          private

          def records_at(ref, unit_path)
            file = "#{unit_path}/#{@register}"
            text = show(ref, file) or return []
            data = YAML.safe_load(text, permitted_classes: [Date]) || {}
            unless data.is_a?(Hash)
              raise "#{ref}:#{file}: update register must be keyed by " \
                    "unit anchor"
            end

            data.flat_map { |anchor, entry| unit_records(anchor, entry, file) }
          end

          # An entry is either the list of records, or a mapping of unit
          # fields whose "records" key holds the list.
          def unit_records(anchor, entry, file)
            list = entry.is_a?(Hash) ? entry["records"] : entry
            Array(list).map do |r|
              raise "#{file}: #{anchor}: malformed amendment record" unless
                r.is_a?(Hash)

              plain(r).merge("anchor" => anchor.to_s)
            end
          end

          def verify_ref(ref)
            _, ok = git("rev-parse", "--verify", "--quiet", "#{ref}^{commit}")
            raise "unknown git ref #{ref} in #{@repo}" unless ok
          end

          def exists_at?(ref, path)
            git("cat-file", "-e", "#{ref}:#{path}").last
          end

          def show(ref, path)
            out, ok = git("show", "#{ref}:#{path}")
            ok ? out : nil
          end

          def git(*)
            out, status = Open3.capture2("git", "-C", @repo, *,
                                         err: File::NULL)
            [out, status.success?]
          end

          def clean(path)
            Pathname.new(path).cleanpath.to_s
          end

          # Dates become ISO strings so the report serialises the same way
          # in YAML and JSON.
          def plain(value)
            case value
            when Hash then value.to_h { |k, v| [k.to_s, plain(v)] }
            when Array then value.map { |v| plain(v) }
            when Date then value.iso8601
            else value
            end
          end
        end
      end
    end
  end
end
