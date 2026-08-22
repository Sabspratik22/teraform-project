provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "pratik-devops-tfstate-425034746613"
}
