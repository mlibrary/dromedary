module Dromedary
  module Forms
    class SearchForm
      incude ActionView::Helpers::FormOptionsHelper
      include Blacklight::CatalogHelperBehavior
    end
  end
end
