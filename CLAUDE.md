# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FixtureFarm is a Ruby gem that automatically generates Rails fixtures while browsing your application or during test execution. It tracks ActiveRecord model creation and converts them into reusable test fixtures with proper associations.

## Development Commands

### Running Tests
```bash
# Run all tests
bin/test

# Run specific test file
bin/test test/fixture_farm_test.rb
```

### Building and Publishing
```bash
# Build the gem
bundle exec rake build

# Install locally
bundle exec rake install

# Release (requires proper credentials)
bundle exec rake release
```

### Using the CLI Tool
```bash
# Start recording fixtures with optional prefix
bundle exec fixture_farm record [fixture_name_prefix]

# Check recording status
bundle exec fixture_farm status

# Stop recording
bundle exec fixture_farm stop
```

## Architecture

### Core Components

**FixtureRecorder** (`lib/fixture_farm/fixture_recorder.rb`):
- Central class that manages fixture recording sessions
- Tracks new model instances via ActiveSupport::Notifications
- Handles fixture naming based on belongs_to associations
- Serializes fixtures to YAML format with proper ERB timestamps
- Maintains session state in `tmp/fixture_farm_store.json`

**ActiveRecordExtension** (`lib/fixture_farm/active_record_extension.rb`):
- Extends all ActiveRecord models with fixture-related methods
- Provides `fixture_name` method to find existing fixture names
- Handles fixture file path resolution including inheritance

**Hook System**:
- **Hook** (`lib/fixture_farm/hook.rb`): Base module for recording functionality
- **ControllerHook** (`lib/fixture_farm/controller_hook.rb`): Enables recording during HTTP requests
- **ActiveJobHook** (`lib/fixture_farm/active_job_hook.rb`): Enables recording during job execution
- **TestHelper** (`lib/fixture_farm/test_helper.rb`): Provides `record_new_fixtures` method for tests

### Key Design Patterns

1. **Session-based Recording**: Uses temporary JSON files to maintain recording state across requests
2. **Association-based Naming**: Fixture names are derived from parent model fixtures (e.g., `user_post_1`)
3. **Automatic Reload**: Models are reloaded after creation to capture any callbacks/updates
4. **Polymorphic Support**: Handles polymorphic associations correctly
5. **Inheritance Handling**: Supports STI models by traversing the inheritance chain

### Configuration

The gem supports one main configuration option:

```ruby
# Lower priority for certain parent models when naming fixtures
FixtureFarm.low_priority_parent_model_for_naming = ->(model) { model.is_a?(TenantModel) }
```

## Integration Points

### Rails Integration
- Automatically loads ActiveRecordExtension via `ActiveSupport.on_load(:active_record)`
- Integrates with Rails' fixture system and test directory structure
- Uses Rails.root for file paths and Rails notifications for model tracking

### Test Integration
Include `FixtureFarm::TestHelper` in your test classes to use `record_new_fixtures`:

```ruby
test 'example' do
  record_new_fixtures('prefix') do |recorder|
    # Create models here
    recorder.stop! # Optional early stop
  end
end
```

### Application Integration
Add to ApplicationController for request-based recording:
```ruby
include FixtureFarm::ControllerHook if defined?(FixtureFarm)
```

## File Structure

- `lib/fixture_farm.rb`: Main entry point with autoloads
- `lib/fixture_farm/`: Core implementation modules
- `bin/fixture_farm.rb`: CLI executable
- `test/dummy/`: Rails dummy app for testing
- `test/fixture_farm_test.rb`: Main test file

## Testing Notes

- Uses Rails' built-in test framework (not RSpec)
- Includes a dummy Rails app in `test/dummy/` for integration testing
- Default rake task runs all tests
- Tests are minimal - the gem is primarily tested through real-world usage
- No mocking
- No instance_variable_get/set
