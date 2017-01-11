module Optionable
  extend ActiveSupport::Concern

  def find_option_value(name)
    (opt = options.find_by_name(name.to_s)) ? opt.value : nil    
  end

  def find_option_values(name)
    options.find_all_by_name(name.to_s).collect(&:value)
  end

  def options_hash
    option_hash = Hash.new {|h,k| h[k] = []}

    options.each do |option|
      option_hash[k] << option.value.to_s
    end

    option_hash
  end

  module ClassMethods
    def has_options
      has_many :options, :as => :entity, :dependent => :destroy
    end
  end
end