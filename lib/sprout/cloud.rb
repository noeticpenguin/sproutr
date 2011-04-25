require 'swirl/aws'
require 'sproutr/utilities'

class Cloud

  class << self
    attr_accessor :instances, :images
  end

  def initialize
    @ec2 ||= Swirl::AWS.new :ec2, load_config
  end

  def get_instances
    aws_instances = @ec2.call "DescribeInstances"
    @instances = Array.new
    aws_instances["reservationSet"].each { |reservation| @instances << Instance.new(reservation["instancesSet"][0]) }
    @instances
  end

  def get_images
    aws_images = @ec2.call "DescribeImages", "Owner" => "self"
    images = aws_images["imagesSet"].select { |img| img["name"] } rescue nil
    @images = Array.new
    images.each { |image| @images << Ami.new(image) }
    @images
  end

  def describe_image(ami)
    @ec2.call "DescribeImages", "ImageId" => ami
  end

end