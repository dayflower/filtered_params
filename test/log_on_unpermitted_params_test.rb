require 'test_helper'
require 'logger'
require 'stringio'

class LogOnUnpermittedParamsTest < ActiveSupport::TestCase
  def setup
    FilteredParams.action_on_unpermitted_parameters = :log
  end

  def teardown
    FilteredParams.action_on_unpermitted_parameters = false
  end

  test "logs on unexpected params" do
    params = FilteredParams.new({
      :book => { :pages => 65 },
      :fishing => "Turnips"
    })

    assert_logged("Unpermitted parameters: fishing") do
      params.permit(:book => [:pages])
    end
  end

  test "logs on unexpected nested params" do
    params = FilteredParams.new({
      :book => { :pages => 65, :title => "Green Cats and where to find then." }
    })

    assert_logged("Unpermitted parameters: title") do
      params.permit(:book => [:pages])
    end
  end

  private

  def assert_logged(message)
    old_logger = FilteredParams::LogSubscriber.logger
    log = StringIO.new
    FilteredParams::LogSubscriber.logger = Logger.new(log)

    begin
      yield

      log.rewind
      assert_match message, log.read
    ensure
      FilteredParams::LogSubscriber.logger = old_logger
    end
  end
end
