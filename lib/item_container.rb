module ItemContainer

    module ClassMethods
      def class_info
        "#{self.name} - Version 1.0"
      end

      def object_count
        if class_variable_defined?(:@@object_num)
          @@object_num
        else
          LoggerManager.log_error("Error: class variable '@@object_count' is not initialized")
          raise "Class variable '@@object_count' is not initialized"
        end
      end

      def increment_count
        @@object_num ||= 0
        @@object_num += 1
      end
    end

    module InstanceMethods
      def add_item(item)
        @items << item
        MyApplicationName::LoggerManager.log_processed_file("Item added: #{item.to_s}")
      end

      def remove_item(item)
        @items.delete(item)
        MyApplicationName::LoggerManager.log_processed_file("Item removed: #{item.to_s}")
      end

      def delete_items
        @items.clear
        MyApplicationName::LoggerManager.log_processed_file("All items cleared from collection")
      end

      def show_all_items
        @items.each { |item| puts item.to_s }
      end
    end

    def self.included(base)
      base.extend ClassMethods
      base.include InstanceMethods
    end
  end