require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/s3"

# Migrate these to explicit Shrine settings, instead of ActiveStorage structure
S3FIXME = Dromedary.config.storage.aws

Shrine.storages = {
#   cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
#   store: Shrine::Storage::FileSystem.new("public", prefix: "uploads"),
  cache: Shrine::Storage::S3.new(prefix: "cache", **S3FIXME),
  store: Shrine::Storage::S3.new(**S3FIXME),
}

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data
Shrine.plugin :restore_cached_data
Shrine.plugin :rack_file
Shrine.plugin :determine_mime_type
