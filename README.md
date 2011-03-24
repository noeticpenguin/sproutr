#Sprout
##EC2 made stupid simple.

##Introduction

sprout is a thor based EC2 instance management library which abstracts the Amazon EC2 API and provides an interactive interface for designing, launching, and managing running instances.

sprout is based around the idea of helping you define an instance, launch it, then create as many copies of that as you need. Currently Sprout supports the following tasks:
  Sprout clone --instance=one two three                # Clone N number of running instance
  Sprout create_ami --ami=AMI --desc=DESC --name=NAME  # Create an EBS Ami from a running or stopped instance
  Sprout define                                        # define a new instance
  Sprout delete_snapshot --snapshot=one two three      # Deletes the given snapshot(s) use --snapshot=
  Sprout describe --ami=one two three                  # Describe a specific instance
  Sprout destroy --ami=one two three                   # Alias to terminate
  Sprout help [TASK]                                   # Describe available tasks or one specific task
  Sprout launch --config-file=CONFIG_FILE              # launch an instance from the specified config directory
  Sprout list                                          # list all the instances and ami's in your ec2 account
  Sprout list_amis                                     # list all the ami's in your ec2 account
  Sprout list_instances                                # list all the instances in your ec2 account
  Sprout list_snapshots                                # Alias to list_snapshots
  Sprout list_snapshots                                # Lists all the snapshots available and their status
  Sprout restart --ami=one two three                   # Restart the specified instance(s), requires --ami=
  Sprout snapshot --ami=one two three                  # Create snapshot
  Sprout start --ami=one two three                     # Start the specified instance(s), requires --ami=
  Sprout stop --ami=one two three                      # Stop the specified instance(s), requires --ami=
  Sprout terminate --ami=one two three                 # Terminate the specified instance, requires --ami=

##Configuration

Sprout relies on the Swirl library, which needs to be passed your AWS credentials to do its magic.  Sprout therefore requires that you provide a .swirlrc file in your home directory (~/) that contains:
~/.swirl:
	---
	:default: 
	  :aws_access_key_id: my_access_key
	  :aws_secret_access_key: my_secret_key

##Usage

You can use Sprout to manage your instances from the commandline. You should create an instance which will serve as your "Sprout" and be converted into an AMI.
Once you have tested this instance, create a snapshot of the instance, then use it by AMI-Id to launch new instances with their own individual configuration.

Here's a simple example from the command line. Begin by invoking the define task.

    $ bin/Sprout define

Sprouts define task will walk you through the process of determining the name, instance size, starting AMI etc.
Key to the sprout experience is the way handles two key features: Chef and Volumes:
    Sprout builds the instance with knowledge of, and the ability to execute arbitrary chef cookbooks/recipes.
    While defining an instance you're given the opportunity to specify additional packages, cookbooks and recipes to have installed
    Currently only Debian (ubuntu, mint, etc.) based distributions are supported.
    Additionally, be aware that any volumes you specify will be aggregated together using mdadm and lvm into one logical volume.

Once defined, you can launch the instance via

    $ Sprout launch --definition=filename.json

You can monitor the instance's fabrication process via

    $ Sprout list

The instance you created will boot, install your selected packages on top of the stock AMI you selected, then download and cook all the cookbooks and recipes you selected.

##Inspiration and Thanks

Sprout is almost entirely based on the stem gem, a product (so far as I can tell) a gift of the Heroku development / operations team. 