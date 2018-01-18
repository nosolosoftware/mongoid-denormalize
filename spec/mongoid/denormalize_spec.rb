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

      context 'when :prefix is used' do
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

        context 'when :as is also used' do
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
              denormalize :name, from: :parent, prefix: :new_prefix, as: :supername
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
              expect(@child.reload.supername).to eq(@parent.name)
            end

            it 'doesn\'t create the prefix field' do
              expect(@child.reload).not_to respond_to(:new_prefix_name)
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
              expect(@child.reload.supername).to eq(@new_parent.name)
            end

            it 'doesn\'t create the prefix field' do
              expect(@child.reload).not_to respond_to(:new_prefix_name)
            end
          end

          context 'when updates parent denormalized field' do
            before do
              @parent = Parent.create(name: 'name')
              @child = Child.create(parent: @parent)
              @parent.update_attributes(name: 'new_fancy_name')
            end

            it 'updates childs denormalized fields' do
              expect(@child.reload.supername).to eq(@parent.name)
            end

            it 'doesn\'t create the prefix field' do
              expect(@child.reload).not_to respond_to(:new_prefix_name)
            end
          end
        end
      end

      context 'when :as is used' do
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
              denormalize :name, from: :parent, as: :supername
            end
          end

          after :all do
            Object.send(:remove_const, :Parent)
            Object.send(:remove_const, :Child)
          end

          context 'when updates parent denormalized field' do
            before do
              @parent = Parent.create!(name: 'parent')
              @child = Child.create!(parent: @parent)

              @parent.update_attributes(name: 'new_name')
            end

            it 'updates childs denormalized fields' do
              expect(@child.reload.supername).to eq(@parent.name)
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
              expect(@child.reload.supername).to eq(@new_parent.name)
            end

            it 'doesn\'t create the old from_field' do
              expect(@child.reload).not_to respond_to(:parent_name)
            end
          end
        end

        context 'when multiple fields are specified' do
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
              Child.denormalize(:first_name, :last_name, from: :parent, as: :supername)
            }.to raise_error(ArgumentError,
                             'When option :as is used only one unique field could be specified.')
          end
        end
      end

      context 'when :belongs_to target is polymorphic' do
        context 'when option :inverses_of is not provided' do
          before :all do
            class Parent1
              include Mongoid::Document

              field :name1
              has_one :children, inverse_of: :top
            end

            class Child
              include Mongoid::Document
              include Mongoid::Denormalize

              belongs_to :top, polymorphic: true
            end
          end

          after :all do
            Object.send(:remove_const, :Parent1)
            Object.send(:remove_const, :Child)
          end

          it 'raises error' do
            expect {
              Child.denormalize(:name1, from: :top)
            }.to raise_error(ArgumentError,
                             'Option :inverses_of is needed with an Array when the relation is polymorphic.')
          end
        end

        context 'when option :as is provided' do
          before :all do
            class Parent1
              include Mongoid::Document

              field :name1
              has_one :children, inverse_of: :top
            end

            class Parent2
              include Mongoid::Document

              field :name2
              has_one :children, inverse_of: :top
            end

            class Child
              include Mongoid::Document
              include Mongoid::Denormalize

              belongs_to :top, polymorphic: true
              denormalize :name1, from: :top, inverses_of: %i[parent1], as: :top_name
              denormalize :name2, from: :top, inverses_of: %i[parent2], as: :top_name
            end
          end

          after :all do
            Object.send(:remove_const, :Parent1)
            Object.send(:remove_const, :Parent2)
            Object.send(:remove_const, :Child)
          end

          context 'when creates new document' do
            before do
              @parent = Parent1.create(name1: 'parent')
              @child = Child.create(top: @parent)
            end

            it 'has denormalized fields' do
              expect(@child.reload.top_name).to eq(@parent.name1)
            end

            it 'doesn\'t create the old from_field' do
              expect(@child.reload).not_to respond_to(:top_name1)
              expect(@child.reload).not_to respond_to(:top_name2)
            end
          end

          context 'when updates the parent document' do
            before do
              @parent = Parent1.create(name1: 'parent')
              @child = Child.create(top: @parent)
              @parent.reload.update_attributes(name1: 'new_fancy_name')
            end

            it 'has denormalized fields' do
              expect(@child.reload.top_name).to eq(@parent.name1)
            end

            it 'doesn\'t create the old from_field' do
              expect(@child.reload).not_to respond_to(:top_name1)
              expect(@child.reload).not_to respond_to(:top_name2)
            end
          end
        end

        context 'when option :inverses_of is provided' do
          context 'when fields doesn\'t exists in all the parents' do
            before :all do
              class Parent1
                include Mongoid::Document

                field :name1
                has_one :children, inverse_of: :top
              end

              class Parent2
                include Mongoid::Document

                field :name2
                has_one :children, inverse_of: :top
              end

              class Child
                include Mongoid::Document
                include Mongoid::Denormalize

                belongs_to :top, polymorphic: true
                denormalize :name2, :name1, from: :top, inverses_of: %i[parent1 parent2]
              end
            end

            after :all do
              Object.send(:remove_const, :Parent1)
              Object.send(:remove_const, :Parent2)
              Object.send(:remove_const, :Child)
            end

            context 'when creates new document' do
              it 'has denormalized fields' do
                parent = Parent1.create!(name1: 'parent')
                child = Child.create!(top: parent)

                expect(child.reload.top_name1).to eq(parent.name1)
                expect(child.reload.top_name2).to be_nil
              end
            end

            context 'when updates relation' do
              before do
                @parent = Parent1.create!(name1: 'parent')
                @child = Child.create!(top: @parent)
              end

              context 'with a document of the same type' do
                before do
                  @parent_same_type = Parent1.create(name1: 'parent')
                  @child.update_attributes(top: @parent_same_type)
                end

                it 'updates denormalized fields' do
                  expect(@child.reload.top_name1).to eq(@parent_same_type.name1)
                  expect(@child.reload.top_name2).to be_nil
                end
              end

              context 'with a document of different type' do
                before do
                  @parent_diff_type = Parent2.create(name2: 'parent')
                  @child.update_attributes(top: @parent_diff_type)
                end

                it 'updates denormalized fields' do
                  expect(@child.reload.top_name2).to eq(@parent_diff_type.name2)
                  expect(@child.reload.top_name1).to eq(@parent.name1)
                end
              end
            end

            context 'when updates the parent document' do
              before do
                @parent = Parent1.create(name1: 'parent')
                @child = Child.create(top: @parent)
                @parent.reload.update_attributes(name1: 'new_fancy_name')
              end

              it 'has denormalized fields' do
                expect(@child.reload.top_name1).to eq(@parent.name1)
                expect(@child.reload.top_name2).to be_nil
              end
            end
          end

          context 'when fields exists in all the parents' do
            before :all do
              class Parent1
                include Mongoid::Document

                field :name1
                has_one :children, inverse_of: :top
              end

              class Child
                include Mongoid::Document
                include Mongoid::Denormalize

                belongs_to :top, polymorphic: true
                denormalize :name1, from: :top, inverses_of: %i[parent1]
              end
            end

            after :all do
              Object.send(:remove_const, :Parent1)
              Object.send(:remove_const, :Child)
            end

            context 'when creates new document' do
              it 'has denormalized fields' do
                parent = Parent1.create!(name1: 'parent')
                child = Child.create!(top: parent)

                expect(child.reload.top_name1).to eq(parent.name1)
              end
            end

            context 'when updates the parent document' do
              it 'has denormalized fields' do
                parent = Parent1.create(name1: 'parent')
                child = Child.create(top: parent)
                parent.reload.update_attributes(name1: 'new_fancy_name')

                expect(child.reload.top_name1).to eq(parent.name1)
              end
            end
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

        context 'when relations is :has_one' do
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
    end
  end
end
