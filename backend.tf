terraform {
  backend "s3" {
    bucket         = "my-project-terraform-state-bucket"   # replace with your bootstrapped bucket name
    key            = "jenkins-infra/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}
