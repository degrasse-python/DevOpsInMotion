# Configure terraform cloud
terraform {
  cloud {
    organization = "DevOpsInMotion"

    workspaces {
      name = "Buildkite--OctopusDeploy"
    }
  }
}

module "aws" {
  source = "./awsmodules/aws_account.tf"
  AWS_ACCESS_KEY_ID  = var.AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY  = var.AWS_SECRET_ACCESS_KEY 
  octopus_m_key = "./octopus_m_key"
}


module "google" {
  source = "./gcpmodules/gcp_account.tf"
  GCP_ACCESS_KEY_ID  = var.GCP_ACCESS_KEY_ID
  GCP_SECRET_ACCESS_KEY  = var.GCP_SECRET_ACCESS_KEY 
  GOOGLE_CREDENTIALS = var.GOOGLE_CREDENTIALS

  octopus_m_key = "./octopus_m_key"
}