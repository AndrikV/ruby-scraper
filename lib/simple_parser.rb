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
    
    MyApplicationName::LoggerManager.log_processed_file("Start parsing process")
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
    MyApplicationName::LoggerManager.log_processed_file("The process of laptop links extraction has been started")
    
    @wait.until { @agent.find_element(css: "body") }
    sleep(@config['web_scraping']['start_page']['delay_seconds'])

    items = @agent.find_elements(class: @config['web_scraping']['start_page']['laptops_link_class'])
    links = []

    items.each_with_index do |item, index|
      links << item.attribute('href')
      MyApplicationName::LoggerManager.log_processed_file("Item #{index + 1} Link: #{item.attribute('href')}")
      break if index > @config['web_scraping']['start_page']['max_count_of_laptops']
    end
    MyApplicationName::LoggerManager.log_processed_file("Extracted #{links.size} laptop links")
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
        MyApplicationName::LoggerManager.log_processed_file("Parsed product: #{name}")
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
    MyApplicationName::LoggerManager.log_processed_file("Saved image for #{id} at #{image_path}")
  end

  def setup_media_dir
    media_dir = @config['default']['media_dir']
    FileUtils.mkdir_p(media_dir) unless Dir.exist?(media_dir)
    MyApplicationName::LoggerManager.log_processed_file("Media directory is set up at #{media_dir}")
  end
end
