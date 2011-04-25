require 'json'

class Definition
  FILE_PREFIX = "~/Sprout_configs/machine_definitions/"
  %x{mkdir -p #{FILE_PREFIX} } unless File.directory? FILE_PREFIX
  attr_accessor :name, :gems, :user_data, :packages, :size, :chef_cookbooks, :chef_recipes, :ami, :tags, :volumes, :volume_size, :availability_zone, :key_name, :chef_install

  def initialize
    yield self if block_given?
  end

  def load_from_file(filename)
    definition_file = File.open(FILE_PREFIX + filename, 'r')
    JSON.parse(definition_file.read).each do |element, value|
      instance_variable_set(element, value)
    end
  end

  def save_to_file(filename)
    hash_of_definition = Hash.new
    instance_variables.each do |var|
      hash_of_definition[var.to_s.gsub("@","")] = instance_variable_get(var)
    end
    File.open(FILE_PREFIX + filename, 'w') {|f| f.write(hash_of_definition.to_json) }
  end
end