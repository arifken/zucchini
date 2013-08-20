class Zucchini::Generator < Clamp::Command
  option %W(-p --project), :flag, "Generate a project"
  option %W(-f --feature), :flag, "Generate a feature"

  parameter "PATH", "Path"

  def templates_path
    File.expand_path("#{File.dirname(__FILE__)}/../../templates")
  end

  def execute
    if project?
      FileUtils.mkdir_p(path)
      FileUtils.cp_r("#{templates_path}/project/.", path)
    elsif feature?
      Zucchini::Config.base_path = File.dirname(File.expand_path(path))
      FileUtils.cp_r("#{templates_path}/feature", path)

      # Create directories for the device screens listed in the config
      screens = Zucchini::Config.devices.values.collect { |d| d['screen'] }.uniq
      screens.each do |s|
        %w(masks pending reference).each do |dir|
          FileUtils.mkdir_p(File.join(path,dir,s))
          FileUtils.touch(File.join(path,dir,s,'.gitkeep'))
        end
      end

    end
  end

end