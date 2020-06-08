require_relative "spec_helper"

RSpec.describe Metanorma do
  it "processes metanorma options inside Asciidoc" do
    File.write("test.adoc", ASCIIDOC_PREAMBLE_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    system "metanorma test.adoc"
    expect(File.exist?("test.xml")).to be true
    expect(File.exist?("test.doc")).to be false
    expect(File.exist?("test.html")).to be true
    expect(File.exist?("test.alt.html")).to be false
    xml = File.read("test.xml")
    expect(xml).to include "</iso-standard>"
  end

  it "processes an asciidoc ISO document" do
    File.write("test.adoc", ASCIIDOC_BLANK_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    system "metanorma -t iso test.adoc"
    expect(File.exist?("test.xml")).to be true
    expect(File.exist?("test.doc")).to be true
    expect(File.exist?("test.html")).to be true
    expect(File.exist?("test.alt.html")).to be true
  end

  it "processes all extensions of an asciidoc ISO document" do
    File.write("test.adoc", ASCIIDOC_BLANK_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    system "metanorma -t iso -x all test.adoc"
    expect(File.exist?("test.xml")).to be true
    expect(File.exist?("test.doc")).to be true
    expect(File.exist?("test.html")).to be true
    expect(File.exist?("test.alt.html")).to be true
  end

  it "processes specific extensions of an asciidoc ISO document" do
    File.write("test.adoc", ASCIIDOC_BLANK_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    system "metanorma -t iso -x xml,doc test.adoc"
    expect(File.exist?("test.xml")).to be true
    expect(File.exist?("test.doc")).to be true
    expect(File.exist?("test.html")).to be false
    expect(File.exist?("test.alt.html")).to be false
    xml = File.read("test.xml")
    expect(xml).to include "</iso-standard>"
  end

  it "extracts isodoc options from asciidoc file" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    system "metanorma -t iso -x html test.adoc"
    html = File.read("test.html", encoding: "UTF-8")
    expect(html).to include "font-family: body-font;"
    expect(html).to include "font-family: header-font;"
    expect(html).to include "font-family: monospace-font;"
  end

  it "wraps HTML output" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_rf %w(test test.alt)
    system "metanorma -w -t iso test.adoc"
    expect(File.exist?("test/test.html")).to be true
    expect(File.exist?("test.alt/test.alt.html")).to be true
  end

  it "keeps Asciimath" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_rf %w(test test.alt)
    system "metanorma -a -t iso test.adoc"
    expect(File.exist?("test.xml")).to be true
    xml = File.read("test.xml", encoding: "utf-8")
    expect(xml).not_to include %(<stem type="MathML">)
    expect(xml).to include %(<stem type="AsciiMath">)
  end

  it "data64 encodes images" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_rf %w(test test.alt)
    system "metanorma -d -t iso test.adoc"
    expect(File.exist?("test.html")).to be true
    html = File.read("test.html", encoding: "utf-8")
    expect(html).to include "data:image"
  end

  it "exports bibdata" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_f "testrelaton.xml"
    system "metanorma -R testrelaton.xml -t iso test.adoc"
    expect(File.exist?("testrelaton.xml")).to be true
    xml = File.read("testrelaton.xml", encoding: "utf-8")
    expect(xml).to include %(<bibdata type="standard">)
  end

  it "exports bibdata as rxl" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_f "testrelaton.xml test.rxl"
    system "metanorma -x rxl -t iso test.adoc"
    expect(File.exist?("test.rxl")).to be true
    xml = File.read("test.rxl", encoding: "utf-8")
    expect(xml).to include %(<bibdata type="standard">)
  end

  it "exports assets" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_rf "extract"
    system "metanorma -x xml -t iso -e extract,sourcecode test.adoc"
    expect(File.exist?("extract/image/image-0000.png")).to be false
    expect(File.exist?("extract/sourcecode/sourcecode-0000.txt")).to be true
    expect(File.read("extract/sourcecode/sourcecode-0000.txt", encoding: "utf-8") + "\n").to eq <<~OUTPUT
def ruby(x)
  if x < 0 && x > 1
    return
  end
end
    OUTPUT
  end

  context "with -r option specified" do
    it "loads the libary and compile document" do
      File.write("test.adoc", ASCIIDOC_PREAMBLE_HDR, encoding: "UTF-8")
      FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)

      system "metanorma compile -t iso -r metanorma-iso test.adoc"

      expect(File.exist?("test.xml")).to be true
      expect(File.exist?("test.doc")).to be false
      expect(File.exist?("test.html")).to be true
      expect(File.exist?("test.alt.html")).to be false
      xml = File.read("test.xml")
      expect(xml).to include "</iso-standard>"
    end
  end

  it "non-zero exit code when metanorma compile for missing file" do
    expect(system("metanorma compile not_existing.adoc")).to be false
  end

  it "warns when no standard type provided" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    stdout = `metanorma test.adoc`
    expect(stdout).to include "Please specify a standard type"
  end

  it "warns when bogus standard type requested" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    stdout = `metanorma -t bogus_format test.adoc`
    expect(stdout).to include "loading gem `metanorma-bogus_format` failed. "\
                              "Exiting"
  end

  it "warns when bogus format requested" do
    File.write("test.adoc", ASCIIDOC_CONFIGURED_HDR, encoding: "UTF-8")
    stdout = `metanorma -t iso -f bogus_format test.adoc`
    expect(stdout).to include "Only source file format currently supported "\
                              "is 'asciidoc'"
  end

  it "warns when no file provided" do
    stdout = `metanorma -t iso -x html`
    expect(stdout).to include "Need to specify a file to process"
  end

  it "gives version information" do
    stdout = `metanorma -v -t iso`
    expect(stdout).to match /Metanorma::ISO \d/
  end
end
