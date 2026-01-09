/**
 * @author Andrea C. Crawford
 * @email acm@us.ibm.com
 * @create date 2026-01-08 15:33:00
 * @desc Terraform to set up golden image landing zone for the packer IBM Cloud
 * plugin, located at: https://github.com/IBM/packer-plugin-ibmcloud/
 */


###############################################################################
## Read Resource Group
##
## Gets reference to an existing resource group, specified in terraform.tfvars
###############################################################################
data "ibm_resource_group" "resource_group" {
   name   = var.resource_group
}

###############################################################################
## Create an Access Group
##
## Access Group that will contain the access policies and Service ID for image engineer
###############################################################################
resource "ibm_iam_access_group" "golden_image_ag" {
  name = "golden-image-ag"
  description = "Access and privileges for \"golden image\" (Packer) engineers to execute IBM Cloud packer plugin"
}

###############################################################################
## Create a Service ID
##
## Service Id for image engineers to test and save golden images
###############################################################################
resource "ibm_iam_service_id" "golden_image_service_id" {
  name        = "golden-image-service-id"
  description = "Service Id reserved for image engineers generating golden images"
}

###############################################################################
## Add Service ID to Access Group
###############################################################################
resource "ibm_iam_access_group_members" "golden_image_members" {
  access_group_id = ibm_iam_access_group.golden_image_ag.id
  #ibm_ids         = ["user@ibm.com"] /* for adding individual users */
  iam_service_ids = [ibm_iam_service_id.golden_image_service_id.id]
}


###############################################################################
## Create a IAM Service Policies
##
## Service ID policies will restrict access to only those services and resources
## necessary to test, create and store golden images
###############################################################################
resource "ibm_iam_access_group_policy" "resource_group_policy" {
  access_group_id = ibm_iam_access_group.golden_image_ag.id
  roles          = ["Editor"]
  resources {
    resource_type = "resource-group"
    resource = data.ibm_resource_group.resource_group.id
  }
}

resource "ibm_iam_access_group_policy" "vpc_policy" {
  access_group_id = ibm_iam_access_group.golden_image_ag.id
  roles          = ["Writer", "Editor"]
  resources {
    service = "is"
    resource_group_id = data.ibm_resource_group.resource_group.id
  }
}

resource "ibm_resource_key" "resourceKey" {
  name = "golden-image-credentials"
  role = "Writer"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  parameters = {
    "serviceid_crn" = ibm_iam_service_id.golden_image_service_id.crn
  }
}

###############################################################################
## Create a Key Protect (KMS) instance
##
## can also be substituted for an existing instance using a "data" block
###############################################################################
## UNCOMMENT if encrypting COS bucket with golden-images
/*
resource "ibm_resource_instance" "kms_instance" {
  name     = "instance-name"
  service  = "kms"
  plan     = "tiered-pricing"
  location = "us-south"
}
*/
###############################################################################
## Create KMS key to encrypt COS bucket
##
###############################################################################
## UNCOMMENT if encrypting COS bucket with golden-images
/*
resource "ibm_kms_key" "bucket_encryption_key" {
  instance_id  = ibm_resource_instance.kms_instance.guid
  key_name     = "golden-image-bucket-key"
  standard_key = false
  force_delete =true
}
*/
###############################################################################
## Create Service Authorization to permit COS to use key for encryption
##
###############################################################################
## UNCOMMENT if encrypting COS bucket with golden-images
/*
resource "ibm_iam_authorization_policy" "cos_kms_policy" {
    source_service_name = "cloud-object-storage"
    target_service_name = "kms"
    roles               = ["Reader"]
}
*/

###############################################################################
## Create Cloud Object Storage
## Name: golden-images (COS instance)
###############################################################################
resource "ibm_resource_instance" "cos_instance" {
  name              = "golden-images"
  resource_group_id = data.ibm_resource_group.resource_group.id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

###############################################################################
## Create COS bucket
## Name: base-linux (COS bucket)
## MUST BE UNIQUE across COS global
###############################################################################
resource "ibm_cos_bucket" "cos_bucket" {
  ## UNCOMMENT if encrypting COS bucket with golden-images
  ##depends_on = [ ibm_iam_authorization_policy.policy ]
  ##kms_key_crn         = ibm_kms_key.test.id
  bucket_name           = "base-linux"
  resource_instance_id  = ibm_resource_instance.cos_instance.id
  region_location       = "us-south"
  storage_class         = "smart"
}

###############################################################################
## Create Service Authorization to permit image to be written to COS bucket
###############################################################################
resource "ibm_iam_authorization_policy" "image_cos_policy" {
  source_service_name  = "is"
  source_resource_type = "image"
  target_service_name  = "cloud-object-storage"
  target_resource_instance_id = ibm_resource_instance.cos_instance.guid
  roles                = ["Writer"]
}

###############################################################################
## Create a VPC on IBM Cloud
## Availability Zones: 1 (no need for failover in Dev)
## Name: edge-vpc
## IP Address Range: 10.10.10.0/24 (256 IP addresses across all subnets)
###############################################################################
resource "ibm_is_vpc" "golden_image_vpc" {
  name = join("-", [var.prefix, "vpc"])
  resource_group = data.ibm_resource_group.resource_group.id
  address_prefix_management = "manual"
  default_routing_table_name = join("-", [var.prefix, "vpc", "rt", "default"])
  default_security_group_name = join("-", [var.prefix, "vpc", "sg", "default"])
  default_network_acl_name = join("-", [var.prefix, "vpc", "acl", "default"])
}

#set VPC Address prefix (all subnets in this vpc will derive from this range)
resource "ibm_is_vpc_address_prefix" "golden_image_prefix" {
  name = "golden-image-address-prefix"
  zone = var.zone
  vpc  = ibm_is_vpc.golden_image_vpc.id
  cidr = var.golden_image_vpc_address_prefix
}


###############################################################################
## Create Subnet #1: VPN Server Subnet
## Name: vpn-server-subnet
## CIDR: 10.10.10.0/25 (128 IP addresses in the VPN Server subnet)
## Language: Terraform
###############################################################################
resource "ibm_is_subnet" "golden_image_subnet" {
  depends_on = [
    ibm_is_vpc_address_prefix.golden_image_prefix
  ]
  ipv4_cidr_block = var.golden_image_vpc_cidr
  name            = "golden-image-subnet"
  vpc             = ibm_is_vpc.golden_image_vpc.id
  zone            = var.zone
  resource_group = data.ibm_resource_group.resource_group.id
}
