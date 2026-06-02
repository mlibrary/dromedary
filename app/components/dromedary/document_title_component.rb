# frozen_string_literal: true

module Dromedary
  class DocumentTitleComponent < Blacklight::DocumentTitleComponent
    def title
      presenter = @presenter
      document = presenter.document

      if presenter.respond_to?(:headword_display) && presenter.respond_to?(:part_of_speech_abbrev)
        headword = presenter.headword_display(document)
        pos = presenter.part_of_speech_abbrev
        link = helpers.link_to_document document, headword.to_s.html_safe, counter: @counter, itemprop: 'name'
        pos_html = pos.present? ? " <span class=\"index-pos\">#{pos}</span>".html_safe : "".html_safe
        "#{link}#{pos_html}".html_safe
      elsif @title.present?
        if @link_to_document
          helpers.link_to_document document, @title, counter: @counter, itemprop: 'name'
        else
          content_tag('span', @title, itemprop: 'name')
        end
      elsif content.present?
        if @link_to_document
          helpers.link_to_document document, content, counter: @counter, itemprop: 'name'
        else
          content_tag('span', content, itemprop: 'name')
        end
      else
        if @link_to_document
          helpers.link_to_document document, presenter.heading, counter: @counter, itemprop: 'name'
        else
          content_tag('span', presenter.heading, itemprop: 'name')
        end
      end
    end
  end
end
