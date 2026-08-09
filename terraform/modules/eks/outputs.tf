output "cluster_id" {
  value = aws_eks_cluster.this.id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_ca_cert" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  value = aws_iam_role.nodes.arn
}

output "node_role_name" {
  value = aws_iam_role.nodes.name
}

output "oidc_provider_arn" {
  value = try("arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}", "")
}

output "oidc_provider_url" {
  value = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, "")
}