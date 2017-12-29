require "mongoid-denormalize/version"

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
        child_model_name = model_name
        child_inverse_of = relations[from].inverse_of

        # When 'from' is updated, update child/childs
        from_class.send(:after_update) do
          attributes = {}
          args.each { |field| attributes["#{from}_#{field}"] = send(field) }

          relation = relations[child_inverse_of.to_s] ||
                     relations[child_model_name.plural] ||
                     relations[child_model_name.singular]

          unless relation
            raise "Option :inverse_of is needed for 'belongs_to :#{from}' into #{child_model_name.name}."
          end

          case relation.relation.to_s
          when 'Mongoid::Relations::Referenced::One'
            document = send(relation.name)
            document.collection.update_one({_id: document._id}, {'$set' => attributes}) if document
          when 'Mongoid::Relations::Referenced::Many'
            send(relation.name).update_all('$set' => attributes)
          else
            raise "Relation type unsupported: #{relation.relation}"
          end
        end
      end
    end
  end
end
