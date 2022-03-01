# frozen_string_literal: true

module FixtureFarm
  class FixtureRecorder
    STORE_PATH = Rails.root.join('tmp', 'fixture_farm_store.json')

    def initialize(fixture_name_prefix, new_models = [])
      @fixture_name_prefix = fixture_name_prefix
      @new_models = new_models
      @initial_now = Time.zone.now
    end

    def self.resume_recording_session
      start_recording_session! unless recording_session_in_progress?

      recording_session = JSON.load_file(STORE_PATH)

      new_models = recording_session['new_models'].map do |(class_name, id)|
        class_name.constantize.find(id)
      end

      new(recording_session['fixture_name_prefix'], new_models)
    end

    def self.start_recording_session!(fixture_name_prefix)
      File.write(STORE_PATH, {
        fixture_name_prefix: fixture_name_prefix,
        new_models: []
      }.to_json)
    end

    def self.stop_recording_session!
      FileUtils.rm_f(STORE_PATH)
    end

    def self.recording_session_in_progress?
      File.exist?(STORE_PATH)
    end

    def record_new_fixtures
      stopped = false

      subscriber = ActiveSupport::Notifications.subscribe 'sql.active_record' do |event|
        payload = event.payload

        next unless payload[:name] =~ /([:\w]+) Create/

        new_fixture_class_name = Regexp.last_match(1)

        payload[:connection].transaction_manager.current_transaction.records.reject(&:persisted?).reject(&:destroyed?).each do |model_instance|
          next if new_fixture_class_name != model_instance.class.name

          @new_models << model_instance
        end
      end

      yield lambda {
        ActiveSupport::Notifications.unsubscribe(subscriber)
        stopped = true
        reload_models
        update_fixture_files(named_new_fixtures)
      }

      unless stopped
        reload_models
        update_fixture_files(named_new_fixtures)
      end
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    def update_recording_session
      return unless FixtureRecorder.recording_session_in_progress?

      File.write(STORE_PATH, {
        fixture_name_prefix: @fixture_name_prefix,
        new_models: @new_models.map { |model| [model.class.name, model.id] }
      }.to_json)
    end

    private

    def reload_models
      @new_models = @new_models.map do |model_instance|
        # reload in case model was updated after initial create
        model_instance.reload
        # Some records are created and then later removed.
        # We don't want to turn those into fixtures
      rescue ActiveRecord::RecordNotFound
        nil
      end.compact
    end

    def named_new_fixtures
      @new_models.uniq(&:id).each_with_object({}) do |model_instance, named_new_fixtures|
        new_fixture_name = "#{@fixture_name_prefix}_#{model_instance.class.name.underscore.gsub('/', '_')}_1"

        while named_new_fixtures[new_fixture_name]
          new_fixture_name = new_fixture_name.sub(/_(\d+)$/, "_#{Regexp.last_match(1).to_i + 1}")
        end

        named_new_fixtures[new_fixture_name] = model_instance
      end
    end

    def update_fixture_files(named_new_fixtures)
      named_new_fixtures.each do |new_fixture_name, model_instance|
        attributes = model_instance.attributes

        yaml_attributes = attributes.except('id').compact.map do |k, v|
          belongs_to_association = model_instance.class.reflect_on_all_associations.filter(&:belongs_to?).find do |a|
            a.foreign_key.to_s == k
          end

          if belongs_to_association
            associated_model_instance = model_instance.public_send(belongs_to_association.name)

            associated_fixture_name = named_new_fixtures.find do |_, fixture_model|
              fixture_model.id == associated_model_instance.id
            end&.first || associated_model_instance.fixture_name

            [belongs_to_association.name.to_s, associated_fixture_name]
          else
            [k, serialize_attributes(v)]
          end
        end.to_h

        fixtures_file_path = model_instance.fixtures_file_path

        fixtures = File.exist?(fixtures_file_path) ? YAML.load_file(fixtures_file_path) : {}
        fixtures[new_fixture_name] = yaml_attributes

        FileUtils.mkdir_p(fixtures_file_path.dirname)

        File.open(fixtures_file_path, 'w') do |file|
          yaml = YAML.dump(fixtures).gsub(/\n(?=[^\s])/, "\n\n").delete_prefix("---\n\n")
          file.write(yaml)
        end
      end
    end

    def serialize_attributes(value)
      case value
      when ActiveSupport::TimeWithZone, Date
        "<%= #{datetime_erb(value)} %>"
      when ActiveSupport::Duration
        value.iso8601
      when BigDecimal
        value.to_f
      else
        value
      end
    end

    def round_time(value)
      if value.to_datetime.minute == 59
        value += 1.minute
        value = value.beginning_of_hour
      elsif value.to_datetime.minute == 1 || value.to_datetime.minute == 0
        value = value.beginning_of_hour
      end
      value
    end

    def datetime_erb(value)
      beginning_of_day = value == value.beginning_of_day

      rounded_initial_now = round_time(@initial_now)
      rounded_now = round_time(Time.zone.now)

      if value.is_a?(Date)
        rounded_initial_now = rounded_initial_now.to_date
        rounded_now = rounded_now.to_date
      elsif beginning_of_day
        rounded_initial_now = rounded_initial_now.beginning_of_day
        rounded_now = rounded_now.beginning_of_day
      end

      time_travel_diff = dt_diff(rounded_initial_now, rounded_now)

      rounded_value = time_travel_diff.inject(value) { |sum, (part, v)| sum + v.public_send(part) }
      rounded_value = round_time(rounded_value) unless value.is_a?(Date)

      parts = dt_diff(rounded_value, rounded_initial_now)

      formatted_now = if value.is_a?(Date)
                        'Date.today'
                      else
                        beginning_of_day ? 'Time.zone.now.beginning_of_day' : 'Time.zone.now'
                      end

      ([formatted_now] + parts.delete_if { |_, v| v.zero? }.map do |(part, v)|
        "#{v.positive? ? '+' : '-'} #{v.abs}.#{part.pluralize(v.abs)}"
      end).join(' ')
    end

    def dt_diff(left, right)
      units = %w[year month week day]
      units += %w[hour minute] unless left.is_a?(Date)

      units.each_with_object({ value_rest: left }) do |unit, acc|
        acc[unit] ||= 0

        if left > right
          while acc[:value_rest] - 1.public_send(unit) >= right
            acc[unit] += 1
            acc[:value_rest] -= 1.public_send(unit)
          end
        else
          while acc[:value_rest] + 1.public_send(unit) <= right
            acc[unit] -= 1
            acc[:value_rest] += 1.public_send(unit)
          end
        end
      end.except(:value_rest)
    end
  end
end
