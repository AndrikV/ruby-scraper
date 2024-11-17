require 'sqlite3'
require 'mongo'
require 'yaml'

class DatabaseConnector
  attr_reader :db, :config

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
      @db.close
      @db = nil
      puts 'Database connection closed.'
    else
      puts 'No active database connection to close.'
    end
  rescue => e
    puts "Error closing database connection: #{e.message}"
  end

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

  def save_parsed_data(item_collection)
    puts item_collection
    if @db.instance_of? Mongo::Client
      begin
        collection = @db[:data]
        collection.insert_many(item_collection.map(&:to_h))
        puts "Parsed data has been saved to MongoDB database successfully"
      rescue => e
        puts "Failed to save parsed data to MongoDB: #{e.message}"
        raise
      end
      return
    end

    if @db.instance_of? SQLite3::Database
      begin
        db.execute <<-SQL
          CREATE TABLE IF NOT EXISTS data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            laptop_name TEXT,
            price INTEGER,
            rating INTEGER,
            rating_amount INTEGER,
            image_path TEXT
          );
        SQL
        puts "Table `data` ensured to exist"

        item_collection.each { |item|
          @db.execute("INSERT INTO data (laptop_name, price, rating, rating_amount, image_path) VALUES (?, ?, ?, ?, ?);", 
                      [item.name, item.price, item.rating, item.rating_amount, item.image_path])
        }      
        puts "Parsed data has been saved to SQLite database successfully"
      rescue => e
        puts "Failed to save parsed data to SQLite database: #{e.message}"
        raise
      end
      return
    end

    puts "Warning: no database is connected or unsupported type of database"
  end
end
