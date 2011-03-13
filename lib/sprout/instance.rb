class Instance

  def initialize(instance)
#    ap instance.keys.each {|x| ap x}
    instance.keys.each do |key|
      var = "@#{key}"

      self.instance_variable_set(var.to_sym, instance[key])
    end
  end

  def method_missing(sym, *args, &block)
    self.instance_variable_get "@#{sym}".to_sym
  end
end