require 'selenium-webdriver'
require 'yaml'
require_relative 'logger_manager'
require 'fileutils'
require 'open-uri'
require 'thread'

class SimpleWebsiteParser
  attr_reader :config, :agent, :item_collection

  def initialize(config_path)
    @config = YAML.load_file(config_path)['web_scraping']
    @mutex = Mutex.new
    
    options = Selenium::WebDriver::Firefox::Options.new
    options.add_argument('--headless')

    @agent = Selenium::WebDriver.for :firefox, options: options
    @wait = Selenium::WebDriver::Wait.new(timeout: 10)
    @item_collection = MyApplicationName::ItemCollection.new

    setup_media_dir
  end

  def start_parse
    log_mutex = Mutex.new
    
    MyApplicationName::LoggerManager.log_processed_file("Start parsing process")
    url = config['start_page']

    if check_url_response(url)
      page = @agent.get(url)
      @wait.until { @agent.find_element(css: 'body') }

      product_links = extract_products_links(page)
    
      threads = product_links.map do |link|
        Thread.new { parse_product_page(link) }
        end
      threads.each(&:join)
      # product_links.each do |link|
      #   parse_product_page(link)
      # end
      
    else
      MyApplicationName::LoggerManager.log_error("Start page is not accessible: #{url}")
    end
  end

  def check_url_response(url)
    MyApplicationName::LoggerManager.log_processed_file("Checking URL response: #{url}")
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
    MyApplicationName::LoggerManager.log_processed_file("Checking URL response: #{url}")
    
    begin
      @agent.get(url)
      @wait.until { @agent.find_element(css: @config['product_rating_selector']) }

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

  def extract_products_links(page)
    css_selector_item = @config['product_links_selector']
    css_selector_list = @config['product_list_selector']
    
    @wait.until { @agent.find_element(css: css_selector_list) }

    ul = @agent.find_element(css: css_selector_list)
    items = ul.find_elements(css: 'li')
    links = []

    items.each_with_index do |item, index|
      link_element = item.find_element(css: css_selector_item)
      links << link_element.attribute('href')
      MyApplicationName::LoggerManager.log_processed_file("Item #{index + 1} Link: #{link_element.attribute('href')}")
    end
    MyApplicationName::LoggerManager.log_processed_file("Extracted #{links.size} product links")
    links
  end

  def parse_product_page(product_link)
    check = false
    @mutex.synchronize do
      check = check_item_url_response(product_link)
    end
    if check
      
      name = ''
      price = 0
      rating = 0
      rating_amount = 0
      image_url = ''

      @mutex.synchronize do
        @agent.get(product_link)
        begin
          @wait.until { @agent.find_element(css: @config['product_rating_selector']) }
        rescue
          @wait.until { @agent.find_element(css: 'body') }
        end
      

        name = extract_product_name
        price = extract_product_price
        rating = extract_product_rating
        rating_amount = extract_product_rating_amount
        image_url = extract_product_image
      end

      save_image(image_url, name)

      item = MyApplicationName::Item.new(name: name, price: price, rating: rating, rating_amount: rating_amount, image_path: image_url)
      item_collection.add_item(item)
      @mutex.synchronize do
        MyApplicationName::LoggerManager.log_processed_file("Parsed product: #{name}")
      end
    else
      @mutex.synchronize do
        MyApplicationName::LoggerManager.log_error("Product page not accessible: #{product_link}")
      end
    end
  end

  def extract_product_name
    @agent.find_element(css: config['product_name_selector']).text.strip
  end

  def extract_product_price
    begin
      @agent.find_element(css: config['product_price_selector']).text.strip.gsub(/[^\d]/, '').to_i
    rescue
      begin
        @agent.find_element(css: config['product_price_alt_selector']).text.strip.gsub(/[^\d]/, '').to_i
      rescue
        raise "Unknown price errr"
      end
    end
  end

  def extract_product_rating
    begin
      @agent.find_element(css: config['product_rating_selector'])['style'][/\d+(\.\d+)?(?=%)/].to_f * 5 / 100
    rescue
      nil
    end
  end

  def extract_product_rating_amount
    begin
      @agent.find_element(css: config['product_rating_amount_selector']).text.strip[/\d+/].to_i
    rescue
      nil
    end
  end

  def extract_product_image
    @agent.find_element(css: config['product_image_selector'])['src']
  end

  def save_image(image_url, product_name)
    image_path = File.join('media_dir', "#{sanitize_filename(product_name)}.jpg")
    
    URI.open(image_url) do |image|
      File.open("#{image_path}.jpg", 'wb') do |file|
      file.write(image.read)
      end
    end
    MyApplicationName::LoggerManager.log_processed_file("Saved image for #{product_name} at #{image_path}")
  end

  def setup_media_dir
    media_dir = 'media_dir'
    FileUtils.mkdir_p(media_dir) unless Dir.exist?(media_dir)
    MyApplicationName::LoggerManager.log_processed_file("Media directory is set up at #{media_dir}")
  end

  def sanitize_filename(filename)
    filename.gsub(/[^0-9A-Za-z.\-]/, '_')
  end
end
