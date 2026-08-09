data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid       = "EnableIAMRootPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = var.allow_service_principals
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.action
      resources = [statement.value.resource]
      principals {
        type        = one(keys(statement.value.principal))
        identifiers = statement.value.principal[one(keys(statement.value.principal))]
      }
      dynamic "condition" {
        for_each = statement.value.condition == null ? [] : [statement.value.condition]
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_kms_key" "this" {
  description              = "${var.name} encryption key - ${var.description}"
  deletion_window_in_days  = var.deletion_window_in_days
  enable_key_rotation      = var.enable_key_rotation
  rotation_period_in_days  = var.key_rotation_period
  policy                   = data.aws_iam_policy_document.kms_policy.json
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = var.multi_region
  tags = merge(var.tags, {
    Name       = var.name
    Component  = "kms"
    Managed_By = "terraform"
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_kms_grant" "default" {
  for_each          = var.enable_grant ? { default = 1 } : {}
  name              = "${var.name}-default-grant"
  key_id            = aws_kms_key.this.key_id
  grantee_principal = var.grantee
  operations        = var.default_grant_operations
}