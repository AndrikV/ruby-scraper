require 'logger'

module MyApplicationName
    class LoggerManager
        class << self
            
            @info_logger = nil
            @error_logger = nil

            def setup(config)
                directory = config['directory'] || './logs'
                log_level = config['level'] || 'INFO'
                files = config['files'] || { 'application_log' => 'hello.log', 'error_log' => 'error.log' }
                
                Dir.mkdir(directory) unless Dir.exist?(directory)

                @info_logger = Logger.new(File.join(directory, files['application_log']), 'daily')
                @info_logger.level = Logger.const_get(log_level.upcase)

                @error_logger = Logger.new(File.join(directory, files['error_log']), 'daily')
                @error_logger.level = Logger.const_get(log_level.upcase)
            end

            def log_processed_file(message)
                raise 'Logger not initialized' unless @info_logger
                @info_logger.info(message)
            end

            def log_error(message)
                raise 'Error Logger not initialized' unless @error_logger
                @error_logger.error(message)
            end
        end
    end
end
