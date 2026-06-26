require_relative "../../lib/dromedary/xslt_utils"

module ApplicationHelper
  extend Dromedary::XSLTUtils::Class
  include Dromedary::XSLTUtils::Class
  include Dromedary::XSLTUtils::Instance

  # Returns a Dromedary::*::IndexPresenter for the given document.
  # Replaces the missing BL8-era index_presenter helper. The custom presenters
  # provide .entry, .form_html, .etym_html, etc. needed by both index and show templates.
  def index_presenter(document)
    case controller_name
    when "catalog"
      Dromedary::IndexPresenter.new(document, self, blacklight_config)
    when "bibliography"
      Dromedary::Bib::IndexPresenter.new(document, self, blacklight_config)
    when "quotes"
      Dromedary::Quotes::IndexPresenter.new(document, self, blacklight_config)
    else
      document_presenter(document)
    end
  end

  # Returns the suggest endpoint path for the given controller name.
  # polymorphic_path doesn't work here because routes use custom path prefixes
  # (e.g., catalog → /dictionary, bibliography → /bibliography, quotes → /quotations).
  def suggest_path_for_controller(controller)
    base = case controller.to_s
           when "catalog" then "#{root_path}dictionary"
           when "bibliography" then "#{root_path}bibliography"
           when "quotes" then "#{root_path}quotations"
           end
    path = case controller.to_s
           when "catalog" then suggest_index_catalog_path
           when "bibliography" then suggest_index_bibliography_path
           when "quotes" then suggest_index_quotes_path
           end
    "#{path}?base_url=#{ERB::Util.url_encode(base)}"
  end

  def cit_xslt
    load_xslt("CitOnly.xsl")
  end

  # @param [MiddleEnglishDictionary::Entry::Citation] cit The citation object
  # @return [String, nil] The citatation transformed into HTML, or nil
  def cit_html(cit)
    rid = cit.bib.stencil.rid
    url = if rid
      bibid = Dromedary.hyp_to_bibid[rid.upcase] if rid
      _url = bib_link_path bibid
    else
      ""
    end
    xsl_transform_from_xml(cit.xml, cit_xslt, ["biburl", "'#{url}'"])
  end

  alias_method :cite_html, :cit_html
  alias_method :citation_html, :cit_html
end
