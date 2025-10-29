
variable "param__post_eks_apply" {
  # Following - https://stackoverflow.com/questions/74861532/targeting-all-resources-exept-one-in-terraformthe-opposite-of-target-paramet

  # Set to TRUE if run phase 2 after EKS is created

  type = bool
  default = false
}

variable "param__gitops_ssh_private_key" {
  type = string
}

######### 

variable "gitops_repo_url" {
  type = string
}

variable "gitops_repo_path" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_region" {
  type = string
  default = "ap-southeast-1"
}

## VPC ##

variable "vpc_config" {
  description = "Config Block, following terraform-aws-modules/vpc/aws module"
  type = object({
    name = string
    cidr = string
    azs = list(string)
    private_subnets = list(string)
    public_subnets = list(string)
  })
  default = {
    name = "lab-vpc"
    cidr = "10.0.0.0/16"
    azs = [ "ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c" ]
    private_subnets = [ "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24" ]
    public_subnets = [ "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24" ] 
  }
}

## EKS ##

variable "eks_config" {
  description = "Config Block"
  type = object({
    cluster_name = string
  })
  default = {
    cluster_name = "lab-eks"
  }
}
