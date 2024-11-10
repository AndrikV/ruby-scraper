require 'sqlite3'
require 'mongo'
require 'yaml'

class DatabaseConnector
  attr_accessor :db

  def initialize(config)
    @config = config
    @db = nil
  end

  def connect_to_database
    case @config['database_type']
    when 'sqlite'
      connect_to_sqlite
    when 'mongodb'
      connect_to_mongodb
    else
      raise "Unsupported database type: #{@config['database_type']}"
    end
  rescue => e
    puts "Error connecting to database: #{e.message}"
  end

  def close_connection
    if @db
      @db.close if @config['database_type'] == 'sqlite'
      @db.close if @config['database_type'] == 'mongodb'
      @db = nil
      puts 'Database connection closed.'
    else
      puts 'No active database connection to close.'
    end
  rescue => e
    puts "Error closing database connection: #{e.message}"
  end

  private

  def connect_to_sqlite
    db_path = @config['sqlite_database']['db_file']
    @db = SQLite3::Database.new(db_path)
    puts "Connected to SQLite database at #{db_path}"
  rescue => e
    puts "Error connecting to SQLite: #{e.message}"
  end

  def connect_to_mongodb
    url = @config['mongodb_database']['url']
    database_name = @config['mongodb_database']['db_name']
    @db = Mongo::Client.new("#{url}/#{database_name}")
    puts "Connected to MongoDB database: #{database_name}"
  rescue => e
    puts "Error connecting to MongoDB: #{e.message}"
  end
end
