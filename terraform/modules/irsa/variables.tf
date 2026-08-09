variable "role_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "account_id" {
  type        = string
  description = "Account ID de AWS (para confinar la trust policy de Pod Identity)"
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "namespaces" {
  type        = list(string)
  description = "Namespaces a los que se asocia el rol"
}

variable "service_account" {
  type        = string
  default     = "default"
  description = "ServiceAccount vinculada al rol"
}

variable "use_pod_identity" {
  type        = bool
  default     = true
  description = "Usa EKS Pod Identity (recomendado) en vez de IRSA clasica por OIDC por namespace"
}

variable "managed_policy_arns" {
  type    = list(string)
  default = []
}

variable "inline_policy" {
  type    = string
  default = ""
}

variable "enable_inline_policy" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}