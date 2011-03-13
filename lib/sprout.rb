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

class Sprout < Thor

  desc "list", "list all the instances in your ec2 account"

  def list
    @ec2 ||= Swirl::AWS.new :ec2, load_config
    aws_instances = @ec2.call("DescribeInstances")
    @instances = Array.new
    aws_instances["reservationSet"].each {|reservation| @instances << Instance.new(reservation["instancesSet"][0])}
    instance_table = table do |t|
      t.headings = 'Name', 'Instance Id', 'Status', 'ip Address', 'Instance Type', 'AMI Image', 'Availablity Zone', 'DNS Cname'
      @instances.each do |instance|
        t << [((instance.tagSet.nil?) ? "Name Not Set" : instance.tagSet[0]["value"]),
              instance.instanceId, instance.instanceState["name"], instance.ipAddress,
              instance.instanceType, instance.imageId, instance.placement["availabilityZone"], instance.dnsName]
      end
    end
      puts instance_table
  end

  desc "debug", "debug info"
  def debug
    ec2 = Swirl::AWS.new :ec2, load_config
    instances = ec2.call("DescribeInstances")
    instances["reservationSet"].each do |instance|
      x = Instance.new(instance["instancesSet"][0])
      ap x.instance_variable_get
#      ap instance["instancesSet"][0].keys
    end 
  end

end
Sprout.start