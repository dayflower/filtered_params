require 'logger'
require 'date'
require 'bigdecimal'
require 'stringio'
require 'rack/test/uploaded_file'

require 'active_support/concern'
require 'active_support/hash_with_indifferent_access'
require 'active_support/notifications'
require 'active_support/log_subscriber'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/class/attribute_accessors'

class FilteredParams < ActiveSupport::HashWithIndifferentAccess
  VERSION = '0.0.1'

  class ParameterMissing < IndexError
    attr_reader :param

    def initialize(param)
      @param = param
      super("key not found: #{param}")
    end
  end

  class UnpermittedParameters < IndexError
    attr_reader :params

    def initialize(params)
      @params = params
      super("found unpermitted parameters: #{params.join(", ")}")
    end
  end

  attr_accessor :permitted
  alias :permitted? :permitted

  cattr_accessor :action_on_unpermitted_parameters, :instance_accessor => false

  # Never raise an UnpermittedParameters exception because of these params
  # are present. They are added by Rails and it's of no concern.
  NEVER_UNPERMITTED_PARAMS = %w( controller action )

  def initialize(attributes = nil)
    super(attributes)
    @permitted = false
  end

  def permit!
    each_pair do |key, value|
      convert_hashes_to_parameters(key, value)
      self[key].permit! if self[key].respond_to? :permit!
    end

    @permitted = true
    self
  end

  def require(key)
    self[key].presence || raise(ParameterMissing.new(key))
  end

  alias :required :require

  def permit(*filters)
    params = self.class.new

    filters.each do |filter|
      case filter
      when Symbol, String
        permitted_scalar_filter(params, filter)
      when Hash then
        hash_filter(params, filter)
      end
    end

    unpermitted_parameters!(params) if self.class.action_on_unpermitted_parameters

    params.permit!
  end

  def [](key)
    convert_hashes_to_parameters(key, super)
  end

  def fetch(key, *args)
    convert_hashes_to_parameters(key, super)
  rescue KeyError, IndexError
    raise ParameterMissing.new(key)
  end

  def slice(*keys)
    self.class.new(super).tap do |new_instance|
      new_instance.instance_variable_set :@permitted, @permitted
    end
  end

  def dup
    self.class.new(self).tap do |duplicate|
      duplicate.default = default
      duplicate.instance_variable_set :@permitted, @permitted
    end
  end

  private

  def convert_hashes_to_parameters(key, value)
    if value.is_a?(self.class) || !value.is_a?(Hash)
      value
    else
      # Convert to Parameters on first access
      self[key] = self.class.new(value)
    end
  end

  #
  # --- Filtering ----------------------------------------------------------
  #

  # This is a white list of permitted scalar types that includes the ones
  # supported in XML and JSON requests.
  #
  # This list is in particular used to filter ordinary requests, String goes
  # as first element to quickly short-circuit the common case.
  #
  # If you modify this collection please update the README.
  PERMITTED_SCALAR_TYPES = [
    String,
    Symbol,
    NilClass,
    Numeric,
    TrueClass,
    FalseClass,
    Date,
    Time,
    # DateTimes are Dates, we document the type but avoid the redundant check.
    StringIO,
    IO,
#   Rack::Test::UploadedFile,
#   ActionDispatch::Http::UploadedFile,
  ]

  def permitted_scalar_types
    unless defined?(@@permitted_scalar_types)
      @@permitted_scalar_types = PERMITTED_SCALAR_TYPES

      if defined?(Rack::Test::UploadedFile)
        @@permitted_scalar_types << Rack::Test::UploadedFile
      end
      if defined?(ActionDispatch::Http::UploadedFile)
        @@permitted_scalar_types << ActionDispatch::Http::UploadedFile
      end
    end

    @@permitted_scalar_types
  end

  def permitted_scalar?(value)
    permitted_scalar_types.any? {|type| value.is_a?(type)}
  end

  def array_of_permitted_scalars?(value)
    if value.is_a?(Array)
      value.all? {|element| permitted_scalar?(element)}
    end
  end

  def permitted_scalar_filter(params, key)
    if has_key?(key) && permitted_scalar?(self[key])
      params[key] = self[key]
    end

    keys.grep(/\A#{Regexp.escape(key.to_s)}\(\d+[if]?\)\z/).each do |key|
      if permitted_scalar?(self[key])
        params[key] = self[key]
      end
    end
  end

  def array_of_permitted_scalars_filter(params, key, hash = self)
    if hash.has_key?(key) && array_of_permitted_scalars?(hash[key])
      params[key] = hash[key]
    end
  end

  def hash_filter(params, filter)
    filter = filter.with_indifferent_access

    # Slicing filters out non-declared keys.
    slice(*filter.keys).each do |key, value|
      return unless value

      if filter[key] == []
        # Declaration {:comment_ids => []}.
        array_of_permitted_scalars_filter(params, key)
      else
        # Declaration {:user => :name} or {:user => [:name, :age, {:adress => ...}]}.
        params[key] = each_element(value) do |element, index|
          if element.is_a?(Hash)
            element = self.class.new(element) unless element.respond_to?(:permit)
            element.permit(*Array.wrap(filter[key]))
          elsif filter[key].is_a?(Hash) && filter[key][index] == []
            array_of_permitted_scalars_filter(params, index, value)
          end
        end
      end
    end
  end

  def each_element(value)
    if value.is_a?(Array)
      value.map { |el| yield el }.compact
      # fields_for on an array of records uses numeric hash keys.
    elsif value.is_a?(Hash) && value.keys.all? { |k| k =~ /\A-?\d+\z/ }
      hash = value.class.new
      value.each { |k,v| hash[k] = yield(v, k) }
      hash
    else
      yield value
    end
  end

  def unpermitted_parameters!(params)
    return unless self.class.action_on_unpermitted_parameters

    unpermitted_keys = unpermitted_keys(params)

    if unpermitted_keys.any?
      case self.class.action_on_unpermitted_parameters
      when :log
        name = "unpermitted_parameters.filtered_params"
        ActiveSupport::Notifications.instrument(name, :keys => unpermitted_keys)
      when :raise
        raise UnpermittedParameters.new(unpermitted_keys)
      end
    end
  end

  def unpermitted_keys(params)
    self.keys - params.keys - NEVER_UNPERMITTED_PARAMS
  end

  class FilteredParams::LogSubscriber < ActiveSupport::LogSubscriber
    def unpermitted_parameters(event)
      unpermitted_keys = event.payload[:keys]
      debug("Unpermitted parameters: #{unpermitted_keys.join(", ")}")
    end

    def logger
      self.class.logger
    end

    class << self
      def logger
        g = super
        if ! g
          @logger ||= Logger.new(STDERR)
          g = @logger
        end
        g
      end
    end
  end
end

FilteredParams::LogSubscriber.attach_to :filtered_params
