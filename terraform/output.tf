output "vpc_name" {
    value = ibm_is_vpc.golden_image_vpc.name
}

output "message" {
    value = <<EOM
    Resource Group: ${data.ibm_resource_group.resource_group.id}
    Region: ${var.region}
    Subnet ID: ${ibm_is_subnet.golden_image_subnet.id}
    COS Bucket: "${ibm_cos_bucket.cos_bucket.bucket_name}"

    If running the Packer golden image automation, be sure to take note of the values above,
    they will need to be added to the `variables.pkvars.hcl` file
    EOM
}
