require 'selenium-webdriver'
require 'fileutils'
require 'open-uri'
require 'thread'

class SimpleWebsiteParser
  attr_reader :config, :agent, :item_collection

  def initialize(config)
    @config = config
    @mutex = Mutex.new
    
    options = Selenium::WebDriver::Firefox::Options.new
    options.add_argument('--headless')
    @agent = Selenium::WebDriver.for :firefox, options: options

    @wait = Selenium::WebDriver::Wait.new(timeout: @config['web_scraping']['timeout'])
    @item_collection = MyApplicationName::ItemCollection.new

    setup_media_dir
  end

  def start_parse
    log_mutex = Mutex.new
    
    MyApplicationName::LoggerManager.log_info("Start parsing process")
    url = @config['web_scraping']['start_page']['link']

    if check_url_response(url)
      links = extract_products_links()
    
      threads = links.map do |link|
        Thread.new { parse_page(link) }
        end
      threads.each(&:join)
      # links.each do |link|
      #   parse_page(link)
      # end
      
    else
      MyApplicationName::LoggerManager.log_error("Start page is not accessible: #{url}")
    end
  end

  def check_url_response(url)
    MyApplicationName::LoggerManager.log_info("Checking URL response: #{url}")
    begin
      @agent.get(url)
      @wait.until { @agent.find_element(css: 'body') }
      true
    rescue
      MyApplicationName::LoggerManager.log_error("URL not accessible: #{url}")
      false
    end
  end

  def check_item_url_response(url)
    MyApplicationName::LoggerManager.log_info("Checking URL response: #{url}")
    
    begin
      @agent.get(url)
      @wait.until { @agent.find_element(css: @config['web_scraping']['laptop']['rating_selector']) }
      true
    rescue
      begin
        check_url_response(url)
        true
      rescue
        MyApplicationName::LoggerManager.log_error("URL not accessible: #{url}")
        false
      end
    end
  end

  def extract_products_links()    
    MyApplicationName::LoggerManager.log_info("The process of laptop links extraction has been started")
    
    @wait.until { @agent.find_element(css: "body") }
    sleep(@config['web_scraping']['start_page']['delay_seconds'])

    items = @agent.find_elements(class: @config['web_scraping']['start_page']['laptops_link_class'])
    links = []

    items.each_with_index do |item, index|
      links << item.attribute('href')
      MyApplicationName::LoggerManager.log_info("Item #{index + 1} Link: #{item.attribute('href')}")
      break if index > @config['web_scraping']['start_page']['max_count_of_laptops']
    end
    MyApplicationName::LoggerManager.log_info("Extracted #{links.size} laptop links")
    links
  end

  def parse_page(link)
    check = false
    @mutex.synchronize do
      check = check_item_url_response(link)
    end
    if check
      
      id = nil
      name = ''
      price = 0
      rating = 0
      rating_amount = 0
      image_url = ''

      @mutex.synchronize do
        @agent.get(link)
        begin
          @wait.until { @agent.find_element(css: @config['web_scraping']['laptop']['rating_selector']) }
        rescue
          @wait.until { @agent.find_element(css: 'body') }
        end
      
        id = extract_id
        name = extract_name
        price = extract_price
        rating = extract_rating
        rating_amount = extract_rating_amount
        image_url = extract_image
      end

      save_image(image_url, id)

      item = MyApplicationName::Item.new(id: id, name: name, price: price, rating: rating, rating_amount: rating_amount, image_path: image_url)
      item_collection.add_item(item)
      @mutex.synchronize do
        MyApplicationName::LoggerManager.log_info("Parsed product: #{name}")
      end
    else
      @mutex.synchronize do
        MyApplicationName::LoggerManager.log_error("Product page not accessible: #{link}")
      end
    end
  end

  def extract_id
    @agent.find_element(css: @config['web_scraping']['laptop']['id_selector']).text.strip[/\d+$/].to_i
  end

  def extract_name
    @agent.find_element(css: @config['web_scraping']['laptop']['name_selector']).text.strip
  end

  def extract_price
    begin
      @agent.find_element(css: @config['web_scraping']['laptop']['price_selector']).text.strip.gsub(/[^\d]/, '').to_i
    rescue
      begin
        @agent.find_element(css: @config['web_scraping']['laptop']['price_alt_selector']).text.strip.gsub(/[^\d]/, '').to_i
      rescue
        raise "Unknown price errr"
      end
    end
  end

  def extract_rating
    begin
      @agent.find_element(css: @config['web_scraping']['laptop']['rating_selector'])['style'][/\d+(\.\d+)?(?=%)/].to_f * 5 / 100
    rescue
      nil
    end
  end

  def extract_rating_amount
    begin
      @agent.find_element(css: @config['web_scraping']['laptop']['rating_amount_selector']).text.strip[/\d+/].to_i
    rescue
      nil
    end
  end

  def extract_image
    @agent.find_element(css: @config['web_scraping']['laptop']['image_selector'])['src']
  end

  def save_image(image_url, id)
    image_path = File.join(@config['default']['media_dir'], "#{id}.jpg")
    
    URI.open(image_url) do |image|
      File.open("#{image_path}.jpg", 'wb') do |file|
      file.write(image.read)
      end
    end
    MyApplicationName::LoggerManager.log_info("Saved image for #{id} at #{image_path}")
  end

  def setup_media_dir
    media_dir = @config['default']['media_dir']
    FileUtils.mkdir_p(media_dir) unless Dir.exist?(media_dir)
    MyApplicationName::LoggerManager.log_info("Media directory is set up at #{media_dir}")
  end
