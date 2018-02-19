require 'traject'
require 'traject/debug_writer'

settings do
  store "writer_class_name", "Traject::DebugWriter"
  store "output_file", "debug.out"
  store 'processing_thread_pool', 0
end

