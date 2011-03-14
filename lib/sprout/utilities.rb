def load_config
  account = "default"
  swirl_config = "#{ENV["HOME"]}/.swirl"
  account = account.to_sym

  if File.exists?(swirl_config)
    data = YAML.load_file(swirl_config)
  else
    abort("You are required to write a proper YAML config file called .swirl file in your home directory")
  end

  if data.key?(account)
    data[account]
  else
    abort("I don't see the account you're looking for")
  end
end

def act_on_instance(action, ami)
  @ec2 ||= Swirl::AWS.new :ec2, load_config
  @ec2.call action, "InstanceId" => ami
end