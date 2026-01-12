terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "1.66.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "random" {}
