RSpec.describe "Config" do
  before :each do
    @test_config = tmp_dir.join(Metanorma::Cli::CONFIG_FILENAME)
    FileUtils.rm_f(@test_config)

    allow(Metanorma::Cli).to receive(:config_path).and_return(@test_config)
    expect(Metanorma::Cli).to receive(:config_path)
  end

  it "get creates config if not exists" do
    config_cli = Metanorma::Cli::Commands::Config.new

    config_cli.get("arg1")

    expect(File.exist?(@test_config)).to be true
  end

  it "print whole config" do
    config_cli = Metanorma::Cli::Commands::Config.new

    config_cli.get

    expect(File.exist?(@test_config)).to be true
  end

  it "set -> get" do
    config_cli = Metanorma::Cli::Commands::Config.new

    config_cli.set("cli.agree_to_terms", "true")

    output = capture_stdout { config_cli.get("cli.agree_to_terms") }

    expect(output).to eq("true\n")

    expect(File.exist?(@test_config)).to be true
  end

  it "set -> unset -> get" do
    config_cli = Metanorma::Cli::Commands::Config.new

    config_cli.set("cli.agree_to_terms", "true")
    config_cli.unset("cli.agree_to_terms")

    output = capture_stdout { config_cli.get("cli.agree_to_terms") }

    expect(output).to eq("nil\n")

    expect(File.exist?(@test_config)).to be true
  end

  it "config values have bigger priority then args" do
    config_cli = Metanorma::Cli::Commands::Config.new
    config_cli.set("cli.agree_to_terms", "true")
    config_cli.set("cli.install_fonts", "true")
    config_cli.set("cli.continue_without_fonts", "true")

    result = Metanorma::Cli::Commands::Config.load_configs(
      { agree_to_terms: false,
        install_fonts: true,
        continue_without_fonts: false },
      [@test_config],
    )

    expect(result[:agree_to_terms]).to be true
    expect(result[:install_fonts]).to be true
    expect(result[:continue_without_fonts]).to be true
  end
end
