require "yaml"
require "spec_helper"

RSpec.describe "Metanorma" do
  describe "template-repo add" do
    it "adds a new template to metanorma config" do
      stub_system_home_directory

      command = %w(template-repo add my-iso -y https://github.com/metanorma/mn-iso)
      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Template repo: my-iso has been added successfully")
    end

    it "returns error for duplicate template" do
      stub_system_home_directory

      command = %w(template-repo add my-iso https://github.com/metanorma/mn-iso)
      output = capture_stderr { Metanorma::Cli.start(command) }

      expect(output).to include("Duplicate metanorma template")
    end
  end
end
