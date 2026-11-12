# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "rbconfig"

# metanorma-cli#490: the default include jail is the working directory
# (Asciidoctor's own default, the pre-#489 behavior) — compiles from a
# repository root keep resolving includes that reach above the
# document's directory. An explicit --base-dir still anchors the jail.
# Each compile runs as a subprocess: the real user path, no in-process
# CLI state. The fixture root is realpath'd (macOS /var -> /private/var)
# and the child gets a matching PWD, because the jail comparison is
# prefix-string based.
RSpec.describe "base_dir default" do # rubocop:disable RSpec/DescribeClass
  let(:root) do
    File.realpath(Dir.mktmpdir("mn490-")).tap do |dir|
      FileUtils.mkdir_p(File.join(dir, "doc"))
      FileUtils.mkdir_p(File.join(dir, "templates"))
      File.write(File.join(dir, "templates", "preamble.adoc"),
                 "PREAMBLE-MARKER lives above the document directory.\n")
      File.write(File.join(dir, "doc", "document.adoc"), <<~ADOC)
        = Trial document
        Author
        :docnumber: 1
        :doctype: international-standard
        :docstage: 30
        :copyright-year: 2026

        [prefatory]
        include::../templates/preamble.adoc[]

        == Scope
        Body text.
      ADOC
      dir
    end
  end

  after { FileUtils.rmtree(root) }

  def compile(*args)
    exe = Metanorma::Cli.root_path.join("exe", "metanorma").to_s
    Dir.chdir(root) do
      # PWD must match the chdir: File.expand_path(".") honors the
      # inherited environment value, and the suite's stale PWD would
      # point the compile at the checkout.
      system({ "PWD" => root }, RbConfig.ruby, exe, "compile", "-x", "xml",
             "-t", "iso", "--no-install-fonts", *args, "doc/document.adoc")
    end
  end

  it "resolves an upward include when compiled from the root" do
    compile
    expect(File.read(File.join(root, "doc", "document.xml")))
      .to include("PREAMBLE-MARKER")
  end

  it "anchors the jail at an explicit --base-dir" do
    compile("--base-dir", root)
    expect(File.read(File.join(root, "doc", "document.xml")))
      .to include("PREAMBLE-MARKER")
  end
end
