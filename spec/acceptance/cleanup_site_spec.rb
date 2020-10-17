require "spec_helper"

RSpec.describe "Metanorma" do
  describe "site cleanup" do
    # @TODO Revisit this test once geneation is done
    #
    it "remove all generated assets" do
      command = %w(site cleanup)
      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("@TODO")
    end
  end
end
