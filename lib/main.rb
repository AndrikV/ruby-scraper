require_relative 'app_config_loader'
require_relative 'logger'

app_config = AppConfigLoader.new
app_config.load_libs('../lib')
app_config.config('config/default_config.yaml', 'config/yaml')
app_config.pretty_print_config_data()
MyApplicationName::LoggerManager.setup(app_config.config_data['logging'])
MyApplicationName::LoggerManager.log_processed_file('Processed a file successfully.')
MyApplicationName::LoggerManager.log_error('An error occurred while processing the file.')