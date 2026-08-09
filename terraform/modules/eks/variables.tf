variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "kms_cluster_key_arn" {
  type        = string
  description = "ARN del KMS key para cifrar secrets del cluster"
}

variable "kms_ebs_key_arn" {
  type        = string
  description = "ARN del KMS key para cifrar discos EBS de los nodos"
}

variable "authentication_mode" {
  type        = string
  default     = "API_AND_CONFIG_MAP"
  description = "Modo de autenticacion: API_AND_CONFIG_MAP, API o CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  type        = bool
  default     = false
  description = "Otorgar cluster-admin al creador (keep false en zero trust; usar Pod Identity / IRSA)"
}

variable "cluster_log_types" {
  type    = list(string)
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "service_ipv4_cidr" {
  type        = string
  default     = "172.20.0.0/16"
  description = "CIDR para ClusterIPs de servicios (no debe solaparse con la VPC)"
}

variable "node_group_name" {
  type    = string
  default = "workers"
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "ami_type" {
  type    = string
  default = "AL2_x86_64"
}

variable "capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "volume_size" {
  type    = number
  default = 40
}

variable "tags" {
  type    = map(string)
  default = {}
}