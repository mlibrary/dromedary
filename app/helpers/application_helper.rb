require_relative "../../lib/dromedary/xslt_utils"

module ApplicationHelper
  extend Dromedary::XSLTUtils::Class
  include Dromedary::XSLTUtils::Class
  include Dromedary::XSLTUtils::Instance

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
