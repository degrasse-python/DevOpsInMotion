locals {
  ssh_user = "ubuntu"
  key_name = "devops"
  private_key_path = "~/githubRepos/.ssh/devops.pem"
}

provider "aws" {
  region = "us-east-2" # Modify to your desired region
  access_key = var.AWS_ACCESS_KEY_ID 
  secret_key = var.AWS_SECRET_ACCESS_KEY
}


data "aws_vpc" "default" {
  default = true
}


data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Create a security group allowing SSH access from anywhere
resource "aws_security_group" "buildkite_sg" {
  name        = "buildkite_sg"
  description = "Security group for Buildkite agent"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generate SSH private key
resource "tls_private_key" "buildkite_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create SSH key pair in AWS
resource "aws_key_pair" "buildkite_ssh_key" {
  key_name   = "buildkite_ssh_key"
  public_key = tls_private_key.buildkite_ssh_key.public_key_openssh
}

# Create an EC2 instance for the Buildkite agent
resource "aws_instance" "buildkite_instance" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Ubuntu 20.04 LTS AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.buildkite_ssh_key.key_name
  subnet_id              = data.aws_subnet_ids.default.ids
  security_groups        = [aws_security_group.buildkite_sg.name]
  associate_public_ip_address = true

  tags = {
    Name = "buildkite-agent"
  }
  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is available'"]

    connection {
    type        = "ssh"
    user        = local.ssh_user
    private_key = tls_private_key.buildkite_ssh_key.private_key_pem
    host        = self.public_ip
  }
  }
  
  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.buildkite_instance.public_ip}, --private-key ${local.private_key_path} buildkite-agent.yml"
    
  }

}

# Output the public IP address of the instance
output "buildkite_instance_public_ip" {
  value = aws_instance.buildkite_instance.public_ip
}
