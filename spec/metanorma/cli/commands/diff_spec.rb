require "spec_helper"

RSpec.describe Metanorma::Cli::Commands::Diff do
  let(:fixtures) { File.join(Dir.pwd, "spec", "fixtures", "diff") }
  let(:base) { File.join(fixtures, "base.xml") }
  let(:cosmetic) { File.join(fixtures, "cosmetic.xml") }
  let(:changed) { File.join(fixtures, "changed.xml") }

  after { Canon::Config.reset! if defined?(Canon::Config) }

  def run_diff(file1, file2, options = {})
    out = StringIO.new
    status = described_class.new(file1, file2, options).run(out)
    [status, out.string]
  end

  it "reports a cosmetically different document as equivalent" do
    status, output = run_diff(base, cosmetic)
    expect(status).to eq 0
    expect(output).to include("Equivalent")
  end

  it "reports a semantic change with a non-zero status" do
    status, output = run_diff(base, changed, color: false)
    expect(status).to eq 1
    expect(output).to include("gadget")
  end

  it "emits a machine-readable JSON report" do
    status, output = run_diff(base, changed, format: "json")
    expect(status).to eq 1
    report = JSON.parse(output)
    expect(report["equivalent"]).to be false
    expect(report["normative_count"]).to be > 0
    expect(report["differences"]).to be_an(Array)
    expect(report["differences"].first).to include("path", "normative")
  end

  it "rejects an input format canon cannot parse" do
    exp = File.join(fixtures, "sample.exp")
    File.write(exp, "SCHEMA synthetic;\nEND_SCHEMA;\n")
    status, = run_diff(exp, exp)
    expect(status).to eq 2
  ensure
    File.delete(exp) if File.exist?(exp)
  end

  it "returns the error status for a missing file" do
    status, = run_diff(base, File.join(fixtures, "nonexistent.xml"))
    expect(status).to eq 2
  end
end
