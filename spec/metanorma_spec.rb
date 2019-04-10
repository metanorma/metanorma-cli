require_relative "spec_helper"

RSpec.describe 'Metanorma', :type => :aruba do
  let(:file) { 'test.adoc' }
  let(:content) { '' }
  before(:each) {
    %w(test.xml test.html test.alt.html test.doc).each do |p|
      FileUtils.rm_f expand_path(p)
    end
  }

  context "processes metanorma options inside Asciidoc" do
    before do
      file = 'test.adoc'
      write_file(file, ASCIIDOC_PREAMBLE_HDR)
      run_command("metanorma #{file}")
    end

    it "creates proper output" do
      aggregate_failures do
        expect(last_command_started).to be_successfully_executed
        expect(last_command_started).to have_output(/Processing/)
        expect(exist?("test.xml")).to be true
        expect(exist?("test.html")).to be true
        expect(exist?("test.doc")).to be false
        expect(exist?("test.alt.html")).to be false
        expect("test.xml").to have_file_content Regexp.new("</iso-standard>")
      end
    end

  end

  context "file with blank header" do

    context "processes an asciidoc ISO document" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_BLANK_HDR)
        run_command("metanorma -t iso #{file}")
      end

      it "creates proper output" do
        aggregate_failures do
          expect(last_command_started).to be_successfully_executed
          expect(last_command_started).to have_output(/Processing/)
          expect(exist?("test.xml")).to be true
          expect(exist?("test.doc")).to be true
          expect(exist?("test.html")).to be true
          expect(exist?("test.alt.html")).to be true
        end
      end
    end

    context "processes all extensions of an asciidoc ISO document" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_BLANK_HDR)
        run_command("metanorma -t iso -x all #{file}")
      end

      it "creates proper output" do
        aggregate_failures do
          expect(last_command_started).to be_successfully_executed
          expect(last_command_started).to have_output(/Processing/)
          expect(exist?("test.xml")).to be true
          expect(exist?("test.doc")).to be true
          expect(exist?("test.html")).to be true
          expect(exist?("test.alt.html")).to be true
        end
      end
    end

    context "processes specific extensions of an asciidoc ISO document" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_BLANK_HDR)
        run_command("metanorma -t iso -x xml,doc #{file}")
      end

      it "creates proper output" do
        aggregate_failures do
          expect(last_command_started).to be_successfully_executed
          expect(exist?("test.xml")).to be true
          expect(exist?("test.doc")).to be true
          expect(exist?("test.html")).to be false
          expect(exist?("test.alt.html")).to be false
          expect("test.xml").to have_file_content Regexp.new("</iso-standard>")
        end
      end
    end

  end

  context "file with configured header" do

    context "extracts isodoc options from Asciidoc file" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_CONFIGURED_HDR)
        run_command("metanorma -t iso -x html #{file}")
      end

      let(:html) { 'test.html' }
      it "creates proper output" do
        aggregate_failures do
          expect(last_command_started).to be_successfully_executed
          expect(exist?(html)).to be true
          expect(html).to have_file_content Regexp.new("font-family: body-font;")
          expect(html).to have_file_content Regexp.new("font-family: header-font;")
          expect(html).to have_file_content Regexp.new("font-family: monospace-font;")
        end
      end

    end

    context "wraps HTML output" do
      before do
        %w(test test.alt).each do |f|
          FileUtils.rm_rf expand_path(f)
        end
        file = 'test.adoc'
        write_file(file, ASCIIDOC_CONFIGURED_HDR)
        run_command("metanorma -w -t iso #{file}")
      end

      it "wraps with directories" do
        aggregate_failures do
          expect(last_command_started).to be_successfully_executed
          expect(exist?("test/test.html")).to be true
          expect(exist?("test.alt/test.alt.html")).to be true
        end
      end
    end

    context "keeps Asciimath" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_CONFIGURED_HDR)
        run_command("metanorma -a -t iso #{file}")
      end

      let(:xml) { 'test.xml' }

      it "retains AsciiMath in files" do
        aggregate_failures do
          expect(last_command_started).to be_successfully_executed
          expect(exist?(xml)).to be true
          expect(xml).not_to have_file_content %(<stem type="MathML">)
          expect(xml).to have_file_content Regexp.new("<stem type=\"AsciiMath\">")
        end
      end
    end

    context "data64 encodes images" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_CONFIGURED_HDR)
        run_command("metanorma -d -t iso #{file}")
      end

      let(:html) { 'test.html' }

      it "encodes images" do
        aggregate_failures do
          expect(last_command_started).to be_successfully_executed
          expect(exist?(html)).to be true
          expect(html).to have_file_content /data:image/
        end
      end
    end

    context "exports bibdata" do
      before do
        FileUtils.rm_f expand_path("testrelaton.xml")
        file = 'test.adoc'
        write_file(file, ASCIIDOC_CONFIGURED_HDR)
        run_command("metanorma -R testrelaton.xml -t iso #{file}")
      end

      let(:xml) { 'testrelaton.xml' }
      it "generates Relaton file" do
        aggregate_failures do
          expect(last_command_started).to be_successfully_executed
          expect(exist?(xml)).to be true
          expect(xml).to have_file_content Regexp.new("<bibdata type=\"article\">")
        end
      end
    end

    context "exports bibdata as rxl" do
      before do
        %w(testrelaton.xml test.rxl).each do |f|
          FileUtils.rm_f f
        end
        file = 'test.adoc'
        write_file(file, ASCIIDOC_CONFIGURED_HDR)
        run_command("metanorma -x rxl -t iso #{file}")
      end

      let(:xml) { 'test.rxl' }
      it "generates Relaton file in RXL format" do
        aggregate_failures do
          expect(last_command_started).to be_successfully_executed
          expect(exist?(xml)).to be true
          expect(xml).to have_file_content Regexp.new("<bibdata type=\"article\">")
        end
      end

    end

    context "exports assets" do
      before do
        FileUtils.rm_rf "extract"
        file = 'test.adoc'
        write_file(file, ASCIIDOC_CONFIGURED_HDR)
        run_command("metanorma -x xml -t iso -e extract,sourcecode #{file}")
      end

      EXPECTED_CONTENT = <<~EOS
      def ruby(x)
        if x < 0 && x > 1
          return
        end
      end
      EOS

      it "extracts assets in specified folder" do
        aggregate_failures do
          expect(exist?("extract/image/image-0000.png")).to be false

          # TODO: Fix this functionality
          puts "extract/sourcecode/sourcecode-0000.txt"
          puts `ls -alR #{expand_path("extract")}`
          expect(exist?("extract/sourcecode/sourcecode-0000.txt")).to be true
          expect("extract/sourcecode/sourcecode-0000.txt").to have_file_content EXPECTED_CONTENT
        end
      end

    end

  end

  context "with invalid options" do

    context "warns when no standard type provided" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_BLANK_HDR)
        run_command("metanorma #{file}")
      end

      it "displays error" do
        expect(last_command_started).to have_output(/Please specify a standard type/)
      end
    end

    context "warns when bogus standard type requested" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_BLANK_HDR)
        run_command("metanorma -t bogus_format #{file}")
      end

      it "displays error" do
        expect(last_command_started).to have_output(/bogus_format is not a default standard type/)
      end
    end

    context "warns when bogus format requested" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_BLANK_HDR)
        run_command("metanorma -t iso -f bogus_format #{file}")
      end

      it "displays error" do
        expect(last_command_started).to have_output(/Only source file format currently supported is 'asciidoc'/)
      end
    end

    context "warns when bogus extension requested" do
      before do
        file = 'test.adoc'
        write_file(file, ASCIIDOC_BLANK_HDR)
        run_command("metanorma -t iso -x bogus_format #{file}")
      end

      it "displays error" do
        expect(last_command_started).to have_output(/bogus_format format is not supported for this standard/)
      end
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
