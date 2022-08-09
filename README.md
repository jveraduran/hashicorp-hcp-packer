# HCP Packer with Github Actions
<p align="left" style="text-align:left;">
  <a href="https://www.packer.io">
    <img alt="HashiCorp Packer logo" src="img/logo-packer-padded.svg" width="500" />
  </a>
</p>

HCP Packer is a cross cloud image gallery for Packer. It uses metadata to track images, their artifacts, their iterations, as well as their build artifacts across clouds. Fetch the latest iteration of an image using the [HCP Packer API](https://cloud.hashicorp.com/api-docs/packer) to use across downstream builds and provisioning pipelines, and revoke images using automation.

<p align="left" style="text-align:left;">
    <img alt="AWS" src="img/aws.svg"/>
    <img alt="Azure" src="img/azure.svg"/>
    <img alt="GCP" src="img/gcp.svg"/>
    <img alt="VMWARE" src="img/vmware.svg"/>
  </a>
</p>

**Update images across clouds**

HCP Packer tracks all builds associated with your golden images, regardless of which hypervisor or cloud the build is associated with

**Create processes for security**

Set end of life dates for images, or set up workflows that can revoke images across builds immediately

**Integrate with Terraform**

Using the [HCP Provider for Terrafor](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs?_gl=1*16j7m9p*_ga*MTgwMDg3ODAwMy4xNjU4NDIxOTkx*_ga_P7S46ZYEKW*MTY2MDA0NzYwMS44LjAuMTY2MDA0NzYwMS4w), the Packer data source allows your teams to codify images in your Terraform configuration files rather than hard-coding them

<br>

# About this implementation

This repository, has the implementation of **HCP Packer** and **HCP Terraform** with **GitHub Actions**, you can read more about this on official web page https://cloud.hashicorp.com/products/packer and https://github.com/features/actions

# Code implementation

AWS 

```
source "amazon-ebs" "ami" {
  access_key            = var.aws_access_key
  ami_name              = join("-", [local.ami_name, var.version])
  force_delete_snapshot = true
  instance_type         = local.instance_type
  region                = var.region
  secret_key            = var.aws_secret_key
  source_ami            = local.source_ami
  ssh_username          = local.ssh_username
  tags = {
    Name        = local.ami_name
    Environment = var.app_env
  }
}

build {
  hcp_packer_registry {
    bucket_name = "aws"
    description = <<EOT
Some nice description about the image being published to HCP Packer Registry.
    EOT
    bucket_labels = {
      "Owner"          = "jveraduran"
      "OS"             = "Ubuntu",
      "Ubuntu-version" = "18.04 LTS",
      "Environment"    = var.app_env
    }

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }
  sources = [
    "source.amazon-ebs.ami"
  ]
}
```

AZURE

```
source "azure-arm" "image" {
  subscription_id     = var.subscription_id
  tenant_id           = var.tenant_id
  client_secret       = var.client_secret
  client_id           = var.client_id
  resource_group_name = "cl-azure-network-prod"
  storage_account     = "hashicorpacker"

  capture_container_name = "images"
  capture_name_prefix    = "packer"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "UbuntuServer"
  image_sku       = "18.04-LTS"

  location = "East US 2"
  vm_size  = "Standard_D2S_v3"

  azure_tags = {
    Name        = local.ami_name
    Environment = var.app_env
  }
}

build {
  hcp_packer_registry {
    bucket_name = "azure"
    description = <<EOT
Some nice description about the image being published to HCP Packer Registry.
    EOT
    bucket_labels = {
      "Owner"          = "jveraduran"
      "OS"             = "Ubuntu",
      "Ubuntu-version" = "18.04 LTS",
      "Environment"    = var.app_env
    }

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }
  sources = [
    "source.azure-arm.image"
  ]
}
```