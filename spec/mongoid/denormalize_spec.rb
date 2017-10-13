require 'spec_helper'

RSpec.describe Mongoid::Denormalize do
  it 'has a version number' do
    expect(Mongoid::Denormalize::VERSION).not_to be nil
  end

  describe '.denormalize' do
    it 'does something useful' do
      class User
        include Mongoid::Document
        include Mongoid::Denormalize

        field :name

        has_many :publications, class_name: 'Post'
      end

      class Category
        include Mongoid::Document
        include Mongoid::Denormalize

        field :name

        has_many :posts
      end

      class Post
        include Mongoid::Document
        include Mongoid::Denormalize

        field :title
        field :body

        belongs_to :user, inverse_of: :publications
        belongs_to :category

        denormalize :name, from: :user
        denormalize :name, from: :category
      end

      user = User.create!(name: 'James')
      category = Category.create!(name: 'Action')
      post = user.publications.create!(title: 'Title 1', body: 'Body 1', category: category)

      expect(post.user_name).to eq(user.name)
      expect(post.category_name).to eq(category.name)
    end
  end
end
