require_relative '../../../lib/inferno/dsl/must_support_metadata_extractor'

RSpec.describe Inferno::DSL::MustSupportMetadataExtractor do
  let(:profile) do
    profile = double("profile")
    allow(profile).to receive(:baseDefinition).and_return("baseDefinition")
    allow(profile).to receive(:name).and_return("name")
    allow(profile).to receive(:type).and_return("type")
    allow(profile).to receive(:version).and_return("version")
    profile
  end

  let(:type) do
    type = double()
    allow(type).to receive(:profile).and_return(["profile_url"])
    type
  end

  let(:profile_element) { double() }
  before do
    allow(profile_element).to receive(:mustSupport).and_return(true)
    allow(profile_element).to receive(:path).and_return("foo.extension")
    allow(profile_element).to receive(:id).and_return("id")
    allow(profile_element).to receive(:type).and_return([type])
  end

  let(:ig_resources) do
    ig_resources = double()
    allow(ig_resources).to receive(:value_set_by_url).and_return(nil)
    ig_resources
  end

  subject { described_class.new([profile_element], profile, "resourceConstructor", ig_resources) }

  describe "#get_type_must_support_metadata" do
    let(:metadata) do
      { path: "path" }
    end

    let(:type) do
      type = double()
      allow(type).to receive(:extension).and_return("extension")
      allow(type).to receive(:code).and_return("code")
      type
    end

    let(:element) do
      element = double()
      allow(element).to receive(:type).and_return([type])
      element
    end

    it "returns a path and an original path" do
      allow(subject).to receive(:type_must_support_extension?).and_return(true)

      result = subject.get_type_must_support_metadata(metadata, element)

      expected = [{:original_path=>"path", :path=>"pathCode"}]
      expect(result).to eq(expected)
    end

    it "returns a path and an original path" do
      allow(subject).to receive(:type_must_support_extension?).and_return(false)

      result = subject.get_type_must_support_metadata(metadata, element)

      expected = []
      expect(result).to eq(expected)
    end

  end
end
