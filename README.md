# FixtureFarm

This gem lets you do two things:
- record fixtures for a block of code (e.g. part of a test).
- record fixtures as you browse.

A few things to note:
- generated fixture names are based on their `belongs_to` fixture names.
- generated fixture that `belongs_to` a record from an existing fixture, will reference that fixture by name.
- models, destroyed during recording, will be removed from fixtures (if they were originally there).
- generated `ActiveStorage::Blob` fixtures file names, will be the same as fixture names (so they can be generated multiple times, without generating new file each time).
- AR models gain `#fixture_name` method

### Limitations

- doesn't update fixtures
- assumes that all serialized attributes are json (so that at least ActiveStorage::Blob metadata is correctly represented; it really should be Rails serializing attributes according to their respective coders when inserting fixtures into the database, but, alas, this isn't how it works)

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

To record in tests, wrap some code in `record_fixtures` block. For example:

```ruby

include FixtureFarm::TestHelper

test 'parents fixtures have children' do
  offending_records = Parent.where.missing(:children)

  if ENV['GENERATE_FIXTURES']
    record_fixtures do
      offending_records.each do |parent|
        parent.children.create!(name: 'Bob')
      end
    end
  else
    assert_empty offending_records.map(&:fixture_name),
      "The following parents don't have children:"
  end
end
```

Assuming there was a parent fixture `dave` that didn't have any children, this test will fail. Now, running the same test with `GENERATE_FIXTURES=1` will generate one child fixture named `dave_child_1`. The test is now passing.

`record_fixtures` accepts optional name prefix, that applies to all new fixture names.

### Automatic fixture naming

Generated fixture names are based on the first `belongs_to` association of the model. E.g., if a new post fixtures belongs_to to a user fixture `bob`, the name is going to be `bob_post_1`.

It's possible to lower the priority of given parent assiciations when it comes to naming, so that certain names are only picked when there are no other suitable parent associations. This is useful, for example, to exclude `acts_as_tenant` association:

```ruby
FixtureFarm.low_priority_parent_model_for_naming = -> { _1.is_a?(TenantModel) }
```

### Attachment fixtures

Rather than [manually crafting attachment fixtures](https://guides.rubyonrails.org/v8.0/active_storage_overview.html#adding-attachments-to-fixtures), we can get the gem do the leg work. Not only is this less boring, but it's also going to generate variant fixtures.

I'd also go as far as suggesting that attachment files for generated blobs should be checked into git just as the fixtures themselves are. To share them with the development environment (e.g. `rails db:fixtures:load`), let's store test attachment files in the same `./storage` directory used in development:

```ruby
# config/environments/test.rb
config.active_storage.service = :local
```

Now this test will not only generate attachments and variant fixtures, but also `git add` new attachment files. The old removed ones will show up in `git status`.

```ruby
test "product fixtures have images" do
  offending_records = Product.where.missing(:images_attachments)

  if ENV["GENERATE_FIXTURES"]
    # Makes generation idempotent
    `git restore --staged storage`

    record_fixtures do |recorder|
      ActiveStorage::Attachment.where(record_type: 'Product').destroy_all

      Product.find_each do |product|
        product.images.attach(
          io: File.open(file_fixture("products/#{product.fixture_name}.jpg")),
          filename: "#{product.fixture_name}.jpg",
          content_type: "image/jpeg"
        )
        # This generates variants
        perform_enqueued_jobs
      end

      recorder.stop!

      `git add -f #{recorder.new_blob_file_paths.join(' ')}`
    end
  else
    assert_empty offending_records.map(&:fixture_name),
      "Expected the following product fixtures to have images:"
  end
end
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
