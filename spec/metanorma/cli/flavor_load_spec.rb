require "metanorma/cli"

RSpec.describe Metanorma::Flavor do
  describe "#load_flavors" do
    it "degrades a flavor gem that raises NameError at require time" do
      instance = loader_with_flavors(["metanorma-ogc"])
      allow(instance).to receive(:require)
        .and_raise(NameError, "uninitialized constant Relaton::Render::Parse")
      expect(Metanorma::Cli::UI).to receive(:error)
        .with("[metanorma] Error: flavor gem metanorma-ogc is not present!")

      expect { instance.load_flavors }.not_to raise_error
    end

    it "degrades a flavor gem that raises LoadError at require time" do
      instance = loader_with_flavors(["metanorma-ietf"])
      allow(instance).to receive(:require).and_raise(LoadError, "cannot load")
      expect(Metanorma::Cli::UI).to receive(:error)
        .with("[metanorma] Error: flavor gem metanorma-ietf is not present!")

      expect { instance.load_flavors }.not_to raise_error
    end

    private

    def loader_with_flavors(gems)
      instance = described_class.new
      def instance.set_test_flavors(gems)
        @flavors = gems
      end
      instance.set_test_flavors(gems)
      instance
    end
  end
end
