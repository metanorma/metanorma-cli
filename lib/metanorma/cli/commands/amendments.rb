# frozen_string_literal: true

require_relative "changes"

module Metanorma
  module Cli
    module Commands
      # Publication state at an amendment number (metanorma-iho#581).
      #
      # Git-era states are checkouts and are compared with
      # `metanorma changes`. Older states exist only as amendment records:
      # this reads every unit's register at one ref and folds the records
      # up to amendment N with Metanorma::Iho::Amendment.fold. With a
      # second amendment number it reports what changed between the two
      # states.
      class Amendments
        include Changes::Source

        EXIT_OK = 0
        EXIT_ERROR = 2

        def initialize(ref, options = {})
          @ref = ref
          @options = options
          @repo = File.expand_path(options[:repo] || ".")
          @units_dir = clean(options[:units_dir] || "sections")
          @register = options[:register] || "updates.yaml"
        end

        # @return [Integer] exit status (0 report written, 2 error)
        def run(out = $stdout)
          out.puts Changes::Report.new(report, @options).render
          EXIT_OK
        rescue StandardError => e
          warn "metanorma amendments: #{e.message}"
          EXIT_ERROR
        end

        # The state report as plain data (string keys).
        def report
          upto, since = targets
          verify_ref(@ref)
          records = all_records
          target = fold(records, upto)
          base = since && fold(records, since)
          { "ref" => @ref, "since" => since, "upto" => upto,
            "last_amendment" => amendment.max_sequence(records),
            "anchors" => anchors(target, base) }.compact
        end

        private

        # Anchors amended at the target state, or, with --since, the
        # anchors that gained records after the earlier state (their at-N
        # form differs from their at-M form).
        def anchors(target, base)
          target.anchors.filter_map do |anchor|
            records = target.history(anchor)
            records = records.drop(base.history(anchor).size) if base
            next if records.empty?

            { "anchor" => anchor,
              "unit" => target.effective(anchor).payload[:unit],
              "records" => records.map { |r| entry(r) } }.compact
          end
        end

        def fold(records, upto)
          amendment.fold(records, upto: upto)
        end

        # The fold keeps payload keys as symbols; the report uses the
        # register's string keys.
        def entry(record)
          payload = record.payload.except(:unit).transform_keys(&:to_s)
          { "anchor" => record.anchor, "sequence" => record.sequence }
            .merge(payload)
        end

        # Records of every unit at REF; each carries its unit folder as
        # payload so the report can name the replacement-packet unit.
        def all_records
          units.flat_map do |name|
            records_at(@ref, "#{@units_dir}/#{name}")
              .map { |r| r.merge("unit" => name) }
          end
        end

        def units
          out, ok = git("ls-tree", "-d", "--name-only", @ref,
                        "#{@units_dir}/")
          raise "no units directory #{@units_dir} at #{@ref}" unless ok

          out.lines.map { |l| File.basename(l.chomp) }.reject(&:empty?).sort
        end

        def targets
          upto = amendment_number(@options[:upto], "--upto")
          since = @options[:since] &&
            amendment_number(@options[:since], "--since")
          raise "--since #{since} is after --upto #{upto}" if
            since && since > upto

          [upto, since]
        end

        def amendment_number(value, flag)
          raise "#{flag} needs an amendment number" if value.nil?

          Integer(value.to_s, 10).tap do |n|
            raise "#{flag} must be 0 or more, got #{n}" if n.negative?
          end
        rescue ArgumentError
          raise "#{flag} must be an amendment number, got #{value.inspect}"
        end

        # The fold ships with metanorma-iho (#583); it is loaded on its
        # own, without the flavor.
        def amendment
          @amendment ||= begin
            require "metanorma/iho/amendment"
            Metanorma::Iho::Amendment
          rescue LoadError
            raise "metanorma amendments needs metanorma-iho >= 1.4.4 " \
                  "(Metanorma::Iho::Amendment)"
          end
        end
      end
    end
  end
end
