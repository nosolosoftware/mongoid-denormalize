require 'mongoid-denormalize/version'

module Mongoid
  module Denormalize
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def denormalize(*args)
        *fields, options = args

        unless options.is_a?(Hash) && options[:from]
          raise ArgumentError, 'Option :from is needed (e.g. denormalize :name, from: :user).'
        end

        fields = Mongoid::Denormalize.get_fields_with_names(self, fields, options)

        # Add fields to model (avoid overwrite)
        fields.each { |field| field(field[:as]) unless self.fields[field[:as].to_s] }

        # Add hooks
        Mongoid::Denormalize.add_hook_to_child(self, fields, options)
        Mongoid::Denormalize.add_hook_to_parent(self, fields, options)
      end
    end

    # Check options and return name for each field
    def self.get_fields_with_names(child_class, fields, options)
      parent = parent_class(child_class, options[:from].to_s)

      if options.include?(:as)
        options[:as] = [options[:as]] unless options[:as].is_a?(Array)

        unless fields.size == options[:as].size
          raise ArgumentError, 'When option :as is used you must pass a name for each field.'
        end

        return fields.map.with_index do |field, index|
          {name: field, as: options[:as][index], type: field_type(parent, field)}
        end
      elsif options.include?(:prefix)
        return fields.map do |field|
          {name: field, as: "#{options[:prefix]}_#{field}", type: field_type(parent, field)}
        end
      end

      fields.map do |field|
        {name: field, as: "#{options[:from]}_#{field}", type: field_type(parent, field)}
      end
    end

    # Add hook to child class to denormalize fields when parent relation is changed
    def self.add_hook_to_child(child_class, fields, options)
      from = options[:from].to_s

      child_class.send(options[:child_callback] || 'before_save') do
        if send("#{from}_id_changed?")
          fields.each do |field|
            send("#{field[:as]}=", send(from)&.send(field[:name]))
          end
        end
      end
    end

    # Add hook to parent class to denormalize fields when parent object is updated
    def self.add_hook_to_parent(child_class, fields, options)
      from = options[:from].to_s

      parent = parent_class(child_class, from)

      relation = parent.relations[child_class.relations[from].inverse_of.to_s] ||
                 parent.relations[child_class.model_name.plural] ||
                 parent.relations[child_class.model_name.singular]

      unless relation
        raise "Option :inverse_of is needed for 'belongs_to :#{from}' into #{child_class}."
      end

      parent.after_update do
        attributes = {}
        fields.each do |field|
          attributes[field[:as]] = send(field[:name]) if send("#{field[:name]}_changed?")
        end
        next if attributes.blank?

        case relation.relation.to_s
        when 'Mongoid::Relations::Referenced::One'
          if (document = send(relation.name))
            document.collection.update_one({_id: document._id}, {'$set' => attributes})
          end
        when 'Mongoid::Relations::Referenced::Many'
          send(relation.name).update_all('$set' => attributes)
        else
          raise "Relation type unsupported: #{relation.relation}"
        end
      end
    end

    # Retrieve parent class
    def self.parent_class(child_class, from)
      (child_class.relations[from].class_name || child_class.relations[from].name.capitalize)
        .constantize
    end

    # Retreive the type of a field from the given class
    def self.field_type(klass, field)
      klass.fields[field.to_s].options[:type]
    end
  end
end
