# frozen_string_literal: true
#
module Dromedary
  module Overrides
    module RepositoryOverrides
      def send_and_receive(path, solr_params = {})
        p = solr_params.to_h.dup
        p.delete_if {|k, v| v.nil? or v == []}
        Rails.logger.measure_info("Calling solr", payload: {solr_params: p}) do
          super
        end
      end
    end
  end
end
Blacklight::Solr::Repository.prepend Dromedary::Overrides::RepositoryOverrides
