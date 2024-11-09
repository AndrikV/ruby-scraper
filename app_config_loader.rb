require 'yaml'
require 'erb'
require 'json'

class AppConfigLoader
  attr_reader :config_data, :loaded_libs

  def initialize
    @config_data = {}
    @loaded_libs = []
  end

  def config(main_config_path, additional_configs_dir)
    main_config = load_default_config(main_config_path)
    additional_configs = load_config(additional_configs_dir)
    @config_data = main_config.merge(additional_configs)
    yield(@config_data) if block_given?
    @config_data
  end

  def pretty_print_config_data
    puts JSON.pretty_generate(@config_data)
  end

  def load_default_config(path_to_yaml_file)
    config_content = File.read(path_to_yaml_file)
    erb_result = ERB.new(config_content).result
    YAML.safe_load(erb_result) || {}
  end

  def load_config(directory)
    Dir["#{directory}/*.yaml"].each_with_object({}) do |file, configs|
      file_config = YAML.load_file(file)
      configs.merge!(file_config) if file_config.is_a?(Hash)
    end
  end

  def load_libs(libs_dir)
    system_libs = %w[date yaml json]

    system_libs.each do |lib|
      require lib
      @loaded_libs << lib
    end

    Dir.glob("#{libs_dir}/*.rb").each do |file|
      file_name = File.basename(file, ".rb")
      puts file
      next if @loaded_libs.include?(file_name)
      require_relative file
      @loaded_libs << file_name
    end
  end

  private :load_default_config, :load_config
end
