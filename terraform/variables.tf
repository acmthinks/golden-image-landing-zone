variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API key"
}

variable "prefix" {
  type        = string
  default = "golden-image"
  description = "The string that needs to be attached to every resource created"
}

variable "resource_group" {
  type        = string
  default     = "golden-image-rg"
  description = "Name of the resource group"
}

variable "region" {
  type        = string
  description = "IBM Cloud region to provision the resources."
  default     = "us-south"
}

variable "zone" {
  type        = string
  description = "IBM Cloud zone to provision the resources."
  default     = "us-south-1"
}

variable "golden_image_vpc_address_prefix" {
  type        = string
  description = "IP Address prefix (CIDR)"
  default     = "10.50.0.0/24"
}

variable "golden_image_vpc_cidr" {
  type        = string
  description = "IP Address CIDR for the vpn"
  default     = "10.50.0.0/25"
}
