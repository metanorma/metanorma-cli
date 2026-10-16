require "metanorma/cli"

RSpec.describe Metanorma::Flavor do
  describe "#load_flavors" do
    it "degrades a flavor gem that raises NameError at require time" do
      allow(Bundler).to receive(:load)
        .and_return(Struct.new(:specs).new([]))
      instance = loader_with_flavors(["metanorma-ogc"])
      allow(instance).to receive(:require)
        .and_raise(NameError, "uninitialized constant Relaton::Render::Parse")
      expect(Metanorma::Cli::UI).to receive(:error)
        .with("[metanorma] Error: flavor gem metanorma-ogc is not present!")

      expect { instance.load_flavors }.not_to raise_error
    end

    it "degrades a flavor gem that raises LoadError at require time" do
      allow(Bundler).to receive(:load)
        .and_return(Struct.new(:specs).new([]))
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

RSpec.describe Metanorma::Flavor do
  describe "#load_flavors with bundled private flavors" do
    it "requires bundled metanorma-* flavor gems it does not name" do
      spec = Struct.new(:name).new("metanorma-private-example")
      plugin = Struct.new(:name).new("metanorma-plugin-lutaml")
      helper = Struct.new(:name).new("metanorma-utils")
      engine = Struct.new(:name).new("metanorma")
      mko = Struct.new(:name).new("metanorma-mko")
      ietf_data = Struct.new(:name).new("metanorma-ietf-data")
      bundler_specs = [spec, plugin, helper, engine, mko, ietf_data]
      bundler = Struct.new(:specs).new(bundler_specs)
      allow(Bundler).to receive(:load).and_return(bundler)

      instance = described_class.new
      required = []
      allow(instance).to receive(:require) { |name| required << name }

      instance.load_flavors

      expect(required).to include("metanorma-private-example")
      expect(required).not_to include("metanorma-mko", "metanorma-ietf-data")
      expect(required).not_to include("metanorma-utils")
      expect(required).not_to include("metanorma-plugin-lutaml")
      expect(required).not_to include("metanorma")
    end
  end
end
