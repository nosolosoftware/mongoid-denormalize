require 'spec_helper'

RSpec.describe Mongoid::Denormalize do
  it 'has a version number' do
    expect(Mongoid::Denormalize::VERSION).not_to be nil
  end

  describe '.denormalize' do
    describe 'relations' do
      describe '#has_many' do
        context 'when relations target use model names' do
          before :all do
            class Parent
              include Mongoid::Document

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
            before :all do
              class Parent
                include Mongoid::Document

                field :name
                has_many :items, class_name: 'Child'
              end

              class Child
                include Mongoid::Document
                include Mongoid::Denormalize

                belongs_to :parent
              end
            end

            after :all do
              Object.send(:remove_const, :Parent)
              Object.send(:remove_const, :Child)
            end

            it 'raises error' do
              expect {
                Child.denormalize(:name, from: :parent)
              }.to raise_error(
                RuntimeError, "Option :inverse_of is needed for 'belongs_to :parent' into Child."
              )
            end
          end

          context 'when :belongs_to has :inverse_of' do
            context 'when updates parent denormalized field' do
              before :all do
                class Parent
                  include Mongoid::Document

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

      describe '#has_one' do
        context 'when updates parent denormalized field' do
          before :all do
            class Parent
              include Mongoid::Document

              field :name
              has_one :child, class_name: 'Child'
            end

            class Child
              include Mongoid::Document
              include Mongoid::Denormalize

              belongs_to :parent, inverse_of: :child
              denormalize :name, from: :parent
            end
          end

          after :all do
            Object.send(:remove_const, :Parent)
            Object.send(:remove_const, :Child)
          end

          context 'when child exists' do
            it 'updates childs denormalized fields' do
              parent = Parent.create!(name: 'parent')
              child = Child.create!(parent: parent)

              parent.update_attributes(name: 'new_name')
              expect(child.reload.parent_name).to eq('new_name')
            end
          end

          context 'when child does not exist' do
            it 'do anything' do
              parent = Parent.create!(name: 'parent')
              parent.update_attributes(name: 'new_name')
            end
          end
        end
      end
    end

    describe 'options' do
      describe '#from' do
        context 'when option is missing' do
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
            expect { Child.denormalize(:name) }.to(
              raise_error(
                ArgumentError, 'Option :from is needed (e.g. denormalize :name, from: :user).'
              )
            )
          end
        end
      end

      describe '#as' do
        context 'when all is ok' do
          before :all do
            class Parent
              include Mongoid::Document

              field :name
              field :age
              field :city
              has_many :children
            end

            class Child
              include Mongoid::Document
              include Mongoid::Denormalize

              belongs_to :parent
              denormalize :name, from: :parent, as: :custom_name
              denormalize :age, :city, from: :parent, as: %i[custom_age custom_city]
            end
          end

          after :all do
            Object.send(:remove_const, :Parent)
            Object.send(:remove_const, :Child)
          end

          context 'when creates new document' do
            it 'has denormalized field' do
              parent = Parent.create!(name: 'parent', age: 32, city: 'London')
              child = Child.create!(parent: parent)

              expect(child.custom_name).to eq('parent')
              expect(child.custom_age).to eq(32)
              expect(child.custom_city).to eq('London')
            end
          end

          context 'when updates parent denormalized field' do
            before do
              @parent = Parent.create!(name: 'parent')
              @child = Child.create!(parent: @parent)

              @parent.update_attributes(name: 'new_name')
            end

            it 'updates childs denormalized fields' do
              expect(@child.reload.custom_name).to eq(@parent.name)
            end

            it 'doesn\'t create the old from_field' do
              expect(@child.reload).not_to respond_to(:parent_name)
            end
          end

          context 'when updates relation' do
            before do
              parent = Parent.create!(name: 'parent')
              @child = Child.create!(parent: parent)

              @new_parent = Parent.create!(name: 'new_parent')
              @child.update_attributes(parent: @new_parent)
            end

            it 'updates denormalized fields' do
              expect(@child.reload.custom_name).to eq(@new_parent.name)
            end

            it 'doesn\'t create the old from_field' do
              expect(@child.reload).not_to respond_to(:parent_name)
            end
          end
        end

        context 'when the number of fields is distinct of :as option values' do
          before :all do
            class Parent
              include Mongoid::Document

              field :name
              has_many :children
            end

            class Child
              include Mongoid::Document
              include Mongoid::Denormalize

              belongs_to :parent
            end
          end

          after :all do
            Object.send(:remove_const, :Parent)
            Object.send(:remove_const, :Child)
          end

          it 'raises ArgumentError' do
            expect {
              Child.denormalize(:first_name, :last_name, from: :parent, as: :custom_name)
            }.to raise_error(
              ArgumentError, 'When option :as is used you must pass a name for each field.'
            )
          end
        end
      end

      describe '#prefix' do
        context 'when all is ok' do
          before :all do
            class Parent
              include Mongoid::Document

              field :name
              has_many :children
            end

            class Child
              include Mongoid::Document
              include Mongoid::Denormalize

              belongs_to :parent
              denormalize :name, from: :parent, prefix: :new_prefix
            end
          end

          after :all do
            Object.send(:remove_const, :Parent)
            Object.send(:remove_const, :Child)
          end

          context 'when creates new document' do
            before do
              @parent = Parent.create(name: 'name')
              @child = Child.create(parent: @parent)
            end

            it 'add childs denormalized fields' do
              expect(@child.reload.new_prefix_name).to eq(@parent.name)
            end

            it 'doesn\'t create the old from_field' do
              expect(@child.reload).not_to respond_to(:parent_name)
            end
          end

          context 'when updates relation' do
            before do
              parent = Parent.create(name: 'name')
              @new_parent = Parent.create(name: 'new_name')
              @child = Child.create(parent: parent)
              @child.update_attributes(parent: @new_parent)
            end

            it 'updates childs denormalized fields' do
              expect(@child.reload.new_prefix_name).to eq(@new_parent.name)
            end

            it 'doesn\'t create the old from_field' do
              expect(@child.reload).not_to respond_to(:parent_name)
            end
          end

          context 'when updates parent denormalized field' do
            before do
              @parent = Parent.create(name: 'name')
              @child = Child.create(parent: @parent)
              @parent.update_attributes(name: 'new_fancy_name')
            end

            it 'updates childs denormalized fields' do
              expect(@child.reload.new_prefix_name).to eq(@parent.name)
            end

            it 'doesn\'t create the old from_field' do
              expect(@child.reload).not_to respond_to(:parent_name)
            end
          end
        end
      end

      describe '#child_callback' do
        context 'when all is ok' do
          before :all do
            class Parent
              include Mongoid::Document

              field :name
              has_many :children
            end

            class Child
              include Mongoid::Document
              include Mongoid::Denormalize

              belongs_to :parent
              denormalize :name, from: :parent, child_callback: :before_validation
            end
          end

          after :all do
            Object.send(:remove_const, :Parent)
            Object.send(:remove_const, :Child)
          end

          context 'when creates new document' do
            it 'uses specified callback to denormalize' do
              parent = Parent.create!(name: 'parent')
              child = Child.new(parent: parent)

              expect(child.parent_name).to be_nil
              child.valid?
              expect(child.parent_name).to eq('parent')
            end
          end

          context 'when updates relation' do
            it 'uses specified callback to denormalize' do
              parent = Parent.create!(name: 'parent')
              child = Child.create!(parent: parent)

              new_parent = Parent.create!(name: 'new_parent')
              child.parent = new_parent

              expect(child.parent_name).to eq('parent')
              child.valid?
              expect(child.parent_name).to eq('new_parent')
            end
          end
        end
      end
    end
  end
end
