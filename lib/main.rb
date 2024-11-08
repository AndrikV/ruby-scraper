require_relative 'app_config_loader'
require_relative 'logger'
require_relative 'item'

app_config = AppConfigLoader.new
app_config.load_libs('../lib')
app_config.config('config/default_config.yaml', 'config/yaml')
app_config.pretty_print_config_data()
MyApplicationName::LoggerManager.setup(app_config.config_data['logging'])
# MyApplicationName::LoggerManager.log_processed_file('Processed a file successfully.')
# MyApplicationName::LoggerManager.log_error('An error occurred while processing the file.')



item1 = MyApplicationName::Item.new(
  name: "Sample Product",
  price: 99.99,
  rating: 4.5,
  rating_amount: 150,
  image_path: "/images/sample.png"
)
puts item1.info

item2 = MyApplicationName::Item.new(name: "Partial Product", price: 49.99)
puts item2.info

item3 = MyApplicationName::Item.new
puts item3.info


fake_item = MyApplicationName::Item.generate_fake
puts fake_item.info

item1.update do |i|
  i.name = "Updated Product"
  i.price = 120.00
end
puts item1.info

item4 = MyApplicationName::Item.new(name: "Item A", price: 10.0)
item5 = MyApplicationName::Item.new(name: "Item B", price: 20.0)

if item4 < item5
  puts "#{item4.name} is cheaper than #{item5.name}"
else
  puts "#{item5.name} is cheaper than #{item4.name}"
end

puts item1.to_h.inspect

begin
  item1.name = nil
  puts item1.to_s
rescue => e
  puts "Caught an error during to_s: #{e.message}"
end

puts item2.inspect

item1.update do |i|
  i.rating = 3.5
  i.rating_amount = 200
end
puts item1.info

item_fault = MyApplicationName::Item.new(name: "Item A", price: -10.0)