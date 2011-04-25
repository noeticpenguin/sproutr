class Ami
  def initialize(ami)
    ami.keys.each do |key|
      var = "@#{key}"
      self.instance_variable_set(var.to_sym, ami[key])
    end
  end

  def method_missing(sym, *args, &block)
    self.instance_variable_get "@#{sym}".to_sym
  end
end