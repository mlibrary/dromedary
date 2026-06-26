require_relative "index"
require_relative "control"

require "fileutils"

require_relative "../../config/load_local_config"

module MedInstaller
  # CLI command that copies prepared data files from the build directory into
  # the application's live data directory, ready for indexing.
  #
  # Validates that both the build and data directories exist, that the required
  # build files are present, and (unless +--force+ is given) that the build
  # files are newer than the currently deployed files.
  #
  # Required files (see {NEEDED_FILES}): +entries.json.gz+, +bib_all.xml+,
  # +hyp_to_bibid.json+.
  #
  # @note +Dromedary.config.build_dir+ (used on line 48) is not defined in
  #   +lib/+; it is expected to be set by a Rails initializer.  This command
  #   will raise +NoMethodError+ if called outside a Rails context.
  class CopyFromBuild < Hanami::CLI::Command
    include MedInstaller::Logger

    # Raised when a required configuration value (e.g. a directory path) is
    # missing or +nil+.
    class ConfigurationError < StandardError
    end

    # Base class for errors that carry a list of affected file paths.
    # @!attribute [rw] files
    #   @return [Array<String>] the files involved in the error condition
    class ErrorWithFileList < StandardError
      attr_accessor :files

      # @param msg [String] human-readable error description
      # @param files [Array<String>] the files involved in the error
      def initialize(msg, files: [])
        super(msg)
        @files = files
      end
    end

    # Raised when a required directory (build or data) does not exist.
    class MissingDirectory < ErrorWithFileList
    end

    # Raised when build files are not newer than the currently deployed files
    # and +--force+ was not given.
    class FilesTooOld < ErrorWithFileList
    end

    # Raised when one or more required files are absent from the data directory.
    class FileMissing < ErrorWithFileList
    end

    # Raised when one or more required files are absent from the build directory.
    class BuildFileMissing < ErrorWithFileList
    end

    # Files that must be present in the build directory before copying.
    NEEDED_FILES = %w[entries.json.gz bib_all.xml hyp_to_bibid.json]

    option :force,
      required: false,
      default: false,
      values: %w[true false],
      desc: "Force a copy even if the files in build aren't newer than those currently in this instance's data_dir"

    # Validate directories and file freshness, then copy {NEEDED_FILES} from the
    # build directory to the live data directory.
    #
    # @param options [Hash] keyword options; uses +:force+ (Boolean)
    # @return [void]
    # @raise [MissingDirectory] if either directory does not exist
    # @raise [ConfigurationError] if a directory path is not configured
    # @raise [BuildFileMissing] if a required file is absent from the build directory
    # @raise [FilesTooOld] if build files are not newer than deployed files (and
    #   +force+ is +false+)
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

    # Validates that +@data_dir+ and +@build_dir+ are set and exist on disk.
    # @return [void]
    # @raise [ConfigurationError] if a directory path is +nil+
    # @raise [MissingDirectory] if a directory does not exist
    def validate_directories!
      # Are the directories set and exist? Will raise if not
      validate_dir!(dir: @data_dir, label: "data_dir")
      validate_dir!(dir: @build_dir, label: "build_dir")
    end

    # Verifies that every file in {NEEDED_FILES} exists in the build directory.
    # @return [void]
    # @raise [BuildFileMissing] listing all missing files
    def validate_build_files_exist!
      dne = NEEDED_FILES.each_with_object([]) do |f, missing|
        bf = build_file(f)
        missing << bf unless bf.exist?
      end
      unless dne.empty?
        raise BuildFileMissing.new("Can't find build file(s)", files: dne)
      end
    end

    # Verifies that every file in {NEEDED_FILES} in the build directory is
    # strictly newer than the currently deployed file (if one exists).
    # @return [void]
    # @raise [FilesTooOld] listing all files where the build copy is not newer
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

    # Logs and re-raises an {ErrorWithFileList} with the file list appended.
    # @param e [ErrorWithFileList] the error to log and re-raise
    # @return [void]
    def error_with_file_list(e)
      logger.error "\n\n" + e.message + "[#{e.files.join(", ")}]"
      raise e
    end

    # Ensures a directory path is non-nil and points to an existing directory.
    # @param dir [Pathname, String, nil] the directory to validate
    # @param label [String] human-readable name used in error messages
    # @return [void]
    # @raise [ConfigurationError] if +dir+ is +nil+
    # @raise [MissingDirectory] if +dir+ does not exist on disk
    def validate_dir!(dir:, label:)
      raise ConfigurationError.new("#{label} is not configured") if dir.nil?
      raise MissingDirectory.new("#{label} dir #{dir} does not exist. Aborting") unless dir.exist?
    end

    # @param filename [String] base filename within the build directory
    # @return [Pathname] absolute path to the file in the build directory
    def build_file(filename)
      Pathname.new(@build_dir) + filename
    end

    # @param filename [String] base filename within the data directory
    # @return [Pathname] absolute path to the file in the live data directory
    def current_file(filename)
      Pathname.new(@data_dir) + filename
    end
  end
end
