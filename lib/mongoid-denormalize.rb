require "mongoid-denormalize/version"

module Mongoid
  module Denormalize
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def denormalize(*fields)
        @_denormalize_options = fields.pop
        @_denormalize_fields = fields

        unless @_denormalize_options.is_a?(Hash) && (from = @_denormalize_options[:from]&.to_s)
          raise ArgumentError, 'Option :from is needed (e.g. delegate :name, from: :user).'
        end

        if @_denormalize_options.include?(:as) && fields.size > 1
          raise ArgumentError, 'When option :as is used only one unique field could be specified.'
        end

        @_denormalize_fields.map! { |field| {name_in_children: name_for_field(field), name_in_parent: field} }

        # Add fields to model
        @_denormalize_fields.each { |field| field field[:name_in_children] }

        # Denormalize fields when model is saved and 'from' has changed
        before_save do
          if send(from) && send("#{from}_id_changed?")
            fields.each do |field|
              send("#{field[:name_in_children]}=", send(from).send(field[:name_in_parent])) if send(from).respond_to?(field[:name_in_parent])
            end
          end
        end

        if relations[from].polymorphic?
          unless (inverses_of = @_denormalize_options[:inverses_of] || inverses_of.is_a?(Array))
            raise ArgumentError, 'Option :inverses_of is needed with an Array when the relation is polymorphic.'
          end

          inverses_of.each do |inverse_of|
            from_class = inverse_of.to_s.capitalize.constantize
            send_after_update_hook(from_class)
          end
        else
          from_class = (relations[from].class_name || relations[from].name.capitalize).constantize
          send_after_update_hook(from_class)
        end
      end

      protected

      def name_for_field(field)
        return @_denormalize_options[:as] if @_denormalize_options.include?(:as)
        return "#{@_denormalize_options[:prefix]}_#{field}" if @_denormalize_options.include?(:prefix)
        "#{@_denormalize_options[:from]}_#{field}"
      end

      def send_after_update_hook(from_class)
        from = @_denormalize_options[:from].to_s
        fields = @_denormalize_fields
        child_model_name = model_name
        child_inverse_of = relations[from].inverse_of

        # When 'from' is updated, update child/childs
        from_class.send(:after_update) do
          attributes = {}
          fields.select { |field| respond_to?(field[:name_in_parent]) }
                .each { |field| attributes[field[:name_in_children]] = send(field[:name_in_parent]) }

          next if attributes.blank?

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
