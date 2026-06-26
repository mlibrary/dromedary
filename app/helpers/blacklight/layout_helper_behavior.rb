# frozen_string_literal: true

# Shadow copy of Blacklight::LayoutHelperBehavior
# Includes all BL8 methods but overrides grid column classes to Bootstrap 4
# (BL8 targets Bootstrap 5; we are still on Bootstrap 4 until the BS4->5 phase)
module Blacklight
  module LayoutHelperBehavior
    def show_content_classes
      "#{main_content_classes} show-document"
    end

    def html_tag_attributes
      {lang: I18n.locale}
    end

    def show_sidebar_classes
      sidebar_classes
    end

    # BL9/Bootstrap 5 grid classes
    def main_content_classes
      "col-lg-9 col-md-8 col-12"
    end

    # BL9/Bootstrap 5 grid classes
    def sidebar_classes
      "col-lg-3 col-md-4 col-12"
    end

    def container_classes
      blacklight_config.full_width_layout ? "container-fluid" : "container"
    end

    def render_nav_actions(options = {}, &block)
      render_filtered_partials(blacklight_config.navbar.partials, options, &block)
    end

    def opensearch_description_tag(title, href)
      tag :link, href: href, title: title, type: "application/opensearchdescription+xml", rel: "search"
    end

    def render_page_title
      (content_for(:page_title) if content_for?(:page_title)) || @page_title || application_name
    end

    def render_link_rel_alternates(document = @document, options = {})
      return if document.nil?

      document_presenter(document).link_rel_alternates(options)
    end

    def render_body_class
      extra_body_classes.join " "
    end

    def extra_body_classes
      @extra_body_classes ||= ["blacklight-#{controller.controller_name}", "blacklight-#{[controller.controller_name, controller.action_name].join("-")}"]
    end
  end
end
