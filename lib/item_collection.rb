require 'faker'
require 'json'
require 'csv'
require 'yaml'
require 'concurrent-ruby'
require_relative 'item_container'

module MyApplicationName  
  class ItemCollection
    include ItemContainer
    include Enumerable

    attr_accessor :items

    @@object_num = 0

    def initialize
      @items = Concurrent::Array.new
      self.class.increment_count
      LoggerManager.log_processed_file("ItemCollection initialized")
    end

    def each(&block)
      @items.each(&block)
    end

    def save_to_file(filename)
      File.open(filename, 'w') { |file| @items.each { |item| file.puts item.to_s } }
      LoggerManager.log_processed_file("Items saved to text file: #{filename}")
    end

    def save_to_json(filename)
      File.open(filename, 'w') { |file| file.write(JSON.pretty_generate(@items.map(&:to_h))) }
      LoggerManager.log_processed_file("Items saved to JSON file: #{filename}")
    end

    def save_to_csv(filename)
      CSV.open(filename, 'w') do |csv|
        csv << ['name', 'price', 'rating', 'rating_amount', 'image_path']
        @items.each { |item| csv << [item.name, item.price, item.rating, item.rating_amount, item.image_path] }
      end
      LoggerManager.log_processed_file("Items saved to CSV file: #{filename}")
    end

    def save_to_yml(directory)
      Dir.mkdir(directory) unless Dir.exist?(directory)
      @items.each_with_index do |item, index|
        File.open("#{directory}/item_#{index + 1}.yml", 'w') { |file| file.write(item.to_h.to_yaml) }
      end
      LoggerManager.log_processed_file("Items saved to YAML files in directory: #{directory}")
    end

    def generate_test_items(count = 5)
      count.times do
        add_item(Item.generate_fake)
      end
    end

    def map(&block)
      @items.map(&block)
    end
    
    def select(&block)
      @items.select(&block)
    end
    
    def reject(&block)
      @items.reject(&block)
    end
  
    def find(&block)
      @items.find(&block)
    end
  
    def reduce(initial = nil, &block)
      @items.reduce(initial, &block)
    end

    def all?(&block)
      @items.all?(&block)
    end

    def any?(&block)
      @items.any?(&block)
    end

    def none?(&block)
      @items.none?(&block)
    end

    def count(&block)
      @items.count(&block)
    end

    def sort(&block)
      @items.sort(&block)
    end

    def uniq
      @items.uniq
    end
  end
end