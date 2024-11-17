require_relative 'app_config_loader'

class Engine
  attr_accessor :app_config_loader, :config, :database_manager, :parser

  def initialize()
    @app_config_loader = AppConfigLoader.new
    @app_config_loader.load_libs('lib')
    @config = nil
    @database_manager = nil
    @parser = nil
  end

  def load_config
    begin
      @app_config_loader.config('config/default_config.yaml', 'config/yaml')
      @config = @app_config_loader.config_data
      puts "Configuration loaded successfully:"
      @app_config_loader.pretty_print_config_data()
    rescue => e
      log_error("Failed to load configuration: #{e.message}", :error)
      raise
    end
  end

  def run(config_params)
    begin
      load_config
      initialize_logging

      @database_manager = DatabaseConnector.new @config['database_config']
      # конфлікт у постановці завдання. З однієї сторони, тип бази даних
      # визначається конфігурацією. З іншої, в config_params може бути як
      # run_save_to_sqlite, так і run_save_to_mongodb. Тому підключення до
      # бази данних відбувається в цих методах, а не тут
      # connect_to_database

      @parser = SimpleWebsiteParser.new @config 

      run_methods(config_params)
    rescue => e
      log_error("Failed to load configuration: #{e.message}")
      raise
    end
  end

  def run_methods(config_params)
    puts config_params
    unless config_params["run_website_parser"]
      log_info("run_website_parser is 0")
      return
    end

    config_params.each do |method_name, to_run|
      begin
        unless respond_to?(method_name, true)
          log_info("Method #{method_name} not found")
        end
        if to_run
          send(method_name)
        end
      rescue => e
        log_error("Error while executing #{method_name}: #{e.message}")
      end
    end
  end

  private

  def initialize_logging
    MyApplicationName::LoggerManager.setup(@config['logging'])
    MyApplicationName::LoggerManager.log_info('LoggerManager has been initialized successfully')
  end

  def log_info(msg)
    MyApplicationName::LoggerManager.log_info(msg)
  end

  def log_error(msg)
    MyApplicationName::LoggerManager.log_error(msg)
  end

  def connect_to_database
    begin
      @database_manager = database_manager.new(@config['database_config'])
      @database_manager.connect_to_database if @database_manager
    rescue => e
      log_error("Error while connecting to database: #{e.message}")
    end
  end

  def run_website_parser
    @parser.start_parse
  end

  def run_save_to_csv
    @parser.item_collection.save_to_csv(@config['default']['data_file_prefix'] + '.csv')
  end

  def run_save_to_json
    @parser.item_collection.save_to_json(@config['default']['data_file_prefix'] + '.json')
  end
  
  def run_save_to_yaml
    @parser.item_collection.save_to_yml(@config['default']['data_file_prefix'] + '_yml_dir')
  end
  
  def run_save_to_sqlite
    puts @parser.item_collection
    begin
      @database_manager.connect_to_sqlite
      @database_manager.save_parsed_data(@parser.item_collection)
    rescue => e
      log_error("Failed to save to sqlite: #{e.message}")
    ensure
      @database_manager.close_connection
    end
  end

  def run_save_to_mongodb
    puts @parser.item_collection
    begin
      @database_manager.connect_to_mongodb
      @database_manager.save_parsed_data(@parser.item_collection)
    rescue => e
      log_error("Failed to save to sqlite: #{e.message}")
    ensure
      @database_manager.close_connection
    end
  end
end
