require "spec_helper"
require "json"
require "open3"
require "tmpdir"
require "yaml"

RSpec.describe Metanorma::Cli::Commands::Changes do
  let(:repo) { Dir.mktmpdir("loose-leaf") }
  let(:first) { record(1, "4.9.0", "CL 30/2021", "Editorial corrections") }
  let(:second) { record(2, "4.10.0", "CL 12/2026", "New B-410") }

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

  def commit_and_tag(tag)
    git("add", "-A")
    git("commit", "-q", "-m", tag)
    git("tag", tag)
  end

  def record(sequence, edition, reference, summary)
    { "sequence" => sequence, "edition" => edition,
      "date" => Date.new(2026, sequence, 1), "reference" => reference,
      "summary" => [{ "language" => "en", "content" => summary },
                    { "language" => "fr", "content" => "FR #{summary}" }] }
  end

  def register(anchor, *records)
    YAML.dump(anchor => { "identifier" => "S-4 Part B, #{anchor}",
                          "records" => records })
  end

  def run_changes(from, to, options = {})
    out = StringIO.new
    status = described_class.new(from, to, options.merge(repo: repo)).run(out)
    [status, out.string]
  end

  before do
    git("init", "-q")
    docrefs = [{ "fileref" => "part-b/document.adoc" },
               { "fileref" => "part-c/document.adoc" }]
    write("collection.yml",
          YAML.dump("manifest" => { "level" => "collection",
                                    "docref" => docrefs }))
    write("part-b/document.adoc",
          "= Part B\n\ninclude::../sections/b-400/en.adoc[]\n" \
          "include::../sections/b-500/en.adoc[]\n")
    write("part-c/document.adoc", "= Part C\n\ninclude::{sections}/c.adoc[]\n")
    write("sections/b-400/en.adoc", "== Section 400\n\nText.\n")
    write("sections/b-400/updates.yaml", register("B-400", first))
    write("sections/b-500/en.adoc", "== Section 500\n\nText.\n")
    write("sections/README.adoc", "Unit index\n")
    commit_and_tag("ed10")
  end

  context "with an amendment touching one unit" do
    before do
      write("sections/b-400/en.adoc", "== Section 400\n\nNew B-410.\n")
      write("sections/b-400/updates.yaml", register("B-400", second, first))
      write("sections/README.adoc", "Unit index, amended\n")
      commit_and_tag("ed10-amd1")
    end

    it "reports the changed unit and the record it gained" do
      report = described_class.new("ed10", "ed10-amd1", repo: repo).report
      expect(report["units"].map { |u| u["unit"] }).to eq ["b-400"]
      unit = report["units"].first
      expect(unit["status"]).to eq "modified"
      expect(unit["records"].map { |r| r["sequence"] }).to eq [2]
      expect(unit["records"].first).to include(
        "anchor" => "B-400", "reference" => "CL 12/2026",
        "date" => "2026-02-01"
      )
      expect(report).not_to have_key("documents")
    end

    it "lists the documents to rebuild from the collection manifest" do
      report = described_class.new("ed10", "ed10-amd1",
                                   repo: repo,
                                   manifest: "collection.yml").report
      expect(report["documents"]).to eq [
        { "file" => "part-b/document.adoc",
          "sources" => ["sections/b-400/en.adoc"] },
      ]
    end

    it "writes a text report with summaries in the chosen language" do
      status, output = run_changes("ed10", "ed10-amd1", language: "fr")
      expect(status).to eq 0
      expect(output).to include("Update units changed: 1")
      expect(output).to include("b-400 (modified) sections/b-400")
      expect(output).to include("B-400 #2 4.10.0 2026-02-01 CL 12/2026: " \
                                "FR New B-410")
    end

    it "writes YAML and JSON reports" do
      _, yaml = run_changes("ed10", "ed10-amd1", format: "yaml")
      _, json = run_changes("ed10", "ed10-amd1", format: "json")
      expect(YAML.safe_load(yaml)).to eq JSON.parse(json)
      expect(JSON.parse(json)["to"]).to eq "ed10-amd1"
    end
  end

  it "flags a unit changed without a new amendment record" do
    write("sections/b-500/en.adoc", "== Section 500\n\nFixed.\n")
    commit_and_tag("ed10-amd1")
    _, output = run_changes("ed10", "ed10-amd1")
    expect(output).to include("b-500 (modified)")
    expect(output).to include("no new amendment record")
  end

  it "reports added and removed units" do
    FileUtils.rm_rf(File.join(repo, "sections/b-500"))
    write("sections/b-600/en.adoc", "== Section 600\n")
    write("sections/b-600/updates.yaml", register("B-600", first))
    commit_and_tag("ed11")
    report = described_class.new("ed10", "ed11", repo: repo).report
    expect(report["units"].to_h { |u| [u["unit"], u["status"]] })
      .to eq("b-500" => "removed", "b-600" => "added")
  end

  it "fails on an unknown ref" do
    status = nil
    expect { status, = run_changes("ed10", "no-such-tag") }
      .to output(/unknown git ref no-such-tag/).to_stderr
    expect(status).to eq 2
  end

  it "fails on a register not keyed by anchor" do
    write("sections/b-500/updates.yaml", YAML.dump([first]))
    commit_and_tag("ed10-amd1")
    status = nil
    expect { status, = run_changes("ed10", "ed10-amd1") }
      .to output(/must be keyed by unit anchor/).to_stderr
    expect(status).to eq 2
  end
end
