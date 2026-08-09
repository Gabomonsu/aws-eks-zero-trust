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

variable "enable_flow_logs" {
  type        = bool
  default     = true
  description = "Habilita VPC Flow Logs hacia CloudWatch Logs (cifrados con KMS)"
}

variable "flow_logs_retention_days" {
  type        = number
  default     = 90
  description = "Dias de retencion del CloudWatch Log Group de flow logs"
}

variable "flow_logs_kms_key_arn" {
  type        = string
  default     = ""
  description = "ARN del KMS key para cifrar los flow logs (requerido con enable_flow_logs=true)"
}

variable "tags" {
  type    = map(string)
  default = {}
}