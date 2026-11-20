require "rspec/core/rake_task"

desc "Run only Solr integration specs"
RSpec::Core::RakeTask.new("spec-just-integration") do |task|
  ENV["RUN_INTEGRATION"] = "1"
  task.rspec_opts = "--tag integration"
end

desc "Run all specs, including Solr integration specs"
RSpec::Core::RakeTask.new("spec-all") do
  ENV["RUN_INTEGRATION"] = "1"
end
