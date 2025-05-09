require_relative 'in_memory_repository'

require_relative '../utils/ig_downloader'

module Inferno
  module Repositories
    # Repository that deals with persistence for the `IG` entity.
    class IGs < InMemoryRepository
      include Inferno::Utils::IgDownloader

      # Get the instance of the IG specified by either identifier or file path.
      # An in-memory instance will be returned if already loaded, otherwise
      # the IG will be retrieved from the user package cache (~/.fhir/packages)
      # or from the package server and then loaded into the repository.
      # @param id_or_path [String] either an identifier, eg "hl7.fhir.us.core#3.1.1"
      #        or a file path, eg "./igs/uscore.tgz"
      # @return [Inferno::Entities::IG]
      def find_or_load(id_or_path)
        return find(id_or_path) if exists?(id_or_path)

        ig_by_path = find_by_path(id_or_path) || find_by_path(find_local_file(id_or_path))
        return ig_by_path if ig_by_path

        load(id_or_path)
      end

      # Get the instance of the already-loaded IG specified by file path.
      # @param path [String] file path, eg "./igs/uscore.tgz"
      # @return [Inferno::Entities::IG]
      def find_by_path(path)
        all.find { |ig| ig.source_path == path }
      end

      # @private
      def load(ig_path)
        local_ig_file = find_local_file(ig_path)
        if local_ig_file
          ig = Inferno::Entities::IG.from_file(local_ig_file)
          # To match the HL7 FHIR validator, DO NOT cache igs loaded from file
        elsif in_user_package_cache?(ig_path.sub('@', '#'))
          # NPM syntax for a package identifier is id@version (eg, hl7.fhir.us.core@3.1.1)
          # but in the cache the separator is # (hl7.fhir.us.core#3.1.1)
          cache_directory = File.join(user_package_cache, ig_path.sub('@', '#'))
          ig = Inferno::Entities::IG.from_file(cache_directory)
        else
          Tempfile.create(['package', '.tgz']) do |temp_file|
            load_ig(ig_path, nil, temp_file.path)
            cache_directory = add_package_to_cache(ig_path.sub('@', '#'), temp_file.path)
            ig = Inferno::Entities::IG.from_file(cache_directory)
          end
        end
        ig.add_self_to_repository
        ig
      end

      # @private
      def find_local_file(ig_path)
        return nil unless ['.tgz', '.tar.gz'].any? { |ext| ig_path.downcase.end_with?(ext) }

        return ig_path if File.exist?(ig_path)

        # IG packages are copied to ./data/igs to be used by the validator,
        # and if referenced by file in the validator block the path given must be "igs/{filename}.tgz"
        data_igs_path = File.join('data', ig_path) # TODO: abstractify this into something that toggles b/n global and local mode
        return data_igs_path if File.exist?(data_igs_path)

        # Last resort, try to find the file under the current working directory,
        # eg, given ig_path: 'igs/package123.tgz'
        # this would find 'lib/my_test_kit/igs/package123.tgz'
        Dir.glob(File.join('**', ig_path))[0]
      end

      # @private
      def user_package_cache
        File.join(Dir.home, '.fhir', 'packages')
      end

      # @private
      def in_user_package_cache?(ig_identifier)
        File.directory?(File.join(user_package_cache, ig_identifier))
      end

      # @private
      def add_package_to_cache(ig_identifier, temp_tgz)
        return temp_tgz if ENV['READ_ONLY_FHIR_PACKAGE_CACHE'].present?

        # In the HL7 FHIR validator, this is handled by the FilesystemPackageCacheManager:
        # https://github.com/hapifhir/org.hl7.fhir.core/blob/3cf2a06e7abda7dc32cdc052d3a356c1201139cf/org.hl7.fhir.utilities/src/main/java/org/hl7/fhir/utilities/npm/FilesystemPackageCacheManager.java#L558
        # We try to follow the same approach here

        lockfile_path = File.join(user_package_cache, "#{ig_identifier}.lock")
        lockfile = File.open(lockfile_path, 'w+')
        lockfile.flock(File::LOCK_EX)

        target_cache_dir = File.join(user_package_cache, ig_identifier)

        # Break early 1 - something else already created it while we got the lock
        return target_cache_dir if in_user_package_cache?(ig_identifier)

        # 1. Extract to a temp folder under the cache
        temp_dir = File.join(user_package_cache, SecureRandom.uuid)
        FileUtils.mkdir_p(temp_dir)

        system "tar -xzf #{temp_tgz} --directory #{temp_dir}"

        # Break early 2 - something else already created it
        return target_cache_dir if in_user_package_cache?(ig_identifier)

        # 2. Rename the temp folder to the correct name
        File.rename(temp_dir, target_cache_dir)

        # return the path in cache
        target_cache_dir
      rescue StandardError => e
        Application['logger'].error(e.full_message)
        # Don't leave a half extracted package behind
        FileUtils.remove_dir(temp_dir, true)

        # Return the tgz so that processing can continue
        temp_tgz
      ensure
        if lockfile.present?
          lockfile.flock(File::LOCK_UN)
          lockfile.close
          File.delete(lockfile)
        end
      end
    end
  end
end
