require "spec_helper"

RSpec.describe "Metanorma" do
  describe "setup" do
    context "without existing fonts" do
      it "downlaods user's fonts as specified" do
        stub_system_home_directory
        command = %w(setup --agree-to-terms)
        Metanorma::Cli.start(command)

        expect(installed_fonts.count).to be >= required_fonts.count
        expect(installed_fonts.grep(/#{required_fonts.first}/i)).not_to be_empty
      end
    end
  end

  def required_fonts
    Metanorma::Cli::REQUIRED_FONTS
  end

  def installed_fonts
    Metanorma::Cli.fonts
  end
end
