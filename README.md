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

Using the [HCP Provider for Terraform](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs?_gl=1*16j7m9p*_ga*MTgwMDg3ODAwMy4xNjU4NDIxOTkx*_ga_P7S46ZYEKW*MTY2MDA0NzYwMS44LjAuMTY2MDA0NzYwMS4w), the Packer data source allows your teams to codify images in your Terraform configuration files rather than hard-coding them

<br>

# About this implementation

This repository, has the implementation of **HCP Packer** and **HCP Terraform** with **GitHub Actions**, you can read more about this on official web page https://cloud.hashicorp.com/products/packer and https://github.com/features/actions

# Code implementation

## HCP Packer with AWS 

The amazon-ebs Packer builder is able to create Amazon AMIs backed by EBS volumes for use in [EC2](https://aws.amazon.com/ec2/). For more information on the difference between EBS-backed instances and instance-store backed instances, see the ["storage for the root device" section in the EC2 documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ComponentsAMIs.html#storage-for-the-root-device).

This builder builds an AMI by launching an EC2 instance from a source AMI, provisioning that running machine, and then creating an AMI from that machine. This is all done in your own AWS account. The builder will create temporary keypairs, security group rules, etc. that provide it temporary access to the instance while the image is being created. This simplifies configuration quite a bit.

The builder does not manage AMIs. Once it creates an AMI and stores it in your account, it is up to you to use, delete, etc. the AMI.

Aditional, we'll use de [HCP Packer Registry](https://www.packer.io/docs/templates/hcl_templates/blocks/build/hcp_packer_registry) configuration, to manage our **Image LifeCycle** and with packer the [HCL2 Templates](https://www.packer.io/guides/hcl) with **Github Actions** as **Continous Integration** and **Continuous Delivery** Tool.

This is the definiton of the [HCL2](https://www.packer.io/guides/hcl) used 
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
This is the definiton of the [Github Action Workflow](./.github/workflows/packer-consul-aws.yml) used for  **Continous Integration** and **Continuous Delivery**. To include [Ansible Provisioner](https://www.packer.io/plugins/provisioners/ansible/ansible), i build a [Github Action on Marketplace](https://github.com/marketplace?type=actions) that you can use named [Packer GitHub Actions with Ansible Provisioner](https://github.com/marketplace/actions/packer-github-actions-with-ansible-provisioner) that consider [Advanced options](https://www.packer.io/docs/commands) based on ```fmt```and ```validate```. 

```
name: Packer Consul AWS

on:
  push:
    branches: [develop, staging, master]
  pull_request: 
    branches: [develop, staging, master]
    types: [opened, synchronize]

jobs:
  Validate-Packer:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    name: Validate-Packer
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Validate Template
        uses: jveraduran/packer-github-actions@master
        with:
          command: validate
          arguments: -syntax-only
          target: aws/packer-consul.json.pkr.hcl
  
  Format-Packer:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    name: Format-Packer
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Validate Template
        uses: jveraduran/packer-github-actions@master
        with:
          command: fmt
          target: aws/packer-consul.json.pkr.hcl

  Build:
    needs: [Validate-Packer,Format-Packer]
    if: ${{ (github.event_name == 'push') && always() }}
    runs-on: ubuntu-latest
    name: Build
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2
      
      - name: Setup ENV
        shell: bash
        run: |-
          if [ ${{ github.event_name }} == "pull_request" ]; then 
            branch=$(echo ${{ github.base_ref }}  | tr / -)
          else 
            branch=$(echo ${GITHUB_REF#refs/heads/} | tr / -)
          fi
          if [ $branch = "master" ]; then 
            env="production";
          elif [ $branch = "develop" ]; then 
            env="develop";
          elif [ $branch = "staging" ]; then 
            env="staging";
          else 
            echo "invalid environment"; exit -1
          fi
          echo "ENV=$(echo $env)" >> $GITHUB_ENV
      
      - name: Download Packer Plugin
        uses: jveraduran/packer-github-actions@master
        with:
          command: init
          target: aws/packer-consul.json.pkr.hcl

      - name: Build Artifact
        uses: jveraduran/packer-github-actions@master
        with:
          command: build
          arguments: "-color=false -on-error=abort -force -var version=${{ github.run_number }}"
          target: aws/packer-consul.json.pkr.hcl
        env:
          AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
          AWS_SECRET_KEY: ${{ secrets.AWS_SECRET_KEY }}
          AWS_REGION: "us-east-1"
          CONSUL_HTTP_ADDR: ${{ secrets.CONSUL_HTTP_ADDR }}
          CONSUL_HTTP_TOKEN: ${{ secrets.CONSUL_HTTP_TOKEN }}
          APP_ENV: ${{ env.ENV }}
          HCP_CLIENT_ID: ${{ secrets.HCP_CLIENT_ID }}
          HCP_CLIENT_SECRET: ${{ secrets.HCP_CLIENT_SECRET }}
```

For use this action, we must set up on [Github Encrypted Secrets](https://docs.github.com/en/enterprise-cloud@latest/actions/security-guides/encrypted-secrets) the ```AWS_ACCESS_KEY```, ```AWS_SECRET_KEY``` and ```AWS_REGION```for [AWS Provider](https://www.packer.io/plugins/builders/amazon#environment-variables). On Aditional, if you'll use [Consul KV](https://www.consul.io/commands#environment-variables), we must set up ```CONSUL_HTTP_ADDR```and ```CONSUL_HTTP_TOKEN```for [Consul Contextual Function](https://www.packer.io/docs/templates/hcl_templates/functions/contextual/consul). Finally, we must set up [HCP Packer Service Principal](https://cloud.hashicorp.com/docs/hcp/admin/service-principals) ```HCP_CLIENT_ID``` and ```HCP_CLIENT_SECRET```

## HCP Packer with Azure

Packer supports building Virtual Hard Disks (VHDs) and Managed Images in [Azure Resource Manager](https://azure.microsoft.com/en-us/documentation/articles/resource-group-overview/). Azure provides new users a [$200 credit for the first 30 days](https://azure.microsoft.com/en-us/free/); after which you will incur costs for VMs built and stored using Packer.

Azure uses a combination of OAuth and Active Directory to authorize requests to the ARM API. Learn how to [authorize access to ARM](https://packer.io/docs/builders/azure#authentication-for-azure).

The documentation below references command output from the Azure CLI.

Aditional, we'll use de [HCP Packer Registry](https://www.packer.io/docs/templates/hcl_templates/blocks/build/hcp_packer_registry) configuration, to manage our **Image LifeCycle** and with packer the [HCL2 Templates](https://www.packer.io/guides/hcl) with **Github Actions** as **Continous Integration** and **Continuous Delivery** Tool.

This is the definiton of the [HCL2](https://www.packer.io/guides/hcl) used 
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
```
This is the definiton of the [Github Action Workflow](./.github/workflows/packer-consul-azure.yml) used for  **Continous Integration** and **Continuous Delivery**. To include [Ansible Provisioner](https://www.packer.io/plugins/provisioners/ansible/ansible), i build a [Github Action on Marketplace](https://github.com/marketplace?type=actions) that you can use named [Packer GitHub Actions with Ansible Provisioner](https://github.com/marketplace/actions/packer-github-actions-with-ansible-provisioner) that consider [Advanced options](https://www.packer.io/docs/commands) based on ```fmt```and ```validate```. 

```
name: Packer Consul AZURE

on:
  push:
    branches: [develop, staging, master]
  pull_request: 
    branches: [develop, staging, master]
    types: [opened, synchronize]

jobs:
  Validate-Packer:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    name: Validate-Packer
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Validate Template
        uses: jveraduran/packer-github-actions@master
        with:
          command: validate
          arguments: -syntax-only
          target: azure/packer-consul.json.pkr.hcl
  
  Format-Packer:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    name: Format-Packer
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Validate Template
        uses: jveraduran/packer-github-actions@master
        with:
          command: fmt
          target: azure/packer-consul.json.pkr.hcl

  Build:
    needs: [Validate-Packer,Format-Packer]
    if: ${{ (github.event_name == 'push') && always() }}
    runs-on: ubuntu-latest
    name: Build
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2
      
      - name: Setup ENV
        shell: bash
        run: |-
          if [ ${{ github.event_name }} == "pull_request" ]; then 
            branch=$(echo ${{ github.base_ref }}  | tr / -)
          else 
            branch=$(echo ${GITHUB_REF#refs/heads/} | tr / -)
          fi
          if [ $branch = "master" ]; then 
            env="production";
          elif [ $branch = "develop" ]; then 
            env="develop";
          elif [ $branch = "staging" ]; then 
            env="staging";
          else 
            echo "invalid environment"; exit -1
          fi
          echo "ENV=$(echo $env)" >> $GITHUB_ENV
      
      - name: Download Packer Plugin
        uses: jveraduran/packer-github-actions@master
        with:
          command: init
          target: azure/packer-consul.json.pkr.hcl

      - name: Build Artifact
        uses: jveraduran/packer-github-actions@master
        with:
          command: build
          arguments: "-color=false -on-error=abort -force -var version=${{ github.run_number }}"
          target: azure/packer-consul.json.pkr.hcl
        env:
          AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          CONSUL_HTTP_ADDR: ${{ secrets.CONSUL_HTTP_ADDR }}
          CONSUL_HTTP_TOKEN: ${{ secrets.CONSUL_HTTP_TOKEN }}
          APP_ENV: ${{ env.ENV }}
          HCP_CLIENT_ID: ${{ secrets.HCP_CLIENT_ID }}
          HCP_CLIENT_SECRET: ${{ secrets.HCP_CLIENT_SECRET }}
```

For use this action, we must set up on [Github Encrypted Secrets](https://docs.github.com/en/enterprise-cloud@latest/actions/security-guides/encrypted-secrets) the ```AZURE_SUBSCRIPTION_ID```, ```AZURE_TENANT_ID```, ```AZURE_CLIENT_ID``` and ```AZURE_CLIENT_SECRET``` for [Azure Provider](https://www.packer.io/plugins/builders/azure#azure-active-directory-service-principal). On Aditional, if you'll use [Consul KV](https://www.consul.io/commands#environment-variables), we must set up ```CONSUL_HTTP_ADDR```and ```CONSUL_HTTP_TOKEN```for [Consul Contextual Function](https://www.packer.io/docs/templates/hcl_templates/functions/contextual/consul). Finally, we must set up [HCP Packer Service Principal](https://cloud.hashicorp.com/docs/hcp/admin/service-principals) ```HCP_CLIENT_ID``` and ```HCP_CLIENT_SECRET```

## HCP Packer with GCP

The googlecompute Packer builder is able to create [images](https://developers.google.com/compute/docs/images) for use with [Google Compute Engine](https://cloud.google.com/products/compute-engine) (GCE) based on existing images.

It is possible to build images from scratch, but not with the googlecompute Packer builder. The process is recommended only for advanced users, please see [Building GCE Images from Scratch](https://cloud.google.com/compute/docs/tutorials/building-images) and the [Google Compute Import Post-Processor](https://www.packer.io/docs/post-processors/googlecompute-import) for more information..

Aditional, we'll use de [HCP Packer Registry](https://www.packer.io/docs/templates/hcl_templates/blocks/build/hcp_packer_registry) configuration, to manage our **Image LifeCycle** and with packer the [HCL2 Templates](https://www.packer.io/guides/hcl) with **Github Actions** as **Continous Integration** and **Continuous Delivery** Tool.

This is the definiton of the [HCL2](https://www.packer.io/guides/hcl) used 
```
source "googlecompute" "basic-example" {
  account_file = var.account_file
  project_id   = local.project_id
  image_name   = "packer"
  machine_type = "e2-medium"
  source_image = "ubuntu-2204-jammy-v20220810"
  ssh_username = "ubuntu"
  zone         = "southamerica-west1-a"
}

build {
  hcp_packer_registry {
    bucket_name = "gcp"
    description = <<EOT
Some nice description about the image being published to HCP Packer Registry.
    EOT
    bucket_labels = {
      "Owner"          = "jveraduran"
      "OS"             = "Ubuntu",
      "Ubuntu-version" = "22.04 LTS",
      "Environment"    = var.app_env
    }

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }
  sources = [
    "sources.googlecompute.basic-example"
  ]
}
```
This is the definiton of the [Github Action Workflow](./.github/workflows/packer-consul-gcp.yml) used for  **Continous Integration** and **Continuous Delivery**. To include [Ansible Provisioner](https://www.packer.io/plugins/provisioners/ansible/ansible), i build a [Github Action on Marketplace](https://github.com/marketplace?type=actions) that you can use named [Packer GitHub Actions with Ansible Provisioner](https://github.com/marketplace/actions/packer-github-actions-with-ansible-provisioner) that consider [Advanced options](https://www.packer.io/docs/commands) based on ```fmt```and ```validate```. 

## Advantages of Using Packer

**Super fast infrastructure deployment.** Packer images allow you to launch completely provisioned and configured machines in seconds, rather than several minutes or hours. This benefits not only production, but development as well, since development virtual machines can also be launched in seconds, without waiting for a typically much longer provisioning time.

**Multi-provider portability** Because Packer creates identical images for multiple platforms, you can run production in AWS, staging/QA in a private cloud like OpenStack, and development in desktop virtualization solutions such as VMware or VirtualBox. Each environment is running an identical machine image, giving ultimate portability.

**Improved stability**. Packer installs and configures all the software for a machine at the time the image is built. If there are bugs in these scripts, they'll be caught early, rather than several minutes after a machine is launched.

**Greater testability**. After a machine image is built, that machine image can be quickly launched and smoke tested to verify that things appear to be working. If they are, you can be confident that any other machines launched from that image will function properly.

Packer makes it extremely easy to take advantage of all these benefits. :sunglasses:


## Licence

The scripts and documentation in this project are released under the [MIT License](./LICENSE)
## Contributions

Contributions are welcome! See [Contributor's Guide](./docs/contributors.md)

## Code of Conduct

👋 Be nice. See our [code of conduct](./docs/code_of_conduct.md)
