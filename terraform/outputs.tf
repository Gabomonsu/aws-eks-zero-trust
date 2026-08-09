output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "kms_keys_arn" {
  value = {
    s3         = module.kms_s3.key_arn
    dynamodb   = module.kms_dynamodb.key_arn
    cluster    = module.kms_cluster.key_arn
    ebs        = module.kms_ebs.key_arn
    ecr        = module.kms_ecr.key_arn
    secrets    = module.kms_secrets.key_arn
    cloudwatch = module.kms_logs.key_arn
  }
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "app_workload_role_arn" {
  value = module.irsa_app.role_arn
}