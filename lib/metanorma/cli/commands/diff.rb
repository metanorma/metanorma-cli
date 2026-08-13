require "json"

module Metanorma
  module Cli
    module Commands
      # Semantic diff of two Metanorma XML documents, with lutaml/canon
      # as the diff engine (metanorma-cli#442, iso-10303
      # drift-tracking). Returns an exit status instead of exiting, so
      # in-process callers (and specs) stay alive; the Thor command
      # decides the process exit.
      class Diff
        EXIT_EQUIVALENT = 0
        EXIT_DIFFERENT = 1
        EXIT_ERROR = 2

        def initialize(file1, file2, options = {})
          @file1 = file1
          @file2 = file2
          @options = options
        end

        # @return [Integer] exit status (0 equivalent / 1 different /
        #   2 error); output goes to the given IO (default $stdout)
        def run(out = $stdout)
          return EXIT_ERROR unless files_exist?

          require "canon"
          configure_canon
          result = compare_documents
          out.puts render(result)
          result.equivalent? ? EXIT_EQUIVALENT : EXIT_DIFFERENT
        rescue StandardError => e
          warn "metanorma diff: #{e.class}: #{e.message}"
          EXIT_ERROR
        end

        private

        def files_exist?
          [@file1, @file2].all? do |f|
            File.file?(f) ||
              (warn("metanorma diff: no such file: #{f}") && false)
          end
        end

        # The canon "metanorma" configuration profile is the default:
        # spec-friendly matching, metanorma whitespace element lists,
        # normative-only display. --profile selects another canon
        # profile (built-in name or a YAML path).
        def configure_canon
          Canon::Config.reset!
          Canon::Config.instance.profile = @options[:profile] || :metanorma
        end

        # rubocop:disable Naming/PredicateMethod -- verbose: true makes
        # equivalent? return a full ComparisonResult, not a boolean
        def compare_documents
          opts = { verbose: true }
          if (mp = @options[:match_profile])
            opts[:match_profile] = mp.to_sym
          end
          Canon::Comparison.equivalent?(
            File.read(@file1, encoding: "UTF-8"),
            File.read(@file2, encoding: "UTF-8"),
            opts,
          )
        end
        # rubocop:enable Naming/PredicateMethod

        def render(result)
          case @options[:format]&.downcase
          when "json" then render_json(result)
          else render_text(result)
          end
        end

        def render_text(result)
          return result.diff(**text_diff_opts) unless result.equivalent?

          info = result.informative_differences.size
          return "Equivalent" if info.zero?

          msg = "Equivalent (#{info} informative difference(s) — " \
                "rerun with --show-diffs informative to view)"
          if @options[:show_diffs].to_s == "informative"
            "#{msg}\n#{result.diff(**text_diff_opts)}"
          else
            msg
          end
        end

        def text_diff_opts
          diff_opts = { use_color: color? }
          if (cl = @options[:context_lines])
            diff_opts[:context_lines] = cl.to_i
          end
          if (sd = @options[:show_diffs])
            diff_opts[:show_diffs] = sd.to_sym
          end
          diff_opts
        end

        def color?
          return false if @options[:color] == false

          $stdout.tty?
        end

        # canon has no machine-readable report; serialise its DiffNode
        # list ourselves — the shape iso-10303 CI can consume
        def diff_to_h(diff)
          { dimension: diff.dimension, reason: diff.reason,
            path: diff.path, normative: diff.normative?,
            before: diff.serialized_before, after: diff.serialized_after }
        end

        def render_json(result)
          diffs = result.differences.map { |d| diff_to_h(d) }
          JSON.pretty_generate(
            files: { a: @file1, b: @file2 },
            equivalent: result.equivalent?,
            normative_count: diffs.count { |d| d[:normative] },
            informative_count: diffs.count { |d| !d[:normative] },
            differences: diffs,
          )
        end
      end
    end
  end
end
