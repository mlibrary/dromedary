require 'sidekiq'

module Dromedary
  class IndexDataJob
    include Sidekiq::Job

    queue_as :default

    def perform(filename)
      puts "indexing data"
      exit_code = %x( bin/dromedary extract_convert_index #{filename} )
      puts "finished preparing with exit code #{exit_code}"
    end
  end
end
