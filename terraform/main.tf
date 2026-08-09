terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket         = "eks-zero-trust-state" # REEMPLAZA con tu bucket de estado (S3 + KMS + DDB lock)
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "eks-zero-trust-lock" # tabla DynamoDB con LockID
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "eks-zero-trust"
      Owner       = var.owner
      Managed_By  = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  # Confined deputy: las politicas de KMS/IAM aceptan llamadas de servicios
  # solo si vienen de EL MISMO account (evita cross-account abuse).
  source_account_condition = {
    test     = "StringEquals"
    variable = "aws:SourceAccount"
    values   = [data.aws_caller_identity.current.account_id]
  }
}

# =====================================================================
# KMS KEYS - un CMK por servicio (zero trust: aislamiento de claves)
# =====================================================================
module "kms_s3" {
  source      = "./modules/kms"
  name        = "eks-zero-trust-s3"
  description = "Cifrado de bucket de estado y artefactos"
  account_id  = data.aws_caller_identity.current.account_id
  allow_service_principals = [
    {
      sid       = "AllowS3ToUseKey"
      effect    = "Allow"
      principal = { Service = ["s3.amazonaws.com"] }
      action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*"]
      resource  = "*"
      condition = local.source_account_condition
    }
  ]
}

module "kms_dynamodb" {
  source      = "./modules/kms"
  name        = "eks-zero-trust-ddb"
  description = "Cifrado de la tabla de lock"
  account_id  = data.aws_caller_identity.current.account_id
  allow_service_principals = [
    {
      sid       = "AllowDDBToUseKey"
      effect    = "Allow"
      principal = { Service = ["dynamodb.amazonaws.com"] }
      action    = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey*"]
      resource  = "*"
      condition = local.source_account_condition
    }
  ]
}

module "kms_cluster" {
  source      = "./modules/kms"
  name        = "eks-zero-trust-cluster"
  description = "Cifrado de secrets en control-plane EKS"
  account_id  = data.aws_caller_identity.current.account_id
  allow_service_principals = [
    {
      sid       = "AllowEKSToUseKey"
      effect    = "Allow"
      principal = { Service = ["eks.amazonaws.com"] }
      action    = ["kms:Decrypt", "kms:GenerateDataKey", "kms:GenerateDataKeyWithoutPlaintext", "kms:DescribeKey"]
      resource  = "*"
      condition = local.source_account_condition
    }
  ]
}

module "kms_ebs" {
  source      = "./modules/kms"
  name        = "eks-zero-trust-ebs"
  description = "Cifrado de volumenes EBS de nodos y PVCs"
  account_id  = data.aws_caller_identity.current.account_id
  allow_service_principals = [
    {
      sid       = "AllowEC2ToUseKey"
      effect    = "Allow"
      principal = { Service = ["ec2.amazonaws.com"] }
      action    = ["kms:Decrypt", "kms:Encrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:CreateGrant"]
      resource  = "*"
      condition = local.source_account_condition
    },
    {
      sid       = "AllowEBSToUseKey"
      effect    = "Allow"
      principal = { Service = ["ebs.amazonaws.com"] }
      action    = ["kms:Decrypt", "kms:Encrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:CreateGrant"]
      resource  = "*"
      condition = local.source_account_condition
    }
  ]
  grantee      = module.eks.node_role_arn
  enable_grant = true
}

module "kms_ecr" {
  source      = "./modules/kms"
  name        = "eks-zero-trust-ecr"
  description = "Cifrado de imagenes container en ECR"
  account_id  = data.aws_caller_identity.current.account_id
  allow_service_principals = [
    {
      sid       = "AllowECRToUseKey"
      effect    = "Allow"
      principal = { Service = ["ecr.amazonaws.com"] }
      action    = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"]
      resource  = "*"
      condition = local.source_account_condition
    }
  ]
}

module "kms_secrets" {
  source      = "./modules/kms"
  name        = "eks-zero-trust-secrets"
  description = "Cifrado de Secrets Manager y Parameter Store (secure strings)"
  account_id  = data.aws_caller_identity.current.account_id
  allow_service_principals = [
    {
      sid       = "AllowSecretsManagerToUseKey"
      effect    = "Allow"
      principal = { Service = ["secretsmanager.amazonaws.com"] }
      action    = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"]
      resource  = "*"
      condition = local.source_account_condition
    },
    {
      sid       = "AllowSSMToUseKey"
      effect    = "Allow"
      principal = { Service = ["ssm.amazonaws.com"] }
      action    = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey*"]
      resource  = "*"
      condition = local.source_account_condition
    }
  ]
}

module "kms_logs" {
  source      = "./modules/kms"
  name        = "eks-zero-trust-logs"
  description = "Cifrado de CloudWatch Logs (auditoria del cluster)"
  account_id  = data.aws_caller_identity.current.account_id
  allow_service_principals = [
    {
      sid       = "AllowCloudWatchToUseKey"
      effect    = "Allow"
      principal = { Service = ["logs.amazonaws.com"] }
      action    = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey*"]
      resource  = "*"
      condition = local.source_account_condition
    }
  ]
}

# =====================================================================
# VPC privada + endpoints (zero trust de red)
# =====================================================================
module "vpc" {
  source                = "./modules/vpc"
  name                  = "eks-zero-trust"
  region                = var.region
  cidr_block            = "10.0.0.0/16"
  az_count              = 3
  enable_nat            = true
  interface_endpoints   = ["ecr.api", "ecr.dkr", "sts", "logs", "secretsmanager"]
  enable_flow_logs      = true
  flow_logs_kms_key_arn = module.kms_logs.key_arn
}

# =====================================================================
# EKS cluster privado + nodos cifrados
# =====================================================================
module "eks" {
  source                                      = "./modules/eks"
  cluster_name                                = "eks-zero-trust"
  vpc_id                                      = module.vpc.vpc_id
  private_subnet_ids                          = module.vpc.private_subnet_ids
  kubernetes_version                          = var.kubernetes_version
  kms_cluster_key_arn                         = module.kms_cluster.key_arn
  kms_ebs_key_arn                             = module.kms_ebs.key_arn
  bootstrap_cluster_creator_admin_permissions = false
  tags                                        = { Team = var.owner }
}

# =====================================================================
# Pod Identity: un rol IAM por workload (zero trust de identidad)
# =====================================================================
module "irsa_app" {
  source               = "./modules/irsa"
  role_name            = "eks-zero-trust-app"
  cluster_name         = module.eks.cluster_name
  account_id           = data.aws_caller_identity.current.account_id
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  namespaces           = ["app"]
  service_account      = "app-sa"
  use_pod_identity     = true
  enable_inline_policy = true
  inline_policy        = data.aws_iam_policy_document.app_workload.json
}

data "aws_iam_policy_document" "app_workload" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "kms:Decrypt"
    ]
    resources = [
      module.kms_secrets.key_arn
    ]
  }
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/eks-zero-trust/*"
    ]
  }
}