data "hcp_packer_iteration" "ubuntu" {
  bucket_name = "aws"
  channel     = "production"
}

data "hcp_packer_image" "ubuntu" {
  bucket_name    = "aws"
  cloud_provider = "aws"
  iteration_id   = data.hcp_packer_iteration.ubuntu.ulid
  region         = "us-east-1"
}
