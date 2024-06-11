locals {
  ssh_user = "ubuntu"
  key_name = "buildkite_ssh_key"
  environment = "prod"
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

data "aws_subnet" "default_subnet_set" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

/*

Security 

*/

# Create a security group allowing SSH access from anywhere
resource "aws_security_group" "buildkite_sg" {
  name        = "buildkite_sg"
  description = "Allow SSH access from anywhere."
  vpc_id      = data.aws_vpc.default.id
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

variable "octopus_m_key" {}

resource "tls_private_key" "octopus_tls_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "octopus_generated_key" {
  key_name   = var.octopus_m_key
  public_key = tls_private_key.octopus_tls_key.public_key_openssh
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
  vpc_security_group_ids = [aws_security_group.buildkite_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "buildkite-agent"
  }
  
  provisioner "remote-exec" {
    # https://github.com/degrasse-python/DevOpsInMotion/tree/4521205cc25012bfb1f7fc3c93dc7dc4ed67fcd0/buildkite--octopus
    #    git archive --remote=https://github.com/degrasse-python/DevOpsInMotion.git --format=zip main 'buildkite--octopus' -o buildkite--octopus.zip
    #https://github.com/degrasse-python/DevOpsInMotion/tree/main/buildkite--octopus
    #    wget -r -P buildkite--octopus https://github.com/degrasse-python/DevOpsInMotion/tree/4521205cc25012bfb1f7fc3c93dc7dc4ed67fcd0/buildkite--octopus
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
    working_dir = path.cwd
    # working dir is buildkite--octopus/infra/
    command = "sudo ansible-playbook -i ${aws_instance.buildkite_instance.public_ip} --private-key ${tls_private_key.buildkite_ssh_key.private_key_pem} ansible/playbook.yaml"
  }

}

/*

postgresql on aws rds

resource "aws_db_instance" "octopus_db" {
  identifier           = "octopus-db"
  allocated_storage    = 40
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "11.4"
  instance_class       = "db.t2.micro"
  username             = "user"
  password             = "mypassword"
  parameter_group_name = "default.postgres11"
  publicly_accessible  = true
}


EKS Cluster 
  Octopus / Argo CD




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

# Export Terraform variable values to an Ansible var_file
resource "local_file" "tf_ansible_vars_file_new" {
  content = <<-DOC
    # Ansible vars_file containing variable values from Terraform.
    # Generated by Terraform mgmt configuration.

    tf_environment: ${local.environment}
    tf_db_connection_string: "Server=tcp:${octopus_db.default.endpoint},${octopus_db.default.port};Initial Catalog=OctopusDeploy;Persist Security Info=False;User ID=octopus-deploy;Password=password;Encrypt=True;Connection Timeout=30;}"
    tf_m_key: ${tls_private_key.octopus_tls_key.private_key_pem}
    
    DOC
  filename = "../ansible/tf_ansible_vars_file.yml"
}
*/




output "buildkite_security_group_id" {
  value       = aws_security_group.buildkite_sg.id
  description = "id of security group"
}

output "default_vpc_id" {
  value       = data.aws_vpc.default.id
  description = "id of security group"
}

output "current_directory" {
  value = path.cwd
}

/*

output "octopus_db" {
  value = octopus_db.default.endpoint
}

output "octopus_db_port" {
  value = octopus_db.default.port
}

*/