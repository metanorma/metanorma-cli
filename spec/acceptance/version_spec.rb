require "spec_helper"

RSpec.describe "Metanorma" do
  describe "version" do
    context "with argument" do
      it "display version for that backend" do
        command = %w(version -t iso)
        output = capture_stdout { Metanorma::Cli.start(command) }

        expect(output).to include("Metanorma::Iso #{Metanorma::Iso::VERSION}")
        expect(output).not_to include("Metanorma::Cc #{Metanorma::Cc::VERSION}")
        expect(output).not_to match /html2doc \d\.\d/
      end
    end

    context "without any argument" do
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

      it "not raise error about dependencies" do
        command = %w(version)
        output = capture_stderr { Metanorma::Cli.start(command) }

        expect(output).not_to match /is not present/
      end
    end
  end
end
