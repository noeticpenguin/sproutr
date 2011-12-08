#!/usr/bin/env ruby
$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'swirl/aws'
require 'json'
require 'thor'
require 'ap'
require 'terminal-table/import'
require 'sproutr/utilities'
require 'sproutr/instance'
require 'sproutr/cloud'
require 'sproutr/ami'
require 'sproutr/definition'

class Sproutr < Thor
  include Thor::Actions
  map "-l" => :list

  def initialize(*args)
    super
    @ec2 ||= Swirl::AWS.new :ec2, load_config
  end

  desc "clone", "Clone N number of running instance"
  method_option :instance, :type => :array, :required => true
  method_option :ami, :type => :string
  method_option :start, :type => :boolean
  method_option :tags, :type => :hash

  def clone
    options[:instance].each do |ami_to_clone|
      if options[:ami] then
        ami_id = options[:ami]
      else
        ami_id = @ec2.call("CreateImage", "InstanceId" => ami_to_clone, "Name" => "AMI-#{ami_to_clone}-#{Time.now.to_i}",
                           "Description" => "AMI created from #{ami_to_clone} at #{Time.now}", "NoReboot" => "true")["imageId"]
      end
      new_config = clone_ami_config(@ec2.call("DescribeInstances", "InstanceId" => ami_to_clone)["reservationSet"][0]["instancesSet"][0], ami_id)
      until ami_done?(ami_id) do
        say "Ami creation has not completed so this clone can not yet be started. Sleeping 30 seconds", :red
        sleep 30
      end
      new_instance = invoke_launch(new_config)
      say "Created and started #{new_instance}", :green
      tag_instance(new_instance, options[:tags]) if options[:tags]
    end
  end

  desc "create_ami", "Create an EBS Ami from a running or stopped instance"
  method_option :ami, :type => :string, :required => true
  method_option :name, :type => :string, :required => true
  method_option :desc, :type => :string, :required => true

  def create_ami
    @ec2.call "CreateImage", "InstanceId" => options[:ami], "Name" => options[:name], "Description" => options[:desc], "NoReboot" => "true"
  end

  desc "define", "define a new instance"

  def define
    definition = Definition.new do |d|
      d.name = demand "What do you want to call this definition (Required): "
      d.size = demand "What size instance do you want (Required): "
      d.ami = demand "What base AMI image would you like to use (Required): "
      ami_info = Cloud.new.describe_image(d.ami)
      break unless yes? "Is this the Image -- #{ami_info["imagesSet"][0]["name"]} -- you wish to build from?", :red
      d.packages = ask "What additional packages do you want installed (Optional): ", :green
      d.gems = ask "What gems do you want to install on this machine by default (Optional): ", :green
      d.chef_cookbooks = ask "Please name the chef cookbooks you wish to automatically download (Optional): ", :green
      d.chef_recipes = ask "Enter the recipes you wish chef to run after cookbooks are installed (Optional): ", :green
      d.user_data = demand "Please copy/paste your Userdata.sh here now. Note, sproutr will automatically add in the
