locals {
  data-path = "${path.root}/data"
  playbook-path = "${local.data-path}/playbooks"
  ssh-configs-path = "${local.data-path}/ssh_configs"
  ssh-keys-path = "${local.data-path}/ssh_keys"
  templates-path = "${local.data-path}/templates"
  credentials-path = "${local.data-path}/credentials"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}
variable "base-internal-security_groups"{
  type = list(string)
}

variable "base-public-security_groups" {
  type = list(string)
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}
variable "acme_server_urls" {
  type = map(string)
  default = {
    "staging" = "https://acme-staging-v02.api.letsencrypt.org/directory"
    "production" = "https://acme-v02.api.letsencrypt.org/directory"
  }
}

#staging or production
variable "acme_server_type" {
  type = string
  default = "production"
}

variable "amis" {
  type = map(string)
  default = {
    // https://wiki.debian.org/Cloud/AmazonEC2Image/Buster amd64
    "af-south-1" = "ami-021ea31a882dc6e26"
    "ap-east-1" = "ami-09da9778"
    "ap-northeast-1" = "ami-048fd87c7ead0af9a"
    "ap-northeast-2" = "ami-0bc7e80fd49f70717"
    "ap-south-1" = "ami-074004b07f40bac7f"
    "ap-southeast-1" = "ami-0a37dc64b36bce463"
    "ap-southeast-2" = "ami-04472326bb46be1ce"
    "ca-central-1" = "ami-0f712cd4f98ca897f"
    "eu-central-1" = "ami-03173d987db03911c"
    "eu-north-1" = "ami-098e3e0c0e82384a8"
    "eu-south-1" = "ami-085d463c092d1d692"
    "eu-west-1" = "ami-02e64d6c81725f843"
    "eu-west-2" = "ami-085d463c092d1d692"
    "eu-west-3" = "ami-009d9923c983f524d"
    "me-south-1" = "ami-07472751c2eaf2429"
    "sa-east-1" = "ami-0bb7c15f6d611f64c"
    "us-east-1" = "ami-0e0161137b4b30900"
    "us-east-2" = "ami-06be10ae4a207f54a"
    "us-west-1" = "ami-06f4f25615eefbc7a"
    "us-west-2" = "ami-0cdf40a7f31926f5e"
  }
}

#variable "amis2" {
#  type = map(string)
#  default = {
#    "us-east-1" = "ami-052465340e6b59fc0"
#  }
#}
