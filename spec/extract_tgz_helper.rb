module ExtractTGZHelper
  def extract_tgz(fixture)
    filename = File.basename(fixture, '.tgz')
    target_dir = Dir.mktmpdir(filename)
    system "mkdir -p #{target_dir}"
    system "tar -xzf #{fixture} --directory #{target_dir}"
    target_dir
  end

  def cleanup(target_dir)
    FileUtils.remove_entry(target_dir)
  end
end
