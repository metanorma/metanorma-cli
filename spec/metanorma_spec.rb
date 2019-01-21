require_relative "spec_helper"

RSpec.describe Metanorma do
  it "processes metanorma options inside Asciidoc" do
    File.open("test.adoc", "w:UTF-8") { |f| f.write(ASCIIDOC_PREAMBLE_HDR) }
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
    File.open("test.adoc", "w:UTF-8") { |f| f.write(ASCIIDOC_BLANK_HDR) }
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    system "metanorma -t iso test.adoc"
    expect(File.exist?("test.xml")).to be true
    expect(File.exist?("test.doc")).to be true
    expect(File.exist?("test.html")).to be true
    expect(File.exist?("test.alt.html")).to be true
  end

  it "processes all extensions of an asciidoc ISO document" do
    File.open("test.adoc", "w:UTF-8") { |f| f.write(ASCIIDOC_BLANK_HDR) }
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    system "metanorma -t iso -x all test.adoc"
    expect(File.exist?("test.xml")).to be true
    expect(File.exist?("test.doc")).to be true
    expect(File.exist?("test.html")).to be true
    expect(File.exist?("test.alt.html")).to be true
  end

  it "processes specific extensions of an asciidoc ISO document" do
    File.open("test.adoc", "w:UTF-8") { |f| f.write(ASCIIDOC_BLANK_HDR) }
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
    File.open("test.adoc", "w:UTF-8") { |f| f.write(ASCIIDOC_CONFIGURED_HDR) }
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    system "metanorma -t iso -x html test.adoc"
    html = File.read("test.html")
    expect(html).to include "font-family: body-font;"
    expect(html).to include "font-family: header-font;"
    expect(html).to include "font-family: monospace-font;"
  end

  it "wraps HTML output" do
    File.open("test.adoc", "w:UTF-8") { |f| f.write(ASCIIDOC_CONFIGURED_HDR) }
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_rf %w(test test.alt)
    system "metanorma -w -t iso test.adoc"
    expect(File.exist?("test/test.html")).to be true
    expect(File.directory?("test/test_images")).to be true
    expect(File.exist?("test.alt/test.alt.html")).to be true
    expect(File.directory?("test.alt/test.alt_images")).to be true
  end

  it "data64 encodes images" do
    File.open("test.adoc", "w:UTF-8") { |f| f.write(ASCIIDOC_CONFIGURED_HDR) }
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_rf %w(test test.alt)
    system "metanorma -d -t iso test.adoc"
    expect(File.exist?("test.html")).to be true
    html = File.read("test.html", encoding: "utf-8")
    expect(html).to include "data:image"
  end

  it "exports bibdata" do
    File.open("test.adoc", "w:UTF-8") { |f| f.write(ASCIIDOC_CONFIGURED_HDR) }
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_f "testrelaton.xml"
    system "metanorma -R testrelaton.xml -t iso test.adoc"
    expect(File.exist?("testrelaton.xml")).to be true
    xml = File.read("testrelaton.xml", encoding: "utf-8")
    expect(xml).to include %(<bibdata type="article">)
  end

  it "exports bibdata as rxl" do
    File.open("test.adoc", "w:UTF-8") { |f| f.write(ASCIIDOC_CONFIGURED_HDR) }
    FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc)
    FileUtils.rm_f "testrelaton.xml testrelaton.rxl"
    system "metanorma -x rxl -t iso test.adoc"
    expect(File.exist?("testrelaton.rxl")).to be true
    xml = File.read("testrelaton.rxl", encoding: "utf-8")
    expect(xml).to include %(<bibdata type="article">)
  end

end


RSpec.describe "warns when no standard type provided" do
  file "test.adoc", ASCIIDOC_CONFIGURED_HDR
  command "metanorma test.adoc"
  its(:stdout) { is_expected.to include "Please specify a standard type" }
end

RSpec.describe "warns when bogus standard type requested" do
  file "test.adoc", ASCIIDOC_CONFIGURED_HDR
  command "metanorma -t bogus_format test.adoc"
  its(:stdout) { is_expected.to include "bogus_format is not a default standard type" }
end

RSpec.describe "warns when bogus format requested" do
  file "test.adoc", ASCIIDOC_CONFIGURED_HDR
  command "metanorma -t iso -f bogus_format test.adoc"
  its(:stdout) { is_expected.to include "Only source file format currently supported is 'asciidoc'" }
end

RSpec.describe "warns when bogus extension requested" do
  file "test.adoc", ASCIIDOC_CONFIGURED_HDR
  command "metanorma -t iso -x bogus_format test.adoc"
  its(:stdout) { is_expected.to include "bogus_format format is not supported for this standard" }
end

RSpec.describe "warns when no file provided" do
  command "metanorma -t iso -x html"
  its(:stdout) { is_expected.to include "Need to specify a file to process" }
end

RSpec.describe "gives version information" do
  command "metanorma -v -t iso"
  its(:stdout) { is_expected.to match(/Metanorma::ISO \d/) }
end

