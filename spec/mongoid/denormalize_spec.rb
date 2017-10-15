require 'spec_helper'

RSpec.describe Mongoid::Denormalize do
  it 'has a version number' do
    expect(Mongoid::Denormalize::VERSION).not_to be nil
  end

  describe '.denormalize' do
    context 'when option :from is missing' do
      before :all do
        class Child
          include Mongoid::Document
          include Mongoid::Denormalize
        end
      end

      after :all do
        Object.send(:remove_const, :Child)
      end

      it 'raises ArgumentError' do
        expect {
          Child.denormalize(:name)
        }.to raise_error(ArgumentError, "Option :from is needed (e.g. delegate :name, from: :user).")
      end
    end

    describe 'hooks' do
      context 'when relations targets use model names' do
        before :all do
          class Parent
            include Mongoid::Document
            include Mongoid::Denormalize

            field :name
            has_many :children
          end

          class Child
            include Mongoid::Document
            include Mongoid::Denormalize

            belongs_to :parent
            denormalize :name, from: :parent
          end
        end

        after :all do
          Object.send(:remove_const, :Parent)
          Object.send(:remove_const, :Child)
        end

        context 'when creates new document' do
          it 'has denormalized fields' do
            parent = Parent.create!(name: 'parent')
            child = Child.create!(parent: parent)

            expect(child.parent_name).to eq('parent')
          end
        end

        context 'when updates parent denormalized field' do
          it 'updates childs denormalized fields' do
            parent = Parent.create!(name: 'parent')
            child = Child.create!(parent: parent)

            parent.update_attributes(name: 'new_name')
            expect(child.reload.parent_name).to eq('new_name')
          end
        end

        context 'when updates relation' do
          it 'updates denormalized fields' do
            parent = Parent.create!(name: 'parent')
            child = Child.create!(parent: parent)

            new_parent = Parent.create!(name: 'new_parent')
            child.update_attributes(parent: new_parent)
            expect(child.reload.parent_name).to eq('new_parent')
          end
        end
      end

      context 'when :belongs_to target name is diferent from model' do
        before :all do
          class Parent
            include Mongoid::Document
            include Mongoid::Denormalize

            field :name
            has_many :children
          end

          class Child
            include Mongoid::Document
            include Mongoid::Denormalize

            belongs_to :top, class_name: 'Parent'
            denormalize :name, from: :top
          end
        end

        after :all do
          Object.send(:remove_const, :Parent)
          Object.send(:remove_const, :Child)
        end

        context 'when creates new document' do
          it 'has denormalized fields' do
            parent = Parent.create!(name: 'parent')
            child = Child.create!(top: parent)

            expect(child.top_name).to eq('parent')
          end
        end
      end

      context 'when :has_many target name is diferent from model' do
        context 'when :belongs_to has not :inverse_of' do
          context 'when updates parent denormalized field' do
            before :all do
              class Parent
                include Mongoid::Document
                include Mongoid::Denormalize

                field :name
                has_many :items, class_name: 'Child'
              end

              class Child
                include Mongoid::Document
                include Mongoid::Denormalize

                belongs_to :parent
                denormalize :name, from: :parent
              end
            end

            after :all do
              Object.send(:remove_const, :Parent)
              Object.send(:remove_const, :Child)
            end

            it 'raises error' do
              parent = Parent.create!(name: 'parent')
              child = Child.create!(parent: parent)

              expect {
                parent.update_attributes(name: 'new_name')
              }.to raise_error(RuntimeError, "Option :inverse_of is needed for 'belongs_to :parent' into Child.")
            end
          end
        end

        context 'when :belongs_to has :inverse_of' do
          context 'when updates parent denormalized field' do
            before :all do
              class Parent
                include Mongoid::Document
                include Mongoid::Denormalize

                field :name
                has_many :items, class_name: 'Child'
              end

              class Child
                include Mongoid::Document
                include Mongoid::Denormalize

                belongs_to :parent, inverse_of: :items
                denormalize :name, from: :parent
              end
            end

            after :all do
              Object.send(:remove_const, :Parent)
              Object.send(:remove_const, :Child)
            end

            it 'updates childs denormalized fields' do
              parent = Parent.create!(name: 'parent')
              child = Child.create!(parent: parent)

              parent.update_attributes(name: 'new_name')
              expect(child.reload.parent_name).to eq('new_name')
            end
          end
        end
      end
    end
  end
end
