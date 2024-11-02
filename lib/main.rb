require_relative 'logger/logger'
require 'yaml'

config_path = './config/yaml/logging.yaml'
MyApplicationName::LoggerManager.setup(config_path)
MyApplicationName::LoggerManager.log_processed_file('Processed a file successfully.')
MyApplicationName::LoggerManager.log_error('An error occurred while processing the file.')