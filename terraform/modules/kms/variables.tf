variable "name" {
  type        = string
  description = "Nombre corto del key (se usa para el alias kms/<name>)"
}

variable "description" {
  type        = string
  description = "Descripcion humana del key"
}

variable "account_id" {
  type        = string
  description = "AWS account ID para habilitar permisos root"
}

variable "deletion_window_in_days" {
  type        = number
  default     = 7
  description = "Ventana de eliminacion tras 'destroy' en dias"
}

variable "enable_key_rotation" {
  type        = bool
  default     = true
  description = "Rotacion automatica anual del material del key"
}

variable "key_rotation_period" {
  type        = number
  default     = 365
  description = "Periodo de rotacion en dias (solo soportado en claves creadas despues de 2024)"
}

variable "multi_region" {
  type        = bool
  default     = false
  description = "Key multi-region (se replica en otras regiones de la misma cuenta)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags base"
}

variable "allow_service_principals" {
  type = list(object({
    sid       = string
    effect    = string
    principal = map(list(string))
    action    = list(string)
    resource  = string
    condition = object({
      test     = string
      variable = string
      values   = list(string)
    })
  }))
  default     = []
  description = "Statements extra para permitir que servicios AWS (ej. s3.amazonaws.com) usen el key. condition opcional (null si no se necesita)."
}

variable "grantee" {
  type        = string
  default     = ""
  description = "Principal que recibe un grant adicional (ej. rol de un workload)"
}

variable "enable_grant" {
  type        = bool
  default     = false
  description = "Habilitar el grant hacia el grantee (requiere var.grantee)"
}

variable "default_grant_operations" {
  type        = list(string)
  default     = ["Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "ReEncryptFrom", "ReEncryptTo", "DescribeKey"]
  description = "Operaciones otorgadas al grantee"
}