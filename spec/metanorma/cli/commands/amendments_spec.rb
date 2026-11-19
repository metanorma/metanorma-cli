require "spec_helper"
require "json"
require "open3"
require "tmpdir"
require "yaml"

# metanorma-iho#581: states older than the git tags exist only as
# amendment records; `metanorma amendments` folds them to amendment N.
RSpec.describe Metanorma::Cli::Commands::Amendments do
  let(:repo) { Dir.mktmpdir("loose-leaf") }

  after { FileUtils.rm_rf(repo) }

  def write(path, content)
    file = File.join(repo, path)
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, content)
  end

  def git(*args)
    _, err, status = Open3.capture3(
      "git", "-C", repo, "-c", "user.name=Spec", "-c",
      "user.email=spec@example.com", "-c", "commit.gpgsign=false",
      "-c", "tag.gpgsign=false", *args
    )
    raise err unless status.success?
  end

  def record(sequence, summary)
    { "sequence" => sequence, "date" => Date.new(2019, sequence, 1),
      "reference" => "CL #{sequence}/2019",
      "summary" => [{ "language" => "en", "content" => summary },
                    { "language" => "fr", "content" => "FR #{summary}" }] }
  end

  def run_amendments(options)
    out = StringIO.new
    status = described_class.new("ed9", options.merge(repo: repo)).run(out)
    [status, out.string]
  end

  def report(options)
    described_class.new("ed9", options.merge(repo: repo)).report
  end

  # A legacy edition: B-100 amended by 1 and 3, B-200 by 2, B-300 never.
  before do
    git("init", "-q")
    write("sections/b-100/en.adoc", "== B-100\n")
    write("sections/b-100/updates.yaml",
          YAML.dump("B-100" => { "records" => [record(3, "Third"),
                                               record(1, "First")] }))
    write("sections/b-200/en.adoc", "== B-200\n")
    write("sections/b-200/updates.yaml",
          YAML.dump("B-200" => [record(2, "Second")]))
    write("sections/b-300/en.adoc", "== B-300\n")
    git("add", "-A")
    git("commit", "-q", "-m", "ed9")
    git("tag", "ed9")
  end

  it "reports the base publication at amendment 0" do
    data = report(upto: "0")

    expect(data).to include("upto" => 0, "last_amendment" => 3,
                            "anchors" => [])
  end

  it "folds the records up to amendment N" do
    data = report(upto: "2")

    expect(data["anchors"].map { |a| [a["anchor"], a["unit"]] })
      .to eq([%w[B-100 b-100], %w[B-200 b-200]])
    expect(data["anchors"].first["records"].map { |r| r["sequence"] })
      .to eq([1])
    expect(data["anchors"].first["records"].first)
      .to include("date" => "2019-01-01", "reference" => "CL 1/2019")
  end

  it "reports only what changed after --since" do
    data = report(since: "1", upto: "3")

    expect(data["anchors"].to_h do |a|
      [a["anchor"], a["records"].map { |r| r["sequence"] }]
    end).to eq("B-100" => [3], "B-200" => [2])
  end

  it "prints the state as text in the chosen language" do
    status, out = run_amendments(upto: "3", language: "fr")

    expect(status).to eq(0)
    expect(out).to include("State at amendment 3 (ed9)",
                           "Units amended: 2",
                           "B-100 #3 2019-03-01 CL 3/2019: FR Third")
  end

  it "writes the same data as YAML and JSON" do
    _, yaml = run_amendments(since: "1", upto: "2", format: "yaml")
    _, json = run_amendments(since: "1", upto: "2", format: "json")

    expect(YAML.safe_load(yaml)).to eq(JSON.parse(json))
    expect(JSON.parse(json)["anchors"].map { |a| a["anchor"] })
      .to eq(["B-200"])
  end

  it "rejects a bad amendment number with status 2" do
    status = nil
    expect { status, = run_amendments(upto: "two") }
      .to output(/--upto must be an amendment number/).to_stderr
    expect(status).to eq(2)

    expect { status, = run_amendments(since: "3", upto: "1") }
      .to output(/--since 3 is after --upto 1/).to_stderr
    expect(status).to eq(2)
  end

  it "rejects an unknown ref with status 2" do
    out = StringIO.new
    status = nil
    expect do
      status = described_class.new("nope", upto: "1", repo: repo).run(out)
    end.to output(/unknown git ref nope/).to_stderr
    expect(status).to eq(2)
  end
end
