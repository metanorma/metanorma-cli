# frozen_string_literal: true

RSpec.describe Metanorma::SiteManifest do
  describe ".from_yaml" do
    let(:manifest) { described_class::Base.from_yaml(input_yaml) }

    subject(:metanorma_manifest) { manifest.metanorma }

    shared_examples "a valid manifest" do
      it "reads YAML into a #{described_class::Base} object" do
        expect(manifest).to be_a(described_class::Base)
      end

      it { is_expected.to be_a(Metanorma::SiteManifest::Manifest) }

      its(:source) do
        is_expected.to be_a(Metanorma::SiteManifest::SourceEntries)
      end

      its(:collection) do
        is_expected.to be_a(Metanorma::SiteManifest::SiteMetadata)
      end
      its(:'collection.organization') { is_expected.to eq "org" }
      its(:'collection.name') { is_expected.to eq "name" }

      it "raises an error when accessing un-modelled properties" do
        expect { manifest.unmodelled_property }.to raise_error(NoMethodError)
      end
    end

    context "with a bare minimum valid input YAML" do
      let(:input_yaml) do
        <<~EOYAML
          metanorma:
            source:
              files:
            collection:
              organization: org
              name: name
        EOYAML
      end
      it_behaves_like "a valid manifest"
      its(:template) { is_expected.to be_nil }
      its(:source) { is_expected.to have_attributes(files: []) }
    end

    context "with a standard valid input YAML" do
      let(:input_yaml) do
        <<~EOYAML
          metanorma:
            source:
              files:
              - file1
              - file2
            collection:
              organization: org
              name: name
        EOYAML
      end

      it_behaves_like "a valid manifest"
      its(:template) { is_expected.to be_nil }
      its(:source) { is_expected.to have_attributes(files: %w[file1 file2]) }
    end

    context "with a valid input YAML with an empty template" do
      let(:input_yaml) do
        <<~EOYAML
          metanorma:
            source:
              files:
              - file1
              - file2
            collection:
              organization: org
              name: name
            template:
        EOYAML
      end

      it_behaves_like "a valid manifest"

      its(:template) do
        is_expected.to be_nil
      end

      its(:source) { is_expected.to have_attributes(files: %w[file1 file2]) }
    end

    context "with a valid input YAML with a minimal template (path)" do
      let(:input_yaml) do
        <<~EOYAML
          metanorma:
            source:
              files:
              - file1
              - file2
            collection:
              organization: org
              name: name
            template:
              path: path/to/template
        EOYAML
      end

      it_behaves_like "a valid manifest"

      its(:template) do
        is_expected.to be_a Metanorma::SiteManifest::SiteTemplate
      end

      its(:source) { is_expected.to have_attributes(files: %w[file1 file2]) }
      its(:'template.path') { is_expected.to eq "path/to/template" }
    end

    context "with a valid input YAML with a minimal template (stylesheet)" do
      let(:input_yaml) do
        <<~EOYAML
          metanorma:
            source:
              files:
              - file1
              - file2
            collection:
              organization: org
              name: name
            template:
              stylesheet: path/to/stylesheet
        EOYAML
      end

      it_behaves_like "a valid manifest"

      its(:template) do
        is_expected.to be_a Metanorma::SiteManifest::SiteTemplate
      end

      its(:source) { is_expected.to have_attributes(files: %w[file1 file2]) }
      its(:'template.stylesheet') { is_expected.to eq "path/to/stylesheet" }
    end

    context "with a valid input YAML with a full template" do
      let(:input_yaml) do
        <<~EOYAML
          metanorma:
            source:
              files:
              - file1
              - file2
            collection:
              organization: org
              name: name
            template:
              path: path/to/template
              stylesheet: path/to/stylesheet
        EOYAML
      end

      it_behaves_like "a valid manifest"

      its(:template) do
        is_expected.to be_a Metanorma::SiteManifest::SiteTemplate
      end

      its(:source) { is_expected.to have_attributes(files: %w[file1 file2]) }
      its(:'template.path') { is_expected.to eq "path/to/template" }
      its(:'template.stylesheet') { is_expected.to eq "path/to/stylesheet" }
    end
  end
end
