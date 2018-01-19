# Mongoid::Denormalize
![Build Status](https://travis-ci.org/rjurado01/mongoid-denormalize.svg?branch=master)

Helper module for denormalizing association attributes in Mongoid models

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mongoid-denormalize'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid-denormalize

## Usage

In your model:

```ruby
# Include the helper method
include Mongoid::Denormalize

# Define your denormalized fields
denormalize :name, :email, from: :user
```

You need to add `inverse_of` to `belongs_to` side if relation name is diferent from model:

```ruby
class Club
  ...
  has_many :members, class_name: 'User'
end

class User
  ...
  belogns_to club, inverse_of: :members

  denormalize :name, from: :club
end
```

### Options of denormalize

#### inverses\_of: for polymorphic relations

In case where the relation is polymorphic you must add `inverses_of` with the name of the possible clasess of the other side of the relation as:

```ruby
class Club
  ...
  has_many :members
end

class User
  ...
  belogns_to club, inverse_of: :members, polymorphic: true

  denormalize :name, from: :club, inverses_of: %i[club]
end
```

#### as: enables to customize the final field name

Only one unique field could be passed as argument, like this:

```ruby
  denormalize :name, from: :top, as: :supername
```

It will create a `supername` field with the content of `top.name`.

#### prefix: enables to customize the prefix of the final name

In somes cases it could be interesting to customize the prefix of the final name, instead of using the basic `from_field`

```ruby
  denormalize :color, :name, from: :top, prefix: :ancestor
```

It will create the fields `ancestor_name` and `ancestor_color` with the content of `top.name` and `top.color`.

## Example

```ruby
class User
  include Mongoid::Document

  field :name

  has_many :books
end

class Book
  include Mongoid::Document
  include Mongoid::Denormalize

  field :title

  belongs_to :author

  denormalize :name, from: :author
end

>> user = User.create(name: 'User1')
>> book = Book.create(title: 'Title', author: user)
>> book.author_name
"User1"

>> user.update_attributes(name: 'User1.1')
>> book.reload.author_name
"User1.1"

>> new_user = User.create(name: 'User2')
>> book.update_attributes(author: new_user)
>> book.reload.author_name
"User2"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rjurado01/mongoid-denormalize.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
