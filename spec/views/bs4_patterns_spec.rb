# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BS4 pattern audit', type: :view do
  def erb_files
    Dir.glob(Rails.root.join('app/views/**/*.erb'))
  end

  it 'has no sr-only in view files' do
    offenders = erb_files.select { |f| File.read(f).match?(/\bsr-only\b/) }
    expect(offenders).to be_empty, "sr-only found in:\n  #{offenders.join("\n  ")}"
  end

  it 'has no data-toggle (without bs) in view files' do
    offenders = erb_files.select { |f| content = File.read(f); content.match?(/data-toggle/) && !content.match?(/data-bs-toggle/) }
    expect(offenders).to be_empty, "data-toggle (without bs) found in:\n  #{offenders.join("\n  ")}"
  end

  it 'has no data-target (without bs) in view files' do
    offenders = erb_files.select { |f| content = File.read(f); content.match?(/data-target/) && !content.match?(/data-bs-target/) }
    expect(offenders).to be_empty, "data-target (without bs) found in:\n  #{offenders.join("\n  ")}"
  end

  it 'has no data-dismiss="modal" (should be data-bl-dismiss) in view files' do
    offenders = erb_files.select { |f| File.read(f).match?(/data-dismiss=["']modal["']/) }
    expect(offenders).to be_empty, "data-dismiss=\"modal\" found in:\n  #{offenders.join("\n  ")}"
  end

  it 'has no .close button class (should be .btn-close) in view files' do
    offenders = erb_files.select do |f|
      content = File.read(f)
      # Match class attributes that contain 'close' as a standalone class
      # but NOT as part of 'btn-close' or 'ajax-modal-close'
      content.match?(/class=["'][^"']*[\s"']close[\s"'][^"']*["']/) && !content.match?(/btn-close/)
    end
    expect(offenders).to be_empty, ".close button class found in:\n  #{offenders.join("\n  ")}"
  end
end
