terraform {
  required_version = "~> 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.51"
    }
    github = {
      source  = "integrations/github"
      version = "6.2.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.2"
    }
  }
}
