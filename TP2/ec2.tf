terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        #version = "~> 5.0" # This will allow any version from 5.0 to less than 6.0
        version = "5.65.0"
        }
    }
    
    required_version = ">= 1.0.0" #1.9.4
    #required_version = "1.9.4" 
}

provider "aws" {
    region = "us-east-1"
    shared_credentials_files = ["../.secrets/credentials"]
  
}

resource "aws_instance" "myec2" {
    ami = "ami-005fc0f236362e99f" # Amazon Linux 2 AMI
    instance_type = "t2.micro"
    key_name = "ssh-key"

    tags = {
        Name = "ec2-cfk"
    }

    # root_block_device {
    #   delete_on_termination = true
    # }
}