This repo contains Terraform to provision a landing zone to create "golden images" with the [IBM Packer plugin for IBM Cloud](https://github.com/IBM/packer-plugin-ibmcloud/)

"Golden images" is a term used to refer to operating system images that have been customized to certain standards (often based on enterprise guidelines). Often, certain operating system packages, users, groups, permissions, agent installs, fix packs and patches are the bedrock of "golden images" that are consumed by the enterprise.

These Terraform assets provision a VPC and all the minimally necessary IAM access groups and policies for an Image Engineer to construct and store QCOW2 images in IBM Cloud. This landing zone can be used with the https://github.com/acmthinks/golden-image repo to create "golden images" (either from IBM Cloud stock images, or your own custom images).

![image](golden-image-landing-zone.png "\"golden image\" landing zone")

#### Pre-requisites

1. Terraform (download [here](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs))
2. IBM Cloud account with permission to create VPC Infrastructure, create Cloud Object Storage, create KMS (if using bucket encryption for stored images), create resources in a Resource Group, and create IAM resouces (Service ID, Service Authorizations, Access Group, Access Policies)
3. IBM Cloud API Key

These pre-requisites are only required to setup the resources and infrastructure to support generation of "golden images". This is a one-time only setup to support "golden image" generation by an image engineer.

# Install

## 1. Clone repo

``` shell
git clone https://github.com/acmthinks/golden-image-landing-zone
```

## 2. Setup environment

Create a file `terraform.tfvars` with an IBM Cloud API key
``` shell
cd golden-image-landing-zone/terraform
vi terraform.tfvars
```

``` terraform
ibmcloud_api_key = "<IBM_CLOUD_API_KEY>"
```

## 3. Validate default variable values

Open `terraform/variables.tf` and validate default values for IBM Cloud region, zone, VPC IP address prefix and subnet CIDR. Update as necessary.

# Run

``` terraform
cd golden-image-landing-zone/terraform
terraform init
terraform plan
terraform apply
```

# Uninstall
1. Delete all objects (golden images) in the COS bucket
2. Deprovision Terraform resources
``` terraform
cd golden-image-landing-zone/terraform
terraform destroy
```
