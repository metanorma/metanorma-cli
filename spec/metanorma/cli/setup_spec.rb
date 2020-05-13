require "spec_helper"

RSpec.describe Metanorma::Cli::Setup do
  describe ".run" do
    context "with existing fonts" do
      it "copy overs the existing fonts" do
        font_name = "Consola.ttf"
        stub_system_home_directory

        Metanorma::Cli::Setup.run(font: font_name)

        expect(Metanorma::Cli.fonts.grep(/#{font_name}/i)).not_to be_nil
      end
    end

    context "with downloadale font" do
      it "downloads and copy over the font" do
        stub_system_home_directory
        font_name = "CALIBRI.TTF"
        Metanorma::Cli::Setup.run(font: "CALIBRI.TTF")

        expect(Metanorma::Cli.fonts.grep(/#{font_name}/i)).not_to be_nil
      end
    end
  end
end
