require "concurrent"

task = Concurrent::TimerTask.new(execution_interval: 5, run_now: true) { puts "Hello" }
task.execute

sleep 1000
