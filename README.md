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

## Update images across clouds

HCP Packer tracks all builds associated with your golden images, regardless of which hypervisor or cloud the build is associated with
## Create processes for security

Set end of life dates for images, or set up workflows that can revoke images across builds immediately

## Integrate with Terraform

Using the [HCP Provider for Terrafor](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs?_gl=1*16j7m9p*_ga*MTgwMDg3ODAwMy4xNjU4NDIxOTkx*_ga_P7S46ZYEKW*MTY2MDA0NzYwMS44LjAuMTY2MDA0NzYwMS4w), the Packer data source allows your teams to codify images in your Terraform configuration files rather than hard-coding them

<br>

# About this implementation

This repository, has the implementation of **HCP Packer** and **HCP Terraform** with **GitHub Actions**, you can read more about this on official web page https://cloud.hashicorp.com/products/packer and https://github.com/features/actions

# Code implementation

