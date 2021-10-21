# A StorageManager that stores file on remote filesystem using rclone. Rclone
# can store files on most cloud storage systems. Requires the `rclone` binary to
# be installed and configured.
#
# @see https://rclone.org/
class StorageManager::Rclone < StorageManager
  class Error < StandardError; end
  attr_reader :remote, :bucket, :rclone_path, :rclone_options

  def initialize(remote:, bucket:, rclone_path: "rclone", rclone_options: {}, **options)
    @remote = remote
    @bucket = bucket
    @rclone_path = rclone_path
    @rclone_options = rclone_options
    super(**options)
  end

  def store(file, path)
    rclone "copyto", file.path, key(path)
  end

  def delete(path)
    rclone "delete", key(path)
  end

  def open(path)
    file = Tempfile.new(binmode: true)
    rclone "copyto", key(path), file.path
    file
  end

  def rclone(*args)
    success = system(rclone_path, *rclone_options, *args)
    raise Error, "rclone #{args.join(" ")}: #{$?}" if !success
  end

  def key(path)
    ":#{remote}:#{bucket}#{full_path(path)}"
  end
end
