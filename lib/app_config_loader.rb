require 'yaml'
require 'erb'
require 'json'

class AppConfigLoader
  attr_reader :config_data

  def initialize
    @config_data = {}
  end

  # Головний метод для завантаження конфігурації
  def config(main_config_path, additional_configs_dir)
    # Завантажуємо основний конфіг
    main_config = load_default_config(main_config_path)

    # Завантажуємо додаткові конфіги з директорії
    additional_configs = load_config(additional_configs_dir)

    # Об'єднуємо основні та додаткові конфіги
    @config_data = main_config.merge(additional_configs)

    # Обробляємо дані, якщо передано блок
    yield(@config_data) if block_given?

    @config_data
  end

  # Метод для виводу конфігурації у форматі JSON
  def pretty_print_config_data
    puts JSON.pretty_generate(@config_data)
  end

  private

  # Метод для завантаження основного конфігураційного файлу
  def load_default_config(path_to_yaml_file)
    config_content = File.read(path_to_yaml_file)
    erb_result = ERB.new(config_content).result
    YAML.safe_load(erb_result) || {}
  end

  # Метод для завантаження всіх YAML-файлів з директорії
  def load_config(directory)
    Dir["#{directory}/*.yaml"].each_with_object({}) do |file, configs|
      file_config = YAML.load_file(file)
      configs.merge!(file_config) if file_config.is_a?(Hash)
    end
  end

  private :load_default_config, :load_config
end

# Приклад використання
# app_config = AppConfigLoader.new
# app_config.config('../config/default_config.yaml', '../config/yaml') do |config|
#   config["environment"] = "production" # Додаткова обробка конфігурації, якщо потрібно
# end
# app_config.pretty_print_config_data
