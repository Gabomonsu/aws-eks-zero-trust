variable "name" {
  type = string
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Rango CIDR principal de la VPC"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "az_count" {
  type        = number
  default     = 3
  description = "Numero de zonas de disponibilidad"
}

variable "private_subnet_offset" {
  type        = number
  default     = 0
  description = "Offset para que los CIDR privados no colisionen con los publicos"
}

variable "enable_nat" {
  type        = bool
  default     = true
  description = "Habilita NAT gateways para egress de nodos/workers"
}

variable "interface_endpoints" {
  type        = set(string)
  default     = ["ecr.api", "ecr.dkr", "sts", "logs", "secretsmanager"]
  description = "Servicios a exponer via Interface VPC Endpoints"
}

variable "endpoint_sg_ids" {
  type        = list(string)
  default     = []
  description = "Security groups que pueden usar los VPC endpoints (idealmente el/los del host bastion)"
}

variable "tags" {
  type    = map(string)
  default = {}
}