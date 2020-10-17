require "spec_helper"

RSpec.describe "Metanorma" do
  describe "site generate" do
    it "generate a mini site" do
      source_path = Metanorma::Cli.root_path.join("tmp")

      command = %W(site generate #{source_path})
      Metanorma::Cli.start(command)
    end
  end
end
