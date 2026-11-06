require "metanorma/cli"
require "tmpdir"
require "fileutils"

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
      spec = Struct.new(:name).new("metanorma-nist")
      plugin = Struct.new(:name).new("metanorma-plugin-lutaml")
      helper = Struct.new(:name).new("metanorma-utils")
      engine = Struct.new(:name).new("metanorma")
      bundler_specs = [spec, plugin, helper, engine]
      bundler = Struct.new(:specs).new(bundler_specs)
      allow(Bundler).to receive(:load).and_return(bundler)

      instance = described_class.new
      required = []
      allow(instance).to receive(:require) { |name| required << name }

      instance.load_flavors

      expect(required).to include("metanorma-nist")
      expect(required).not_to include("metanorma-utils")
      expect(required).not_to include("metanorma")
    end

    it "requires bundled metanorma-plugin-* gems by their gem name" do
      required = load_with_bundled("metanorma-plugin-sirena")

      expect(required).to include("metanorma-plugin-sirena")
    end

    it "skips a bundled plugin that has no gem-name entry file" do
      expect { load_with_bundled("metanorma-plugin-nofile", missing: true) }
        .not_to raise_error
    end

    private

    def load_with_bundled(name, missing: false)
      specs = [Struct.new(:name).new(name)]
      allow(Bundler).to receive(:load)
        .and_return(Struct.new(:specs).new(specs))
      instance = described_class.new
      required = []
      allow(instance).to receive(:require) do |gem_name|
        raise LoadError, "cannot load #{gem_name}" if missing

        required << gem_name
      end
      instance.load_flavors
      required
    end
  end

  describe "#load_flavors with broken bundled plugins" do
    # Real require of throwaway entry files: a plugin that is broken in
    # any way must not abort the CLI nor stop later plugins loading.
    let(:plugin_dir) { Dir.mktmpdir }

    before do
      $LOAD_PATH.unshift(plugin_dir)
      $bundled_plugin_probe = []
      allow(Metanorma::Cli::UI).to receive(:debug)
    end

    after do
      $LOAD_PATH.delete(plugin_dir)
      FileUtils.remove_entry(plugin_dir)
      $bundled_plugin_probe = nil
    end

    {
      "a RuntimeError" => "raise 'boom at require'",
      "a SyntaxError" => "def (",
      "a Gem::MissingSpecError" =>
        "raise Gem::MissingSpecError.new('x', Gem::Requirement.default)",
      "a NameError" => "UndefinedPluginConstant",
    }.each do |label, body|
      it "survives a plugin raising #{label} and still loads the rest" do
        write_plugin("metanorma-plugin-bad", body)
        write_plugin("metanorma-plugin-good", "$bundled_plugin_probe << :good")

        names = %w[metanorma-plugin-bad metanorma-plugin-good]
        expect { load_with_bundled(names) }
          .to change { $bundled_plugin_probe }.from([]).to([:good])
      end
    end

    it "loads a plugin once even when something already required it" do
      write_plugin("metanorma-plugin-twice", "$bundled_plugin_probe << :twice")
      require "metanorma-plugin-twice"

      load_with_bundled(%w[metanorma-plugin-twice metanorma-plugin-twice])

      expect($bundled_plugin_probe).to eq([:twice])
    end

    it "never requires non-plugin gems through the plugin loader" do
      write_plugin("other-plugin-thing", "$bundled_plugin_probe << :other")

      load_with_bundled(%w[other-plugin-thing])

      expect($bundled_plugin_probe).to be_empty
    end

    it "loads plugins from the installed gems when Bundler cannot load" do
      write_plugin("metanorma-plugin-fallback", "$bundled_plugin_probe << :fb")
      allow(Bundler).to receive(:load).and_raise(Bundler::GemfileNotFound)
      stub_installed_gems(%w[metanorma-plugin-fallback])

      new_loader.load_flavors

      expect($bundled_plugin_probe).to eq([:fb])
    end

    private

    def write_plugin(name, body)
      File.write(File.join(plugin_dir, "#{name}.rb"), body)
    end

    def load_with_bundled(names)
      stub_bundle(names)
      new_loader.load_flavors
    end

    def stub_installed_gems(names)
      allow(Gem::Specification).to receive(:find_all)
        .and_return(names.map { |name| Struct.new(:name).new(name) })
    end

    def new_loader
      described_class.new.tap do |instance|
        allow(instance).to receive(:require).and_call_original
        allow(instance).to receive(:require).with(/\Ametanorma-(?!plugin)/)
      end
    end

    def stub_bundle(names)
      specs = names.map { |name| Struct.new(:name).new(name) }
      allow(Bundler).to receive(:load)
        .and_return(Struct.new(:specs).new(specs))
    end
  end
end
