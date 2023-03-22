require "sidekiq"

class PokeSidekiqJob
  include Sidekiq::Job

  def perform
    puts "hiiiiii"
  end
end
