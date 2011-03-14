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

  desc "list", "list all the instances in your ec2 account"

  def list
    @ec2 ||= Swirl::AWS.new :ec2, load_config
    aws_instances = @ec2.call("DescribeInstances")
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

  desc "start", "Start the specified instance, requires --ami="
  method_option :ami, :type => :string, :required => true

  def start
    act_on_instance("StartInstances", options[:ami])
  end

  desc "stop", "Stop the specified instance, requires --ami="
  method_option :ami, :type => :string, :required => true

  def stop
    act_on_instance("StopInstances", options[:ami])
  end

  desc "restart", "Restart the specified instance, requires --ami="
  method_option :ami, :type => :string, :required => true

  def restart
    act_on_instance("RebootInstances", options[:ami])
  end

  desc "terminate", "Terminate the specified instance, requires --ami="
  method_option :ami, :type => :string, :required => true

  def terminate
    verify = ask "Do you really want to terminate this instance? ", :red
    act_on_instance("TerminateInstances", options[:ami]) if verify.downcase == "y" || verify.downcase == "yes"
  end

  desc "describe", "Describe a specific instance"
  method_option :ami, :type => :string, :required => true

  def describe
    @ec2 ||= Swirl::AWS.new :ec2, load_config
    ap @ec2.call("DescribeInstances", "InstanceId" => options[:ami])["reservationSet"][0]["instancesSet"][0]
  end

  desc "debug", "debug info"

  def debug
    @ec2 ||= Swirl::AWS.new :ec2, load_config
    ami_list = @ec2.call "DescribeImages", "Owner" => "self"
    images = ami_list["imagesSet"].select { |img| img["name"] } rescue nil
    @ami_images = Array.new
    images.each { |image| @ami_images << Ami.new(image) }
    @ami_images.each do |ami|
      ap ami.blockDeviceMapping[0]["ebs"]
    end
    puts ami_table
  end
end
Sprout.start