#!/usr/bin/env ruby

# Before doing anything else, need to
# force bundler to load up so we
# can require gems from the Gemfile
#
require "pathname"
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile",
                                           Pathname.new(__FILE__).realpath)
bundle_binstub = File.expand_path("../bundle", __FILE__)

if File.file?(bundle_binstub)
  if File.read(bundle_binstub, 300) =~ /This file was generated by Bundler/
    load(bundle_binstub)
  else
    abort("Your `bin/bundle` was not generated by Bundler, so this binstub cannot run.
Replace `bin/bundle` by running `bundle binstubs bundler --force`, then run this command again.")
  end
end

require "bundler/setup"

# Add the local lib

$LOAD_PATH.unshift (Pathname(__dir__).parent + 'lib').to_s
$LOAD_PATH.unshift (Pathname(__dir__).parent + 'indexer').to_s

# Now we can actually load stuff

require 'hanami/cli'
require "dromedary/services"
require "med_installer/indexing_steps"

indexer = MedInstaller::IndexingSteps.new(zipfile: "/mec/data/A.zip")
indexer.connection.collections.each {|c| c.delete! if c.name =~ /\Amed_/}
indexer.connection.configsets.each {|c| c.delete! if c.name =~ /\Amed_/}
