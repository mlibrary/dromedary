# require 'simple_solr_client'
# require 'delegate'
# require 'annoying_utilities'
#
# module MedInstaller
#   class Indexer
#     class Solr < SimpleDelegator
#
#       attr_accessor :url
#
#       def initialize(url = nil)
#         @url = (url or AnnoyingUtilities.blacklight_solr_url)
#         @client = self.solr_client(@url)
#         __setobj__(@client)
#       end
#
#
#       def solr_client(url)
#         solr_root, corename = split_solr_url(url)
#         client              = SimpleSolrClient::Client.new(solr_root)
#         client.core(corename)
#       end
#
#
#       # Given a whole solr url (including the core at the end), split it into the
#       # solr_root and the corename
#       def split_solr_url(url)
#         uri       = URI(url)
#         path      = uri.path.split('/')
#         corename  = path.pop
#         uri.path  = path.join('/') # go up a level -- we popped off the core name
#         solr_root = uri.to_s
#         [solr_root, corename]
#       end
#
#
#     end
#
#
#   end
# end
