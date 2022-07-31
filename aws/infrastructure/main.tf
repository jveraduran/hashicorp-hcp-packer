data "hcp_packer_iteration" "ubuntu" {
  bucket_name = "jveraduran"
  channel     = "production"
}

data "hcp_packer_image" "ubuntu" {
  bucket_name    = "jveraduran"
  cloud_provider = "aws"
  iteration_id   = data.hcp_packer_iteration.ubuntu.ulid
  region         = "us-east-1"
}

resource "aws_instance" "ubuntu" {
  ami           = data.hcp_packer_image.ubuntu.cloud_image_id
  instance_type = "t2.micro"
  tags = {
    Name = "HCP-Packer"
    CECO = "O123"
    SystemInfo = "HCP-Packer"
  }
}