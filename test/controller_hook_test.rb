require 'test_helper'

class TestHookController < ApplicationController
  before_action -> { FakeFS.activate! }

  include FixtureFarm::ControllerHook

  def create_user
    User.create!(name: 'Controller User', email: 'controller@example.com')
    render json: { success: true }
  end
end

class ControllerHookTest < ActionDispatch::IntegrationTest
  setup do
    FakeFS.deactivate!

    Rails.application.routes.draw do
      post '/test_hook/create_user', to: 'test_hook#create_user'

      post '/start_recording', to: ->(env) {
        FakeFS.activate!
        FixtureFarm::FixtureRecorder.start_recording_session!('controller_capture')

        [200, {}, ['']]
      }

      post '/stop_recording', to: ->(env) {
        FixtureFarm::FixtureRecorder.stop_recording_session!

        [200, {}, ['']]
      }
    end
  end

  teardown do
    post '/stop_recording'
    Rails.application.reload_routes!
  end

  test 'captures fixtures during request' do
    post '/start_recording'

    post '/test_hook/create_user'
    assert_response :success

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    assert fixtures.key?('controller_capture_user_1')
    assert_equal 'Controller User', fixtures['controller_capture_user_1']['name']
  end

  test 'does not capture when no recording session' do
    post '/test_hook/create_user'
    assert_response :success

    fixtures = YAML.load_file(Rails.root.join('test', 'fixtures', 'users.yml'))
    refute fixtures.key?('controller_capture_user_1')
  end

  test 'updates recording session after request' do
    skip 'TODO'
  end
end
