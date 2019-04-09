require_relative "spec_helper"

RSpec.describe 'Metanorma', :type => :aruba do
  let(:file) { 'test.adoc' }
  let(:content) { '' }
  before(:each) { FileUtils.rm_f %w(test.xml test.html test.alt.html test.doc) }

  context "processes metanorma options inside Asciidoc" do
    let(:content) { ASCIIDOC_PREAMBLE_HDR }
    before(:each) { write_file file, content }
    before(:each) { run_command("metanorma #{file}") }

    it { expect(last_command_started).to have_output(/Processing/) }
    it { expect(exist?("test.xml")).to be true           }
    it { expect(exist?("test.doc")).to be false          }
    it { expect(exist?("test.html")).to be true          }
    it { expect(exist?("test.alt.html")).to be false     }
    it { expect("test.xml").to have_file_content Regexp.new("</iso-standard>") }
  end

  context "file with blank header" do

    context "processes an asciidoc ISO document" do
      let(:content) { ASCIIDOC_BLANK_HDR }
      before(:each) { write_file file, content }
      before(:each) { run_command("metanorma -t iso #{file}") }
      it { expect(exist?("test.xml")).to be true }
      it { expect(exist?("test.doc")).to be true }
      it { expect(exist?("test.html")).to be true }
      it { expect(exist?("test.alt.html")).to be true }
    end

    context "processes all extensions of an asciidoc ISO document" do
      let(:content) { ASCIIDOC_BLANK_HDR }
      before(:each) { write_file file, content }
      before(:each) { run_command("metanorma -t iso -x all #{file}") }
      it { expect(exist?("test.xml")).to be true }
      it { expect(exist?("test.doc")).to be true }
      it { expect(exist?("test.html")).to be true }
      it { expect(exist?("test.alt.html")).to be true }
    end

    context "processes specific extensions of an asciidoc ISO document" do
      let(:content) { ASCIIDOC_BLANK_HDR }
      before(:each) { write_file file, content }
      before(:each) { run_command("metanorma -t iso -x xml,doc #{file}") }
      it { expect(exist?("test.xml")).to be true }
      it { expect(exist?("test.doc")).to be true }
      it { expect(exist?("test.html")).to be false }
      it { expect(exist?("test.alt.html")).to be false }
      it { expect("test.xml").to have_file_content Regexp.new("</iso-standard>") }
    end

  end

  context "file with configured header" do

    context "extracts isodoc options from Asciidoc file" do
      let(:content) { ASCIIDOC_CONFIGURED_HDR }
      before(:each) { write_file file, content }
      before(:each) { run_command("metanorma -t iso -x html #{file}") }
      let(:html) { 'test.html' }
      it { expect(html).to have_file_content Regexp.new("font-family: body-font;") }
      it { expect(html).to have_file_content Regexp.new("font-family: header-font;") }
      it { expect(html).to have_file_content Regexp.new("font-family: monospace-font;") }
    end

    context "wraps HTML output" do
      let(:content) { ASCIIDOC_CONFIGURED_HDR }
      before(:each) { write_file file, content }
      before(:each) { FileUtils.rm_rf %w(test test.alt) }
      before(:each) { run_command("metanorma -w -t iso #{file}") }
      it { expect(exist?("test/test.html")).to be true }
      it { expect(exist?("test.alt/test.alt.html")).to be true }
    end

    context "keeps Asciimath" do
      let(:content) { ASCIIDOC_CONFIGURED_HDR }
      before(:each) { write_file file, content }
      before(:each) { FileUtils.rm_f %w(test test.alt) }
      before(:each) { run_command("metanorma -a -t iso #{file}") }
      let(:xml) { 'test.xml' }
      it { expect(exist?("test.xml")).to be true }
      it { expect(xml).not_to have_file_content %(<stem type="MathML">) }
      it { expect(xml).to have_file_content Regexp.new("<stem type=\"AsciiMath\">") }
    end

    context "data64 encodes images" do
      let(:content) { ASCIIDOC_CONFIGURED_HDR }
      before(:each) { write_file file, content }
      before(:each) { FileUtils.rm_f %w(test test.alt) }
      before(:each) { run_command("metanorma -d -t iso #{file}") }
      let(:html) { 'test.html' }
      it { expect(exist?("test.html")).to be true }
      it { expect(html).to have_file_content /data:image/ }
    end

    context "exports bibdata" do
      let(:content) { ASCIIDOC_CONFIGURED_HDR }
      before(:each) { write_file file, content }
      before(:each) { FileUtils.rm_f %w(testrelaton.xml) }
      before(:each) { run_command("metanorma -R testrelaton.xml -t iso #{file}") }
      let(:xml) { 'testrelaton.xml' }
      it { expect(exist?("testrelaton.xml")).to be true }
      it { expect(xml).to have_file_content Regexp.new("<bibdata type=\"article\">") }
    end

    context "exports bibdata as rxl" do
      let(:content) { ASCIIDOC_CONFIGURED_HDR }
      before(:each) { write_file file, content }
      before(:each) { FileUtils.rm_f %w(testrelaton.xml test.rxl) }
      before(:each) { run_command("metanorma -x rxl -t iso #{file}") }
      let(:xml) { 'test.rxl' }
      it { expect(exist?("test.rxl")).to be true }
      it { expect(xml).to have_file_content Regexp.new("<bibdata type=\"article\">") }
    end

    context "exports assets" do
      let(:content) { ASCIIDOC_CONFIGURED_HDR }
      before(:each) { write_file file, content }
      before(:each) { FileUtils.rm_rf %w(extract) }
      before(:each) { run_command("metanorma -x xml -t iso -e extract,sourcecode #{file}") }
      it { expect(exist?("extract/image/image-0000.png")).to be false }
      it { expect(exist?("extract/sourcecode/sourcecode-0000.txt")).to be true }
      it {
        expect(File.read("extract/sourcecode/sourcecode-0000.txt", encoding: "utf-8") + "\n").to eq <<~OUTPUT
  def ruby(x)
    if x < 0 && x > 1
      return
    end
  end
      OUTPUT
      }

    end

    context "warns when no standard type provided" do
      let(:content) { ASCIIDOC_BLANK_HDR }
      before(:each) { write_file file, content }
      before(:each) { run_command("metanorma #{file}") }
      it { expect(last_command_started).to have_output(/Please specify a standard type/) }
    end

    context "warns when bogus standard type requested" do
      let(:content) { ASCIIDOC_BLANK_HDR }
      before(:each) { write_file file, content }
      before(:each) { run_command("metanorma -t bogus_format #{file}") }
      it { expect(last_command_started).to have_output(/bogus_format is not a default standard type/) }
    end

    context "warns when bogus format requested" do
      let(:content) { ASCIIDOC_BLANK_HDR }
      before(:each) { write_file file, content }
      before(:each) { run_command("metanorma -t iso -f bogus_format #{file}") }
      it { expect(last_command_started).to have_output(/Only source file format currently supported is 'asciidoc'/) }
    end

    context "warns when bogus extension requested" do
      let(:content) { ASCIIDOC_BLANK_HDR }
      before(:each) { write_file file, content }
      before(:each) { run_command("metanorma -t iso -x bogus_format #{file}") }
      it { expect(last_command_started).to have_output(/bogus_format format is not supported for this standard/) }
    end
  end

  context "warns when no file provided" do
    before(:each) { run_command("metanorma -t iso -x html") }
    it { expect(last_command_started).to have_output(/Need to specify a file to process/) }
  end

  context "gives version information" do
    before(:each) { run_command("metanorma -v -t iso") }
    it { expect(last_command_started).to have_output(/Metanorma::ISO/) }
  end

end
