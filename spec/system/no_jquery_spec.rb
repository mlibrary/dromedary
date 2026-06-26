# frozen_string_literal: true

require "rails_helper"

RSpec.describe "jQuery removal", type: :system do
  describe "no jQuery references in JS files" do
    it "has no jQuery references in application JS" do
      js_files = Dir.glob(Rails.root.join("app/assets/javascripts/**/*.js"))
      offenders = js_files.select { |f| File.read(f).match?(/\$\(|jQuery/) }
      expect(offenders).to be_empty, "jQuery found in: #{offenders.join(', ')}"
    end

    it "does not require jquery in application.js" do
      app_js = File.read(Rails.root.join("app/assets/javascripts/application.js"))
      expect(app_js).not_to include("require jquery")
    end
  end

  describe "no jQuery references in ERB templates" do
    it "has no jQuery $() calls in view templates" do
      erb_files = Dir.glob(Rails.root.join("app/views/**/*.erb"))
      offenders = erb_files.select do |f|
        content = File.read(f)
        # Skip this test file itself
        next if f.include?("no_jquery_spec")
        content.match?(/\$[\(\.#]/) || content.match?(/jQuery/)
      end
      expect(offenders).to be_empty,
        "jQuery found in: #{offenders.map { |f| f.sub("#{Rails.root}/", '') }.join(', ')}"
    end
  end

  describe "no jquery-rails gem" do
    it "does not have jquery-rails in Gemfile" do
      gemfile = File.read(Rails.root.join("Gemfile"))
      expect(gemfile).not_to match(/gem\s+['"]jquery-rails['"]/)
    end
  end

  describe "pages load without jQuery" do
    it "splash page loads without errors" do
      visit "/"
      expect(page.status_code).to eq(200)
    end

    it "dictionary home loads without errors" do
      visit "/dictionary"
      expect(page.status_code).to eq(200)
    end

    it "bibliography home loads without errors" do
      visit "/bibliography"
      expect(page.status_code).to eq(200)
    end

    it "quotations home loads without errors" do
      visit "/quotations"
      expect(page.status_code).to eq(200)
    end
  end
end
