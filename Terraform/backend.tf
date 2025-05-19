terraform {
  backend "s3" {
    bucket       = "bilarn-devops-eks-aws-bucket-05"
    region       = "us-east-1"
    key          = "aws-eks-mtire-devsec-project/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
  required_version = ">=0.13.0"
  required_providers {
    aws = {
      version = ">= 2.7.0"
      source  = "hashicorp/aws"
    }
  }
}
