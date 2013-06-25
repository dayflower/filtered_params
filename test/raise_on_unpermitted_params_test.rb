require 'test_helper'

class RaiseOnUnpermittedParamsTest < ActiveSupport::TestCase
  def setup
    FilteredParams.action_on_unpermitted_parameters = :raise
  end

  def teardown
    FilteredParams.action_on_unpermitted_parameters = false
  end

  test "raises on unexpected params" do
    params = FilteredParams.new({
      :book => { :pages => 65 },
      :fishing => "Turnips"
    })

    assert_raises(FilteredParams::UnpermittedParameters) do
      params.permit(:book => [:pages])
    end
  end

  test "raises on unexpected nested params" do
    params = FilteredParams.new({
      :book => { :pages => 65, :title => "Green Cats and where to find then." }
    })

    assert_raises(FilteredParams::UnpermittedParameters) do
      params.permit(:book => [:pages])
    end
  end
end
