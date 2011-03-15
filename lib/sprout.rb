#!/usr/bin/env ruby
$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'swirl/aws'
require 'json'
require 'thor'
require 'ap'
require 'terminal-table/import'
require 'sprout/utilities'
require 'sprout/instance'
require 'sprout/ami'

class Sprout < Thor
  include Thor::Actions
  map "-l" => :list

  def initialize(*args)
    super
    @ec2 ||= Swirl::AWS.new :ec2, load_config
  end

  desc "list_instances", "list all the instances in your ec2 account"

  def list_instances
    aws_instances = @ec2.call "DescribeInstances"
    @instances = Array.new
    aws_instances["reservationSet"].each { |reservation| @instances << Instance.new(reservation["instancesSet"][0]) }
    instance_table = table do |i|
      i.headings = 'Name', 'Instance Id', 'Status', 'ip Address', 'Instance Type', 'AMI Image', 'Availablity Zone', 'DNS Cname'
      @instances.each do |instance|
        i << [((instance.tagSet.nil?) ? "Name Not Set" : instance.tagSet[0]["value"]),
              instance.instanceId, instance.instanceState["name"], instance.ipAddress,
              instance.instanceType, instance.imageId, instance.placement["availabilityZone"], instance.dnsName]
      end
    end
    puts instance_table
  end

  desc "list_amis", "list all the ami's in your ec2 account"

  def list_amis
    ami_list = @ec2.call "DescribeImages", "Owner" => "self"
    images = ami_list["imagesSet"].select { |img| img["name"] } rescue nil
    @ami_images = Array.new
    images.each { |image| @ami_images << Ami.new(image) }
    ami_table = table do |a|
      a.headings = 'Name', 'AMI Id', 'Type', 'State', 'Size', 'Architecture', 'Public?', 'Description'
      @ami_images.each do |ami|
        a << [ami.name, ami.imageId, ami.rootDeviceType, ami.imageState, ami.blockDeviceMapping[0]["ebs"]["volumeSize"],
              ami.architecture, ami.isPublic, ami.description]
      end
    end
    puts ami_table
  end
  desc "list", "list all the instances and ami's in your ec2 account"

  def list
    list_instances()
    list_amis()
  end

  desc "start", "Start the specified instance(s), requires --ami="
  method_option :ami, :type => :array, :required => true

  def start
    options[:ami].each { |ami| act_on_instance("StartInstances", ami) }
  end

  desc "stop", "Stop the specified instance(s), requires --ami="
  method_option :ami, :type => :array, :required => true

  def stop
    options[:ami].each { |ami| act_on_instance("StopInstances", ami) }
  end

  desc "restart", "Restart the specified instance(s), requires --ami="
  method_option :ami, :type => :array, :required => true

  def restart
    options[:ami].each { |ami| act_on_instance("RebootInstances", ami) }
  end

  desc "terminate", "Terminate the specified instance, requires --ami="
  method_option :ami, :type => :array, :required => true

  def terminate
    options[:ami].each do |ami|
      verify = ask "Do you really want to terminate the #{ami} instance? ", :red
      act_on_instance("TerminateInstances", ami) if verify.downcase == "y" || verify.downcase == "yes"
    end
  end

  desc "destroy", "Alias to terminate"
  method_option :ami, :type => :array, :required => true
  alias :destroy :terminate

  desc "describe", "Describe a specific instance"
  method_option :ami, :type => :array, :required => true

  def describe
    options[:ami].each do |ami|
      say @ec2.call("DescribeInstances", "InstanceId" => ami)["reservationSet"][0]["instancesSet"][0].to_yaml, :blue
    end
  end

  desc "snapshot", "Create snapshot"
  method_option :ami, :type => :array, :required => true
  method_options :desc => "Snapshot created by Sprout"

  def snapshot
    options[:ami].each do |ami|
      instance_volumes = @ec2.call("DescribeInstances", "InstanceId" => ami)["reservationSet"][0]["instancesSet"][0]["blockDeviceMapping"]
      instance_volumes.each { |volume| ap @ec2.call("CreateSnapshot", "VolumeId" => volume["ebs"]["volumeId"], "Description" => options[:desc]) }
    end
  end

  desc "list_snapshots", "lists all the snapshots available and their status"

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

  desc "delete_snapshot", "deletes the given snapshot(s) use --snapshot="
  method_option :snapshot, :type => :array, :required => true

  def delete_snapshot
    options[:snapshot].each do |snapshot_id|
      result = @ec2.call "DeleteSnapshot", "SnapshotId" => snapshot_id
      say result["return"], :green
    end
  end

  desc "debug", "debug info"

  def debug
#    @ec2 ||= Swirl::AWS.new :ec2, load_config
    snapshots = @ec2.call "DescribeSnapshots", "Owner" => "self"
    ap snapshots
#    images = ami_list["imagesSet"].select { |img| img["name"] } rescue nil
#    @ami_images = Array.new
#    images.each { |image| @ami_images << Ami.new(image) }
#    @ami_images.each do |ami|
#      ap ami.blockDeviceMapping[0]["ebs"]
#    end
#    puts ami_table
  end
end
Sprout.start