requisite code to download and install Cheff cookbooks, and aggregate additional volumes
into a singluar raid array (Required): "
      d.tags = ask "Please enter the tags you'd like in name:value format (Optional, Note that the Name will automatically be specified): ", :green
      d.volumes = ask "Please enter the number of additional volumes (Optional, Note that these additional volumes will be RAID/LVM enabled as 1 *logical* volume): ", :green
      d.volume_size = ask "Please enter the size of each component volume in Gigabytes (Optional, Currently all volumes are identical in size): ", :green
      d.availability_zone = demand "Please enter the availability zone you wish to instantiate this machine in: "
      d.key_name = demand "Which key-pair would you like to use? use the key name: "
    end
    definition.save_to_file(definition.name+"_definition.json")
  end

  desc "delete_snapshot", "Deletes the given snapshot(s) use --snapshot="
  method_option :snapshot, :type => :array, :required => true

  def delete_snapshot
    options[:snapshot].each do |snapshot_id|
      result = @ec2.call "DeleteSnapshot", "SnapshotId" => snapshot_id
      say result["return"], :green
    end
  end

  desc "describe", "Describe a specific instance"
  method_option :ami, :type => :array, :required => true

  def describe
    options[:ami].each do |ami|
      ap @ec2.call("DescribeInstances", "InstanceId" => ami)["reservationSet"][0]["instancesSet"][0]
    end
  end

  desc "grow", "Grow a machine's 'hardware' resources"
  method_option :ami, :type => :array, :required => true
  method_option :size, :type => :string, :required => true

  def grow
    options[:ami].each do |ami|
      Instance::call_on(@ec2, "StopInstances", ami)
      @ec2.call "ModifyInstanceAttribute", "InstanceId" => ami, "InstanceType" => options[:size]
      Instance::call_on(@ec2, "StartInstances", ami)
    end
  end

  desc "launch", "launch an instance from the specified config directory"
  method_option :config_file, :type => :string, :required => true

  def launch
    config = JSON.parse(File.new(options[:config_file]).read) if File.exists? options[:config_file]
    throw "Failed to read config file, or config file does not specify an ImageId" unless config["ami"]
    say invoke_launch(validate_launch_config(config)), :blue
  end

  desc "list", "list all the instances and ami's in your ec2 account"

  def list
    invoke :list_instances
    invoke :list_amis
  end

  desc "list_amis", "list all the ami's in your ec2 account"

  def list_amis
    @ami_images = Cloud.new.get_images
    ami_table = table do |a|
      a.headings = 'Name', 'AMI Id', 'Type', 'State', 'Size', 'Architecture', 'Public?', 'Description'
      @ami_images.each do |ami|
        begin
          ami_size = ami.blockDeviceMapping.first["ebs"]["volumeSize"]
        rescue
          ami_size = "unknown"
        end
        a << [ami.name, ami.imageId, ami.rootDeviceType, ami.imageState, ami_size,
              ami.architecture, ami.isPublic, ami.description]
      end
    end
    puts ami_table
  end

  desc "list_instances", "list all the instances in your ec2 account"

  def list_instances
    instances = Cloud.new.get_instances
    instance_table = table do |i|
      i.headings = 'Name', 'Instance Id', 'Status', 'ip Address', 'Instance Type', 'AMI Image', 'Availablity Zone', 'DNS Cname'
      instances.each do |instance|
        p instance.inspect
        i << [((instance.tagSet.nil?) ? "Name Not Set" : instance.tagSet[0]["value"]),
              instance.instanceId, instance.instanceState["name"], instance.ipAddress,
              instance.instanceType, instance.imageId, instance.placement["availabilityZone"], instance.dnsName]
      end
    end
    puts instance_table
  end

  desc "list_snapshots", "Lists all the snapshots available and their status"

  def list_snapshots
    snapshots = @ec2.call("DescribeSnapshots", "Owner" => "self")["snapshotSet"]
    snapshots_table = table do |s|
      s.headings = snapshots.first.keys
      snapshots.each do |snap|
        s << snap.values
      end
    end
    puts snapshots_table
  end

  desc "migrate", "Migrate from one Availability Zone to another, requires --ami= [multiple apis supported separated by space] and --target="
  method_option :ami, :type => :array, :require => true
  method_option :target, :type => :string, :require => true

  def migrate
    ami_id = @ec2.call("CreateImage", "InstanceId" => ami_to_clone, "Name" => "AMI-#{options["ami"]}-#{Time.now.to_i}",
                       "Description" => "AMI created from #{options["ami"]} at #{Time.now}", "NoReboot" => "true")["imageId"]

    current_config = @ec2.call("DescribeInstances", "InstanceId" => options["ami"])["reservationSet"][0]["instancesSet"][0]
    new_config = clone_ami_config(current_config, ami_id)

    until ami_done?(ami_id) do
      say "Ami creation has not completed so the new instance can not yet be started. Sleeping 30 seconds", :red
      sleep 30
    end
    new_instance = invoke_launch(validate_launch_config(new_config, options[:target]))
    say "Created and started #{new_instance}", :green
    tag_instance(new_instance, options[:tags]) if options[:tags]
  end

  desc "restart", "Restart the specified instance(s), requires --ami="
  method_option :ami, :type => :array, :required => true

  def restart
    options[:ami].each { |ami| Instance::call_on(@ec2, "RebootInstances", ami) }
  end

  desc "snapshot", "Create snapshot"
  method_option :ami, :type => :array, :required => true
  method_options :desc => "Snapshot created by sproutr"

  def snapshot
    options[:ami].each do |ami|
      instance_volumes = @ec2.call("DescribeInstances", "InstanceId" => ami)["reservationSet"][0]["instancesSet"][0]["blockDeviceMapping"]
      instance_volumes.each { |volume| ap @ec2.call("CreateSnapshot", "VolumeId" => volume["ebs"]["volumeId"], "Description" => options[:desc]) }
    end
  end


  desc "start", "Start the specified instance(s), requires --ami="
  method_option :ami, :type => :array, :required => true

  def start
    options[:ami].each { |ami| Instance::call_on(@ec2, "StartInstances", ami) }
  end

  desc "stop", "Stop the specified instance(s), requires --ami="
  method_option :ami, :type => :array, :required => true

  def stop
    options[:ami].each { |ami| Instance::call_on(@ec2, "StopInstances", ami) if yes? "Do you really want to stop the #{ami} instance? ", :red }
  end


  desc "terminate", "Terminate the specified instance, requires --ami="
  method_option :ami, :type => :array, :required => true

  def terminate
    options[:ami].each do |ami|
      verify = ask "Do you really want to terminate the #{ami} instance? ", :red
      Instance::call_on(@ec2, "TerminateInstances", ami) if verify.downcase == "y" || verify.downcase == "yes"
    end
  end

  desc "destroy", "Alias to terminate"
  method_option :ami, :type => :array, :required => true
  alias :destroy :terminate

  desc "shrink", "Alias to grow"
  method_option :ami, :type => :array, :required => true
  method_option :size, :type => :string, :require => true
  alias :shrink :terminate

  desc "list_snapshots", "Alias to list_snapshots"
  alias :list_snapshot :list_snapshots

end
Sproutr.start