end

# TESTS
#
# Item Validation 
# item1 = MyApplicationName::Item.new(
#   name: "Sample Product",
#   price: 99.99,
#   rating: 4.5,
#   rating_amount: 150,
#   image_path: "/images/sample.png"
# )
# puts item1.info

# item2 = MyApplicationName::Item.new(name: "Partial Product", price: 49.99)
# puts item2.info

# item3 = MyApplicationName::Item.new
# puts item3.info


# fake_item = MyApplicationName::Item.generate_fake
# puts fake_item.info

# item1.update do |i|
#   i.name = "Updated Product"
#   i.price = 120.00
# end
# puts item1.info

# item4 = MyApplicationName::Item.new(name: "Item A", price: 10.0)
# item5 = MyApplicationName::Item.new(name: "Item B", price: 20.0)

# if item4 < item5
#   puts "#{item4.name} is cheaper than #{item5.name}"
# else
#   puts "#{item5.name} is cheaper than #{item4.name}"
# end

# puts item1.to_h.inspect

# begin
#   item1.name = nil
#   puts item1.to_s
# rescue => e
#   puts "Caught an error during to_s: #{e.message}"
# end

# puts item2.inspect

# item1.update do |i|
#   i.rating = 3.5
#   i.rating_amount = 200
# end
# puts item1.info

# item_fault = MyApplicationName::Item.new(name: "Item A", price: -10.0)



# ItemCollection Validation
# item_collection = MyApplicationName::ItemCollection.new
# item_collection.generate_test_items(5)

# names = item_collection.map { |item| item.name }
# puts "Mapped Names: #{names}"

# data = item_collection.map { |item| item.to_s}
# puts "Map ---------------------"
# puts data
# puts "Map_end---------------------"
# selected_items = item_collection.select { |item| item.price > 70 }

# puts "Selected Items (Price > 70):"
# puts "Select ---------------------"
# selected_items.each { |item| puts item.to_s }
# puts "Select_end---------------------"


# rejected_items = item_collection.reject { |item| item.rating.to_i > 3 }
# puts "Rejected Items (Rating =< 4):"
# puts "Reject ---------------------"
# rejected_items.each { |item| puts item.to_s }
# puts "Reject_end ---------------------"

# puts "Find -----------------"
# found_item = item_collection.find { |item| item.name == "Durable Granite Bench" }
# puts "Found Item: #{found_item.to_s if found_item}"
# puts "Find_end -----------------"

# puts "Reduce -----------------"
# total_price = item_collection.reduce(0) { |sum, item| item.price + sum}
# puts "Total Price of All Items: #{total_price}"
# puts "Reduce_end -----------------"

# puts "All? -----------------"
# all_high_rating = item_collection.all? { |item| item.rating < 5 }
# puts "All items have rating less than 5: #{all_high_rating}"
# puts "All?_end -----------------"

# puts "Any? -----------------"
# any_low_price = item_collection.any? { |item| item.price < 10 }
# puts "Any item has a price less than 10: #{any_low_price}"
# puts "Any?_end -----------------"

# puts "None? -----------------"
# none_low_rating = item_collection.none? { |item| item.rating == 1 }
# puts "No item has a rating of 1: #{none_low_rating}"
# puts "None?_end -----------------"

# puts "Count -----------------"
# count_high_rating = item_collection.count { |item| item.rating > 3 }
# puts "Count of items with rating > 3: #{count_high_rating}"
# puts "Count_end -----------------"

# puts "Sort -----------------"
# sorted_by_price = item_collection.sort { |a, b| a.price <=> b.price }
# puts "Sorted by Price (Ascending):"
# sorted_by_price.each { |item| puts "#{item.name}: #{item.price}" }
# puts "Sort_end -----------------"

# puts "Uniq -----------------"
# unique_items = item_collection.uniq
# puts "Unique Items:"
# unique_items.each { |item| puts item.to_s }
# puts "Uniq_end -----------------"


# item_collection.save_to_file('items.txt')
# item_collection.save_to_json('items.json')
# item_collection.save_to_csv('items.csv')
# item_collection.save_to_yml('items_yml_directory')

# puts "Class Info: #{MyApplicationName::ItemCollection.class_info}"
# puts "Object Count: #{MyApplicationName::ItemCollection.object_count}"

# collection = MyApplicationName::ItemCollection.new

# puts "Object Count: #{MyApplicationName::ItemCollection.object_count}"

# item1 = MyApplicationName::Item.generate_fake
# item2 = MyApplicationName::Item.generate_fake
# item3 = MyApplicationName::Item.generate_fake

# puts "=== Adding Items ==="
# collection.add_item(item1)
# collection.add_item(item2)
# collection.add_item(item3)

# puts "Items after adding:"
# collection.show_all_items
# puts "\n"

# puts "=== Removing an Item ==="
# collection.remove_item(item2)

# puts "Items after removing item2:"
# collection.show_all_items
# puts "\n"

# puts "=== Deleting All Items ==="
# collection.delete_items

# puts "Items after deleting all:"
# collection.show_all_items
# puts "\n"
