# frozen_string_literal: true

class UserSettings::Namespace
  attr_reader :name, :definitions

  def initialize(name)
    @name        = name.to_sym
    @definitions = {}
  end

  def configure(&block)
    instance_eval(&block)
    self
  end

  def setting(key, options = {})
    UserSettings::Setting.new(key, options.merge(namespace: name)).tap do |s|
      @definitions[s.key] = s
    end
  end

  def setting_inverse_alias(key, original_key)
    @definitions[key] = @definitions[original_key].inverse_of(key)
  end
end
