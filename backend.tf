terraform {
  backend "s3" {
    bucket         = "my-project-terraform-state-bucket"
    key            = "jenkins-infra/terraform.tfstate"
    region         = "eu-central-1"
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
