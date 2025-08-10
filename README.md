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
bundle exec fixture_farm record
# OR
bundle exec fixture_farm record name_prefix
# OR
bundle exec fixture_farm record name_prefix:replaces_name

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

#### Fixture Name Replacement

`record_fixtures` also supports hash arguments for advanced fixture naming control:

```ruby
# Replace 'client_1' with 'new_client' in fixture names, or use 'new_client' as prefix if not found
record_fixtures(new_client: :client_1) do
  User.create!(name: 'Test User', email: 'test@example.com')
end
```

This works in two ways:
- **Replacement**: If a generated fixture name contains `client_1`, it gets replaced with `new_client`
- **Prefixing**: If a generated fixture name doesn't contain `client_1`, it gets prefixed with `new_client_`

For example:
- A user fixture that would be named `client_1_user_1` becomes `new_client_user_1` (replacement)
- A user fixture that would be named `user_1` becomes `new_client_user_1` (prefixing)

### Automatic fixture naming

Generated fixture names are based on the first `belongs_to` association of the model. E.g., if a new post fixtures belongs_to to a user fixture `bob`, the name is going to be `bob_post_1`.

It's possible to lower the priority of given parent assiciations when it comes to naming, so that certain names are only picked when there are no other suitable parent associations. This is useful, for example, to exclude `acts_as_tenant` association:

```ruby
FixtureFarm.low_priority_parent_model_for_naming = -> { _1.is_a?(TenantModel) }
```

### Attachment fixtures

Rather than [manually crafting attachment fixtures](https://guides.rubyonrails.org/v8.0/active_storage_overview.html#adding-attachments-to-fixtures), we can get the gem to do the work. Not only is this less boring, but it's also going to generate variant fixtures.

If we then check the generated blob files into git (along with the fixture files themselves), no attachment processing will be happening in tests or after `rails db:fixtures:load`.

We'll need a special storage service for the fixture blobs we want to keep versioned. For example:

```yml
# config/storage.yml
test_fixtures:
  service: Disk
  root: <%= Rails.root.join("test/fixtures/files/active_storage_blobs") %>
```

Now a test like the one below is either going to fail if some product fixtures have no attachments, or, if run with `GENERATE_FIXTURES=1`, is going to generate those attachment fixtures, their variant fixtures if needed, along with all the blob files tucked away in a separate (from regular throw away storage) folder that can be checked in:

```ruby
if ENV["GENERATE_FIXTURES"]
  setup do
    @original_queue_adapter = ActiveJob::Base.queue_adapter
    # This is so that variants get generated and blobs analyzed
    ActiveJob::Base.queue_adapter = :inline

    @original_storage_service = ActiveStorage::Blob.service
    ActiveStorage::Blob.service = ActiveStorage::Blob.services.fetch(:test_fixtures)
  end

  teardown do
    ActiveJob::Base.queue_adapter = @original_queue_adapter
    ActiveStorage::Blob.service = @original_storage_service
  end
end

test "product fixtures have images" do
  offending_records = Product.where.missing(:images_attachments)

  if ENV["GENERATE_FIXTURES"]
    record_fixtures do |recorder|
      ActiveStorage::Attachment.where(record_type: 'Product').destroy_all

      Product.find_each do |product|
        product.images.attach(
          io: File.open(file_fixture("products/#{product.fixture_name}.jpg")),
          filename: "#{product.fixture_name}.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  else
    assert_empty offending_records.map(&:fixture_name),
      "Expected the following product fixtures to have images:"
  end
end
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
