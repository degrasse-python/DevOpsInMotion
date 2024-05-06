locals {
  ssh_user = "ubuntu"
  key_name = "devops"
  # private_key_path = "~/githubRepos/.ssh/devops.pem"
}

provider "aws" {
  region = "us-east-2" # Modify to your desired region
  access_key = var.AWS_ACCESS_KEY_ID 
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

/*

Data

*/

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "subnet_set" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

/*

Security 

*/

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

# Create an IAM role for the EKS cluster
resource "aws_iam_role" "eks_admin_role" {
  name               = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach IAM policies to the role
resource "aws_iam_policy_attachment" "eks_policy_attachment" {
  name       = "eks-cluster-policy-attachment"
  roles      = [aws_iam_role.eks_admin_role.name]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"  # Provides permissions to create and manage EKS clusters
}

resource "aws_iam_policy_attachment" "eks_node_policy_attachment" {
  name       = "eks-node-policy-attachment"
  roles      = [aws_iam_role.eks_admin_role.name]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"  # Provides permissions to attach IAM roles to worker nodes
}

resource "aws_iam_policy_attachment" "eks_cni_policy_attachment" {
  name       = "eks-cni-policy-attachment"
  roles      = [aws_iam_role.eks_admin_role.name]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"  # Provides permissions for the Amazon VPC CNI plugin used by EKS clusters
}

resource "aws_iam_policy_attachment" "eks_service_policy_attachment" {
  name       = "eks-service-policy-attachment"
  roles      = [aws_iam_role.eks_admin_role.name]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"  # Provides permissions for Kubernetes service discovery via AWS CloudMap
}

resource "aws_iam_policy_attachment" "eks_fargate_policy_attachment" {
  name       = "eks-fargate-policy-attachment"
  roles      = [aws_iam_role.eks_admin_role.name]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"  # Provides permissions for Fargate pod execution role
}

/*

EC2

*/

# Create an EC2 instance for the Buildkite agent
resource "aws_instance" "buildkite_instance" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Ubuntu 20.04 LTS AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.buildkite_ssh_key.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  security_groups        = [aws_security_group.buildkite_sg.name]
  vpc_security_group_ids = ["${aws_security_groups.buildkite_sg.id}"]
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
    # √buildkite--octopus/infra/ansible/roles/buildkite/tasks/install.yaml
    command = "ansible-playbook -i ${aws_instance.buildkite_instance.public_ip}, --private-key ${tls_private_key.buildkite_ssh_key.private_key_pem} ../ansible/playbook.yaml"
  }

}

/*

EKS Cluster 
  Argo CD




resource "aws_eks_cluster" "prod" {
  name     = "prod"
  role_arn = aws_iam_role.eks_admin_role.arn

  vpc_config {
    subnet_ids = [data.aws_subnets.default.ids[0], data.aws_subnets.default.ids[1]]
  
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_policy_attachment.eks_cni_policy_attachment,
    aws_iam_policy_attachment.eks_fargate_policy_attachment,
    aws_iam_policy_attachment.eks_node_policy_attachment,
    aws_iam_policy_attachment.eks_policy_attachment,
    aws_iam_policy_attachment.eks_service_policy_attachment,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.prod.endpoint
}
*/