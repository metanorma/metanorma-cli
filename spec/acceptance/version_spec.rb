require "spec_helper"

RSpec.describe "Metanorma" do
  describe "version" do
    context "with argument" do
      # rubocop:disable RSpec/MultipleExpectations
      it "display version for that backend" do
        command = %w(version -t iso)
        output = capture_stdout { Metanorma::Cli.start(command) }

        expect(output).to include("Metanorma::Iso #{Metanorma::Iso::VERSION}")
        expect(output).not_to include("Metanorma::Cc #{Metanorma::Cc::VERSION}")
        expect(output).not_to match /html2doc \d\.\d/
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "without any argument" do
      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it "display version for dependencies" do
        command = %w(version)
        output = capture_stdout { Metanorma::Cli.start(command) }

        expect(output).to include("Metanorma #{Metanorma::VERSION}")
        expect(output).to include("Metanorma::Cli #{Metanorma::Cli::VERSION}")
        expect(output).to include("Metanorma::Iso #{Metanorma::Iso::VERSION}")
        expect(output).to include("Metanorma::Cc #{Metanorma::Cc::VERSION}")
        expect(output).to include("Metanorma::Ietf #{Metanorma::Ietf::VERSION}")
        expect(output).to match /html2doc \d\.\d/
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

      it "reports a version for every installed dependency gem" do
        output = capture_stdout { Metanorma::Cli.start(%w(version)) }
        missing = installed_dependency_gems
          .reject { |g| output.match?(/^#{Regexp.escape(g)} \d/) }
        expect(missing).to be_empty
      end

      it "not raise error about dependencies" do
        command = %w(version)
        output = capture_stderr { Metanorma::Cli.start(command) }

        expect(output).not_to include("is not present")
      end
    end
  end

  # only gems actually present can be expected in the listing: a fresh
  # resolve may legitimately omit some (e.g. emf2svg platform gems)
  def installed_dependency_gems
    Metanorma::Cli::Command::DEPENDENCY_GEMS.select do |g|
      Gem.loaded_specs.key?(g) || gem_installed?(g)
    end
  end

  def gem_installed?(name)
    Gem::Specification.find_by_name(name)
    true
  rescue Gem::LoadError
    false
  end
end
