class Configurator
  attr_accessor :config

  DEFAULT_CONFIG = {
    run_website_parser: 0,       # Запуск розбору сайту
    run_save_to_csv: 0,          # Збереження даних в CSV форматі
    run_save_to_json: 0,         # Збереження даних в JSON форматі
    run_save_to_yaml: 0,         # Збереження даних в YAML форматі
    run_save_to_sqlite: 0,       # Збереження даних в базі даних SQLite
    run_save_to_mongodb: 0       # Збереження даних в базі даних MongoDB
  }

  def initialize
    @config = DEFAULT_CONFIG.dup
  end

  def configure(overrides = {})
    overrides.each do |key, value|
      if @config.key?(key)
        @config[key] = value
      else
        puts "Warning: '#{key}' is not a valid configuration key"
      end
    end
  end

  def self.available_methods
    DEFAULT_CONFIG.keys
  end
end
