locals {
  oidc_issuer_url  = replace(var.oidc_provider_url, "https://", "")
  trust_conditions = var.use_pod_identity ? [] : var.namespaces
}

# Trust policy para Pod Identity (recomendado: sin necesidad de OIDC federation)
data "aws_iam_policy_document" "pod_identity_trust" {
  count = var.use_pod_identity ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Trust policy clasica via web identity (IRSA)
data "aws_iam_policy_document" "irsa_trust" {
  count = var.use_pod_identity ? 0 : 1
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringLike"
      variable = "${local.oidc_issuer_url}:sub"
      values = [for ns in var.namespaces :
        "system:serviceaccount:${ns}:${var.service_account}"
      ]
    }
  }
}

resource "aws_iam_role" "workload" {
  name               = var.role_name
  assume_role_policy = var.use_pod_identity ? data.aws_iam_policy_document.pod_identity_trust[0].json : data.aws_iam_policy_document.irsa_trust[0].json
  description        = "Rol IAM del workload ${var.role_name} (zero trust: minimo privilegio)"
  tags = merge(var.tags, {
    Name      = var.role_name
    Component = "iam"
  })
}

resource "aws_iam_role_policy" "inline" {
  count  = var.enable_inline_policy ? 1 : 0
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.workload.name
  policy = var.inline_policy
}

resource "aws_iam_role_policy_attachment" "managed" {
  count      = length(var.managed_policy_arns)
  role       = aws_iam_role.workload.name
  policy_arn = var.managed_policy_arns[count.index]
}

# Pod Identity Association si se usa el agente
resource "aws_eks_pod_identity_association" "this" {
  count           = var.use_pod_identity ? length(var.namespaces) : 0
  cluster_name    = var.cluster_name
  namespace       = var.namespaces[count.index]
  service_account = var.service_account
  role_arn        = aws_iam_role.workload.arn
}