require 'faker'

Faker::Config.random = Random.new(1234)

module MyApplicationName
  class Item
    include Comparable

    attr_accessor :id, :name, :price, :rating, :rating_amount, :image_path

    def initialize(params = {})
      @id = params[:id] || nil
      @name = params[:name] || "Placeholder"
      @price = params[:price] || 0.0
      @rating = params[:rating] || 0.0
      @rating_amount = params[:rating_amount] || 0
      @image_path = params[:image_path] || "default.png"

      if @id.nil?
        LoggerManager.log_error("ID has been not received")
        raise "ID has been not received"
      end

      if @id <= 0
        LoggerManager.log_error("Invalid id #{@id}. ID cannot be negative.")
        raise "Id cannot be negative"
      end

      if @price < 0
        LoggerManager.log_error("Invalid price #{@price}. Price cannot be negative.")
        raise "Price cannot be negative"
      end

      if @rating < 0 || @rating > 5
        LoggerManager.log_error("Invalid rating #{@rating}. Rating must be between 0 and 5.")
        raise "Rating must be between 0 and 5"
      end

      if @rating_amount < 0
        LoggerManager.log_error("Invalid rating amount #{@rating_amount}. Rating amount cannot be negative.")
        raise "Rating amount cannot be negative"
      end

      LoggerManager.log_processed_file("Item initialized with name: #{@name}, price: #{@price}, rating: #{@rating}, rating_amount: #{@rating_amount}, image_path: #{@image_path}")

      yield(self) if block_given?
    end

    def to_s
      attributes = instance_variables.map { |var| "#{var.to_s.delete('@')}: #{instance_variable_get(var)}" }
      "Item Details - " + attributes.join(", ")
    end

    alias_method :info, :to_s

    def to_h
      instance_variables.each_with_object({}) do |var, hash|
        hash[var.to_s.delete('@').to_sym] = instance_variable_get(var)
      end
    end
  
    def inspect
      "#<#{self.class} #{to_h.inspect}>"
    end

    def update
      yield(self) if block_given?
      LoggerManager.log_processed_file("Item updated with name: #{@name}, price: #{@price}, rating: #{@rating}, rating_amount: #{@rating_amount}, image_path: #{@image_path}")
    end

    def self.generate_fake
      item = Item.new(
        name: Faker::Commerce.product_name,
        price: Faker::Commerce.price,
        rating: Faker::Number.between(from: 1, to: 5),
        rating_amount: Faker::Number.between(from: 1, to: 1000),
        image_path: Faker::LoremFlickr.image,
      )
      LoggerManager.log_processed_file("Generated fake Item: #{item.to_s}")
      item
    end

    def <=>(other)
      self.price <=> other.price
    end
  end
end
