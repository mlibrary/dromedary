require_relative "index"
require_relative "control"

require "fileutils"

require_relative "../../config/load_local_config"

module MedInstaller
  # Copy the already-munged files from the build directory into this
  # instances data_dir, presumably for later indexing.
  class CopyFromBuild < Hanami::CLI::Command
    include MedInstaller::Logger

    # Error types for CopyFromBuild
    class ConfigurationError < StandardError
    end

    class ErrorWithFileList < StandardError
      attr_accessor :files

      def initialize(msg, files: [])
        super(msg)
        @files = files
      end
    end

    class MissingDirectory < ErrorWithFileList
    end

    class FilesTooOld < ErrorWithFileList
    end

    class FileMissing < ErrorWithFileList
    end

    class BuildFileMissing < ErrorWithFileList
    end

    NEEDED_FILES = %w[entries.json.gz bib_all.xml hyp_to_bibid.json]
    option :force,
      required: false,
      default: false,
      values: %w[true false],
      desc: "Force a copy even if the files in build aren't newer than those currently in this instance's data_dir"

    def call(**options)
      @data_dir = AnnoyingUtilities.data_dir
      @build_dir = Pathname.new(Dromedary.config.build_dir).realdirpath
      @force = options.fetch(:force)

      validate_directories!
      validate_build_files_exist!

      unless @force
        validate_files_not_too_old!
      end

      # We're finally ready.

      NEEDED_FILES.each do |f|
        logger.info "Copying #{f} from #{@build_dir} to #{@data_dir}"
        FileUtils.copy_file(build_file(f), current_file(f))
      end
    rescue MissingDirectory, ConfigurationError, BuildFileMissing => e
      error_with_file_list(e)
    rescue FilesTooOld => e
      msg = <<MSG
 
     File(s) #{e.files.join(", ")} in the build directory aren't newer 
     than what's currently being used.

      Did you remember to first prepare new data with  'newdata prepare'?

      You can add "--force=true"" to force the copy anyway."
MSG
      error_with_file_list(FilesTooOld.new(msg))
    end

    def validate_directories!
      # Are the directories set and exist? Will raise if not
      validate_dir!(dir: @data_dir, label: "data_dir")
      validate_dir!(dir: @build_dir, label: "build_dir")
    end

    def validate_build_files_exist!
      dne = NEEDED_FILES.each_with_object([]) do |f, missing|
        bf = build_file(f)
        missing << bf unless bf.exist?
      end
      unless dne.empty?
        raise BuildFileMissing.new("Can't find build file(s)", files: dne)
      end
    end

    def validate_files_not_too_old!
      too_old = NEEDED_FILES.each_with_object([]) do |f, arr|
        next unless current_file(f).exist?
        arr << f if current_file(f).mtime >= build_file(f).mtime
      end

      unless too_old.empty?
        raise FilesTooOld.new("Current files newer than build files", files: too_old)
      end
    end

    private

    def error_with_file_list(e)
      logger.error "\n\n" + e.message + "[#{e.files.join(", ")}]"
      raise e
    end

    # Make sure a directory is defined and exists
    def validate_dir!(dir:, label:)
      raise ConfigurationError.new("#{label} is not configured") if dir.nil?
      raise MissingDirectory.new("#{label} dir #{dir} does not exist. Aborting") unless dir.exist?
    end

    # @return [Pathname]
    def build_file(filename)
      Pathname.new(@build_dir) + filename
    end

    # @return [Pathname]
    def current_file(filename)
      Pathname.new(@data_dir) + filename
    end
  end
end
