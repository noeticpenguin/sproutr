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

def invoke_launch(config)
  response = @ec2.call "RunInstances", config
  response["instancesSet"].first["instanceId"]
end

def validate_launch_config(config, availability_zone = nil)
  instance_options = {
      "SecurityGroup.#" => config["groups"] || [],
      "MinCount" => "1",
      "MaxCount" => "1",
      "KeyName" => config["key_name"] || "Production",
      "InstanceType" => config["instance_type"] || "m1.small",
      "ImageId" => config["ami"],
      "AvailabilityZone" => availability_zone || config["placement"]["availabilityZone"]
  }

  if config["volumes"]
    devices = []
    sizes = []
    config["volumes"].each do |v|
      puts "Adding a volume of #{v["size"]} to be mounted at #{v["device"]}."
      devices << v["device"]
      sizes << v["size"].to_s
    end

    instance_options.merge! "BlockDeviceMapping.#.Ebs.VolumeSize" => sizes, "BlockDeviceMapping.#.DeviceName" => devices
  end

end

def clone_ami_config(config, new_ami)
  throw "No config provided" unless config

  instance_options = {
      "SecurityGroup.#" => config["groups"] || [],
      "MinCount" => "1",
      "MaxCount" => "1",
      "KeyName" => config["key_name"] || "Production",
      "InstanceType" => config["instance_type"] || "m1.small",
      "ImageId" => new_ami
  }

  devices = []
  sizes = []
  config["blockDeviceMapping"].each do |block_device|
    volume = @ec2.call "DescribeVolumes", "VolumeId" => block_device["ebs"]["volumeId"]
    next if volume["volumeSet"][0]["attachmentSet"][0]["device"] == "/dev/sda1"
    say "Adding volume #{volume["volumeSet"][0]["attachmentSet"][0]["device"]} with a size of #{volume["volumeSet"][0]["size"]}", :green
    devices << volume["volumeSet"][0]["attachmentSet"][0]["device"]
    sizes << volume["volumeSet"][0]["size"]
  end

  instance_options.merge! "BlockDeviceMapping.#.Ebs.VolumeSize" => sizes, "BlockDeviceMapping.#.DeviceName" => devices

end

def ami_done?(ami)
  ami_list = @ec2.call "DescribeImages", "Owner" => "self"
  images = ami_list["imagesSet"].select { |img| img["name"] } rescue nil
  images = images.map { |image| image["imageId"] if image["imageState"] == "available" }
  (images.include? ami) ? true : false
end

def parse_tags(tags)
  if tags && !tags.empty?
    if tags.is_a? Hash
      {"Tag.#.Key" => tags.keys.map(&:to_s),
       "Tag.#.Value" => tags.values.map(&:to_s)}
    elsif tags.is_a? Array
      {
          "Tag.#.Key" => tags.map(&:to_s),
          "Tag.#.Value" => (1..tags.size).map { '' }
      }
    else
      {"Tag.1.Key" => tags.to_s, "Tag.1.Value" => ''}
    end
  end
end

def tag_instance(instance_id, tags)
  instance_id = [instance_id] unless instance_id.is_a? Array
  @ec2.call("CreateTags", parse_tags(tags).merge("ResourceId" => instance_id))
end

def demand(question)
  answer = nil
  while answer.nil? or answer.strip == ""
    answer = ask question, :green
  end
  answer
end