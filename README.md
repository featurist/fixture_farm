# FixtureFarm

This gem lets you do two things:

- record fixtures as you browse.
- record fixtures for a block of code (e.g. setup part of a test).

Generated fixture that `belongs_to` a record from an existing fixture, will reference that fixture by name.

## Usage

### Record as you browse

To record as you browse in development add this to `ApplicationController`:

```ruby
include FixtureFarm::ControllerHook if Rails.env.development?
```

Then start/stop recording using tasks:

```bash
bundle exec fixture_farm record some_awesome_name_prefix
bundle exec fixture_farm status
bundle exec fixture_farm stop
```

### Record in tests

To record in tests, wrap some code in `record_new_fixtures` block. For example:

```ruby

include FixtureFarm::TestHelper

test 'some stuff does the right thing' do
  record_new_fixtures('some_stuff') do |stop_recording|
    user = User.create!(name: 'Bob')
    post = user.posts.create!(title: 'Stuff')

    stop_recording.call

    assert_difference 'user.published_posts.size' do
      post.publish!
    end
  end
end
```

Running this test generates user and post fixtures. Now you can rewrite this test to use them:

```ruby
test 'some stuff does the right thing' do
  user = users('some_stuff_user_1')

  assert_difference 'user.published_posts.size' do
    user.posts.first.publish!
  end
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'fixture_farm', group: %i[development test]
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install fixture_farm
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
