# frozen_string_literal: true

require "spec_helper"
require "metanorma-core"

# THE integration gate of the flavor/taste restructure: identity comes
# from the core table, renderers resolve through it, and a real ISO
# presentation-XML document renders through the resolved renderer.
RSpec.describe "flavor table integration" do
  before do
    require "metanorma/iso/document"
    require "metanorma-taste"
  end

  it "resolves ISO canonically and chains the ICC taste" do
    entry = Metanorma::Core::Flavors.find(:iso)
    expect(entry).not_to be_nil
    expect(entry.base_flavor).to be_nil

    icc = Metanorma::Core::Flavors.find(:icc)
    expect(icc&.base_flavor).to eq(:iso)
    expect(Metanorma::Core::Flavors.table.canonical(:icc).name).to eq(:iso)
  end

  it "renders an ISO document through the table-resolved renderer" do
    xml = File.read(File.expand_path(
      "../fixtures/iso/document-en.presentation.xml", __dir__
    ))
    doc = Metanorma::Iso::Document::Root.from_xml(xml)
    renderer = Metanorma::Core::Flavors.renderer_for(doc, format: :html)
    expect(renderer).to eq(Metanorma::Iso::Html::Renderer)

    html = Metanorma::Html::Generator.generate(doc)
    expect(html.length).to be > 10_000
  end
end
