class Instance

  def initialize(instance)
    instance.keys.each do |key|
      var = "@#{key}"

      self.instance_variable_set(var.to_sym, instance[key])
    end
  end

  def self.call_on(action, ami)
    @ec2.call action, "InstanceId" => ami
  end

  def method_missing(sym, *args, &block)
    self.instance_variable_get "@#{sym}".to_sym
  end
end