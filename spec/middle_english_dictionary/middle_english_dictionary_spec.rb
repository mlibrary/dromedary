require_relative "spec_helper"
RSpec.describe MiddleEnglishDictionary do
  it "has a version number" do
    expect(MiddleEnglishDictionary::VERSION).not_to be nil
  end
end
