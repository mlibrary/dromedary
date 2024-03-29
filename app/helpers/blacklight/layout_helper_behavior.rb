# frozen_string_literal: true

# Methods added to this helper will be available to all templates in the hosting
# application
module Blacklight
  # A module for useful methods used in layout configuration
  module LayoutHelperBehavior
    ##
    # Classes added to a document's show content div
    # @return [String]
    def show_content_classes
      "#{main_content_classes} show-document"
    end

    ##
    # Classes added to a document's sidebar div
    # @return [String]
    def show_sidebar_classes
      sidebar_classes
    end

    ##
    # Classes used for sizing the main content of a Blacklight page
    # @return [String]
    def main_content_classes(offset = false)
      retval = "col-md-9 col-sm-8 col-xs-12"
      if offset
        retval += title_content_classes
      end
      retval
    end

    def title_content_classes
      " col-md-push-3 col-sm-push-4"
    end

    ##
    # Classes used for sizing the sidebar content of a Blacklight page
    # @return [String]
    def sidebar_classes
      "col-md-3 col-sm-4 col-xs-12"
    end

    ##
    # Class used for specifying main layout container classes. Can be
    # overwritten to return 'container-fluid' for Bootstrap full-width layout
    # @return [String]
    def container_classes
      "container"
    end
  end
end
