require_relative "spec_helper"
require "tmpdir"

RSpec.describe Metanorma do
  before :all do
    # @dir = Dir.mktmpdir("metanorma_spec")
    @dir = tmp_directory
    spec_assets_path = tmp_directory.join("spec")

    FileUtils.mkdir_p(spec_assets_path)
    FileUtils.cp_r("spec/assets", spec_assets_path)
  end

  after :each do
    cleanup_test_files
    # Dir.chdir(@dir) do
    #   FileUtils.rm_f %w(test.xml
    #                     test.html
    #                     test.alt.html
    #                     test.doc
    #                     test.rxl
    #                     test test.alt)
    # end
  end

  def create_clean_test_files(content)
    File.write(File.join(@dir, "test.adoc"), content, encoding: "UTF-8")
    cleanup_test_files
    # Dir.chdir(@dir) do
    #   FileUtils.rm_f %w(test.xml
    #                     test.html
    #                     test.alt.html
    #                     test.doc
    #                     test.rxl
    #                     test test.alt)
    # end
  end

  it "processes metanorma options inside Asciidoc" do
    create_clean_test_files ASCIIDOC_PREAMBLE_HDR
    system "metanorma #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("test.xml")).to be true
      expect(File.exist?("test.doc")).to be false
      expect(File.exist?("test.html")).to be true
      expect(File.exist?("test.alt.html")).to be false
      xml = File.read("test.xml")
      expect(xml).to include "</iso-standard>"
    end
  end

  it "processes an asciidoc ISO document" do
    create_clean_test_files ASCIIDOC_BLANK_HDR
    system "metanorma -t iso #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("test.xml")).to be true
      expect(File.exist?("test.doc")).to be true
      expect(File.exist?("test.html")).to be true
      expect(File.exist?("test.alt.html")).to be true
    end
  end

  it "processes all extensions of an asciidoc ISO document" do
    create_clean_test_files ASCIIDOC_BLANK_HDR
    system "metanorma -t iso -x all #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("test.xml")).to be true
      expect(File.exist?("test.doc")).to be true
      expect(File.exist?("test.html")).to be true
      expect(File.exist?("test.alt.html")).to be true
    end
  end

  it "processes specific extensions of an asciidoc ISO document" do
    create_clean_test_files ASCIIDOC_BLANK_HDR
    system "metanorma -t iso -x xml,doc #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("test.xml")).to be true
      expect(File.exist?("test.doc")).to be true
      expect(File.exist?("test.html")).to be false
      expect(File.exist?("test.alt.html")).to be false
      xml = File.read("test.xml")
      expect(xml).to include "</iso-standard>"
    end
  end

  it "extracts isodoc options from asciidoc file" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    system "metanorma -t iso -x html #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      html = File.read("test.html", encoding: "UTF-8")
      expect(html).to include "font-family: body-font;"
      expect(html).to include "font-family: header-font;"
      expect(html).to include "font-family: monospace-font;"
    end
  end

  it "wraps HTML output" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    system "metanorma -w -t iso -x html #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("test/test.html")).to be true
    end
  end

  it "keeps Asciimath" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    system "metanorma -a -t iso -x xml #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("test.xml")).to be true
      xml = File.read("test.xml", encoding: "utf-8")
      expect(xml).not_to include %(<stem type="MathML">)
      expect(xml).to include %(<stem type="AsciiMath">)
    end
  end

  it "data64 encodes images" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    system "metanorma -d -t iso -x html #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("test.html")).to be true
      html = File.read("test.html", encoding: "utf-8")
      expect(html).to include "data:image"
    end
  end

  it "exports bibdata" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    system "metanorma -R #{@dir}/testrelaton.xml -t iso -x html #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("testrelaton.xml")).to be true
      xml = File.read("testrelaton.xml", encoding: "utf-8")
      expect(xml).to include %(<bibdata type="standard">)
    end
  end

  it "exports bibdata as rxl" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    system "metanorma -x rxl -t iso #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("test.rxl")).to be true
      xml = File.read("test.rxl", encoding: "utf-8")
      expect(xml).to include %(<bibdata type="standard">)
    end
  end

  it "exports assets" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    system "metanorma -x xml -t iso -e extract,sourcecode #{@dir}/test.adoc --no-install-fonts"
    Dir.chdir(@dir) do
      expect(File.exist?("extract/image/image-0000.png")).to be false
    end
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
      create_clean_test_files ASCIIDOC_PREAMBLE_HDR

      system "metanorma compile -t iso -r metanorma-iso #{@dir}/test.adoc --no-install-fonts"

      Dir.chdir(@dir) do
        expect(File.exist?("test.xml")).to be true
        expect(File.exist?("test.doc")).to be false
        expect(File.exist?("test.html")).to be true
        expect(File.exist?("test.alt.html")).to be false
        xml = File.read("test.xml")
        expect(xml).to include "</iso-standard>"
      end
    end
  end

  it "non-zero exit code when metanorma compile for missing file" do
    expect(system("metanorma compile not_existing.adoc")).to be false
  end

  it "warns when no standard type provided" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    stdout = `metanorma #{@dir}/test.adoc --no-install-fonts`
    expect(stdout).to include "Please specify a standard type"
  end

  it "warns when bogus standard type requested" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    stdout = `metanorma -t bogus_format #{@dir}/test.adoc`
    expect(stdout).to include "loading gem `metanorma-bogus_format` failed. "\
                              "Exiting"
  end

  it "warns when bogus format requested" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    stdout = `metanorma -t iso -f bogus_format #{@dir}/test.adoc`
    expect(stdout).to include "Only source file format currently supported "\
                              "is 'asciidoc'"
  end

  it "warns when no file provided" do
    stdout = `metanorma -t iso -x html`
    expect(stdout).to include "Need to specify a file to process"
  end

  it "gives version information" do
    stdout = `metanorma -v -t iso`
    expect(stdout).to match(/Metanorma::ISO \d/)
  end

  def tmp_directory
    @tmp_directory ||= Metanorma::Cli.root_path.join("tmp", "acceptance")
  end

  def cleanup_test_files
    Dir.chdir(@dir) do
      files = %w(test.xml test.html test.alt.html test.doc test.rxl test test.alt)
      FileUtils.rm_f(files)
    end
  end
end
