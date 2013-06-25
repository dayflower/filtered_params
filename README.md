# FilteredParams

Strong parameters (from Rails 4) for everyone.

## Usage

Same as strong parameters in Rails 4 (and strong_parameters gem for Rails 3).

```ruby
person_params = FilteredParams.new(params).require(:person).permit(:name, :age)
person.update_attributes!(person_params)
```

This module relies on only ActiveSupport (4+).  Best conjunction with ActiveModel (and ActiveRecord) 4, but not required.

## Installation

Add this line to your application's Gemfile:

    gem 'filtered_params', :github => 'dayflower/filtered_params'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install filtered_params

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
