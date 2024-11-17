require_relative 'engine'

engine = Engine.new

configurator = Configurator.new
configurator.configure(
  {
    "run_website_parser" => 1,
    "run_save_to_csv" => 1,
    "run_save_to_json" => 1,
    "run_save_to_yaml" => 1,
    "run_save_to_sqlite" => 1,
    "run_save_to_mongodb" => 1,
    "invalid_key" => 1  # Невалідний ключ
  }
)
puts configurator.config
puts Configurator.available_methods

engine.run configurator.config
