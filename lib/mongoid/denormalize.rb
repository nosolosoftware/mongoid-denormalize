require "mongoid/denormalize/version"

module Mongoid
  module Denormalize
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def denormalize(*args)
        options = args.pop

        unless options.is_a?(Hash) && (from = options[:from]&.to_s)
          raise ArgumentError, 'Option :from is needed (e.g. delegate :name, from: :user).'
        end

        # Add fields to model
        args.each { |field| field "#{from}_#{field}" }

        # Denormalize fields when model is saved and 'from' has changed
        before_save do
          if send(from) && send("#{from}_id_changed?")
            args.each do |field|
              send("#{from}_#{field}=", send(from).send(field))
            end
          end
        end

        from_class = (relations[from].class_name || relations[from].name.capitalize).constantize
        model_class = model_name.name
        inverse_of = relations[from].inverse_of || model_name.route_key.pluralize

        # When 'from' is updated, update all childs
        from_class.send(:after_update) do
          attributes = {}
          args.each { |field| attributes["#{from}_#{field}"] = send(field) }

          unless relations[inverse_of.to_s]
            raise "Option :inverse_of is needed for 'belongs_to :#{from}' into #{model_class}."
          end

          send(inverse_of).update_all('$set' => attributes)
        end
      end
    end
  end
end
