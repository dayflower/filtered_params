require 'test_helper'

class ParametersRequireTest < ActiveSupport::TestCase
  test "required parameters must be present not merely not nil" do
    assert_raises(FilteredParams::ParameterMissing) do
      FilteredParams.new(:person => {}).require(:person)
    end
  end
end
