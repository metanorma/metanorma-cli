# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "rbconfig"

# metanorma-iso#1776: figure targets in schema-rendered documents
# resolve and render — the ISO 10303 / WG 12 layout where each figure
# sits next to its schema source and the document declares
# :imagesdir: images. The plugin stages schema-adjacent figures into
# the resolved imagesdir and emits bare basenames, so the compile
# finds every figure and no doubled images/<imagesdir>/ path exists.
# Each compile runs as a subprocess: the real user path, no in-process
# CLI state.
RSpec.describe "figure resolution in schema documents" do # rubocop:disable RSpec/DescribeClass
  let(:root) do
    File.realpath(Dir.mktmpdir("mnfig-")).tap do |dir|
      FileUtils.mkdir_p(File.join(dir, "images"))
      FileUtils.mkdir_p(File.join(dir, "schemas"))
      svg = "<svg xmlns='http://www.w3.org/2000/svg' width='10' " \
            "height='10'><rect width='10' height='10' fill='blue'/></svg>"
      File.write(File.join(dir, "schemas", "armexpg1.svg"), svg)
      File.write(File.join(dir, "schemas", "schema.exp"), <<~EXP)
        SCHEMA repro_schema;
          ENTITY thing;
            name : STRING;
          END_ENTITY;
          (*"repro_schema.__expressg"
          image::armexpg1.svg[]
          *)
        END_SCHEMA;
      EXP
      File.write(File.join(dir, "document.adoc"), <<~ADOC)
        = Figure repro
        Author
        :docnumber: 1
        :doctype: iso-standard
        :copyright-year: 2026
        :language: en
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: images

        [lutaml_express_liquid,schemas/schema.exp,my_context]
        ----
        {% for schema in my_context.schemas %}
        == {{ schema.id }}
        {% for remark in schema.remark_items %}
        {{ remark }}
        {% endfor %}
        {% endfor %}
        ----
      ADOC
      dir
    end
  end

  after { FileUtils.rmtree(root) }

  def compile(*args)
    exe = Metanorma::Cli.root_path.join("exe", "metanorma").to_s
    Dir.chdir(root) do
      system({ "PWD" => root }, RbConfig.ruby, exe, "compile", "-x", "html",
             "-t", "iso", "--no-install-fonts", *args, "document.adoc")
    end
  end

  it "renders schema-adjacent figures through the document's imagesdir" do
    expect(compile).to be_truthy

    html = File.read(File.join(root, "document.html"))
    # The figure renders (inline SVG or SVG data URI) — never silently
    # dropped.
    expect(html).to match(%r{<svg|data:image/svg\+xml})
    # No doubled images/<imagesdir>/ target anywhere in the output.
    expect(html).not_to include("images/images/")
    # No raw build-path or ../ composition leaks into the output.
    expect(html).not_to include("../schemas/")
    # The staged copy sits where the document's imagesdir resolves.
    expect(File.file?(File.join(root, "images", "armexpg1.svg"))).to be(true)
  end
end
