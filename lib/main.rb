require_relative 'app_config_loader'
require_relative 'logger_manager'
require_relative 'item'
require_relative 'item_container'
require_relative 'item_collection'

app_config = AppConfigLoader.new
app_config.load_libs('../lib')
app_config.config('config/default_config.yaml', 'config/yaml')
app_config.pretty_print_config_data()
MyApplicationName::LoggerManager.setup(app_config.config_data['logging'])
# MyApplicationName::LoggerManager.log_processed_file('Processed a file successfully.')
# MyApplicationName::LoggerManager.log_error('An error occurred while processing the file.')


# # Item Validation 
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
item_collection = MyApplicationName::ItemCollection.new
item_collection.generate_test_items(5)

names = item_collection.map { |item| item.name }
puts "Mapped Names: #{names}"

data = item_collection.map { |item| item.to_s}
puts "Map ---------------------"
puts data
puts "Map_end---------------------"
selected_items = item_collection.select { |item| item.price > 70 }

puts "Selected Items (Price > 70):"
puts "Select ---------------------"
selected_items.each { |item| puts item.to_s }
puts "Select_end---------------------"


rejected_items = item_collection.reject { |item| item.rating.to_i > 3 }
puts "Rejected Items (Rating =< 4):"
puts "Reject ---------------------"
rejected_items.each { |item| puts item.to_s }
puts "Reject_end ---------------------"

puts "Find -----------------"
found_item = item_collection.find { |item| item.name == "Durable Granite Bench" }
puts "Found Item: #{found_item.to_s if found_item}"
puts "Find_end -----------------"

puts "Reduce -----------------"
total_price = item_collection.reduce(0) { |sum, item| item.price + sum}
puts "Total Price of All Items: #{total_price}"
puts "Reduce_end -----------------"

puts "All? -----------------"
all_high_rating = item_collection.all? { |item| item.rating < 5 }
puts "All items have rating less than 5: #{all_high_rating}"
puts "All?_end -----------------"

puts "Any? -----------------"
any_low_price = item_collection.any? { |item| item.price < 10 }
puts "Any item has a price less than 10: #{any_low_price}"
puts "Any?_end -----------------"

puts "None? -----------------"
none_low_rating = item_collection.none? { |item| item.rating == 1 }
puts "No item has a rating of 1: #{none_low_rating}"
puts "None?_end -----------------"

puts "Count -----------------"
count_high_rating = item_collection.count { |item| item.rating > 3 }
puts "Count of items with rating > 3: #{count_high_rating}"
puts "Count_end -----------------"

puts "Sort -----------------"
sorted_by_price = item_collection.sort { |a, b| a.price <=> b.price }
puts "Sorted by Price (Ascending):"
sorted_by_price.each { |item| puts "#{item.name}: #{item.price}" }
puts "Sort_end -----------------"

puts "Uniq -----------------"
unique_items = item_collection.uniq
puts "Unique Items:"
unique_items.each { |item| puts item.to_s }
puts "Uniq_end -----------------"


item_collection.save_to_file('items.txt')
item_collection.save_to_json('items.json')
item_collection.save_to_csv('items.csv')
item_collection.save_to_yml('items_yml_directory')

puts "Class Info: #{MyApplicationName::ItemCollection.class_info}"
puts "Object Count: #{MyApplicationName::ItemCollection.object_count}"

collection = MyApplicationName::ItemCollection.new

puts "Object Count: #{MyApplicationName::ItemCollection.object_count}"

item1 = MyApplicationName::Item.generate_fake
item2 = MyApplicationName::Item.generate_fake
item3 = MyApplicationName::Item.generate_fake

puts "=== Adding Items ==="
collection.add_item(item1)
collection.add_item(item2)
collection.add_item(item3)

puts "Items after adding:"
collection.show_all_items
puts "\n"

puts "=== Removing an Item ==="
collection.remove_item(item2)

puts "Items after removing item2:"
collection.show_all_items
puts "\n"

puts "=== Deleting All Items ==="
collection.delete_items

puts "Items after deleting all:"
collection.show_all_items
puts "\n"
