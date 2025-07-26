# FixtureFarm

This gem lets you do two things:

- record fixtures as you browse.
- record fixtures for a block of code (e.g. setup part of a test).

Generated fixture that `belongs_to` a record from an existing fixture, will reference that fixture by name.

### Limitations

- doesn't update fixtures
- assumes that all serialized attributes are json (so that at least ActiveStorage::Blob metadata is correctly represented; it really should be Rails serializing attributes according to their respective coders when inserting fixtures into the database, but, alas, this isn't happening)

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

## Usage

### Record as you browse

To record as you browse in development add this to `ApplicationController`:

```ruby
include FixtureFarm::ControllerHook if defined?(FixtureFarm)
```

And in `ApplicationJob` if needed:

```ruby
include FixtureFarm::ActiveJobHook if defined?(FixtureFarm)
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
  record_new_fixtures do |recorder|
    user = User.create!(name: 'Bob')
    post = user.posts.create!(title: 'Stuff')

    recorder.stop!

    assert_difference 'user.published_posts.size' do
      post.publish!
    end
  end
end
```

Running this test generates user and post fixtures. Now you can rewrite this test to use them:

```ruby
test 'some stuff does the right thing' do
  user = users('user_1')

  assert_difference 'user.published_posts.size' do
    user.posts.first.publish!
  end
end
```

`record_new_fixtures` accepts optional name prefix, that applies to all new fixture names.

A more robust approach is to have dedicated fixture tests that normally fail, but can be optionally run in "record mode" (think VCR).

For example, let's say we have `Author` model that `has_many :posts` and we require authors to have at least one post. Here's the test to enforce `authors` fixtures to comply with this rule:

```ruby
test 'authors fixtures must have at least one post' do
  offending_records = Author.where.missing(:posts)

  assert_empty offending_records
end
```

Let's say this test is currently failing.

Now let's add the option to automatically record missing fixtures:

```ruby
test 'authors fixtures must have at least one post' do
  offending_records = Author.where.missing(:posts)

  if ENV['RECORD_FIXTURES']
    record_new_fixtures do
      offending_records.each do |author|
        author.posts.create!(text: 'some text')
      end
    end
  end

  assert_empty offending_records
end
```

Running this test with `RECORD_FIXTURES=1` will generate missing fixture entries in `test/fixtures/posts.yml`. Now re-run the test again and it's passing.

### Automatic fixture naming

Generated fixture names are based on the first `belongs_to` association of the model. E.g., if a new post fixtures belongs_to to a user fixture `bob`, the name is going to be `bob_post_1`.

It's possible to lower the priority of given parent assiciations when it comes to naming, so that certain names are only picked when there are no other suitable parent associations. This is useful, for example, to exclude `acts_as_tenant` association:

```ruby
FixtureFarm.low_priority_parent_model_for_naming = -> { _1.is_a?(TenantModel) }
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
