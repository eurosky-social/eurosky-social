terraform {
  required_version = ">= 1.0"

  required_providers {
    upcloud = {
      source  = "upcloudltd/upcloud"
      version = ">= 5.0.0"
    }
  }
}
