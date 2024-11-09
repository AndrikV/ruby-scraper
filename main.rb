require_relative 'app_config_loader'

app_config = AppConfigLoader.new
app_config.load_libs('lib')
app_config.config('config/default_config.yaml', 'config/yaml')
app_config.pretty_print_config_data()
MyApplicationName::LoggerManager.setup(app_config.config_data['logging'])
MyApplicationName::LoggerManager.log_processed_file('Processed a file successfully.')
MyApplicationName::LoggerManager.log_error('An error occurred while processing the file.')

# Тестування класу Configurator
configurator = Configurator.new
configurator.configure(
  run_website_parser: 1,
  run_save_to_csv: 1,
  run_save_to_yaml: 1,
  run_save_to_sqlite: 1,
  invalid_key: 1  # Невалідний ключ
)
puts configurator.config
puts Configurator.available_methods

connector = DatabaseConnector.new(app_config.config_data['database_config'])
connector.connect_to_database
connector.close_connection
