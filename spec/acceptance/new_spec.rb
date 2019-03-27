require "spec_helper"

RSpec.describe "Metanorma" do
  describe "new document" do
    it "creates a new metanorma document" do
      allow(Metanorma::Cli::Generator).to receive(:run)

      command = %w(new -t iso -d standard ./tmp/my-iso-doc)
      capture_stdout { Metanorma::Cli.start(command) }

      expect(Metanorma::Cli::Generator).to have_received(:run)
    end
  end
end
