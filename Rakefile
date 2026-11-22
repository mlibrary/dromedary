# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"
require "standard/rake"
require_relative "app/jobs/poke_sidekiq_job"

Rails.application.load_tasks

desc "sanity-check sidekiq"
task :poke_sidekiq do
  PokeSidekiqJob.perform_async
end
