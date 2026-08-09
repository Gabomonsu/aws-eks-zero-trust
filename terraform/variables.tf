variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "sandbox"
}

variable "owner" {
  type    = string
  default = "cloud-engineer"
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}