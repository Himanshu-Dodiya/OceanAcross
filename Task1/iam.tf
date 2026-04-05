resource "aws_iam_role" "tenant_role" {
  for_each = toset(var.tenant_name)
  name = "${each.value}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Tenant = each.value
  }
  
}

resource "aws_iam_policy" "tenant_policy" {
  for_each = toset(var.tenant_name)
  name = "${each.value}-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = [
        "arn:aws:s3:::payroll-documents-bucket",
        "arn:aws:s3:::payroll-documents-bucket/${each.value}/*"
        ]
      },
      {
        Action = [
            "rds:connect",
          "ec2:DescribeInstances"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tenant_attach" {
    for_each = toset(var.tenant_name)
    role = aws_iam_role.tenant_role[each.key].name
    policy_arn = aws_iam_policy.tenant_policy[each.key].arn
}

resource "aws_iam_instance_profile" "tenant_profile" {
  for_each = toset(var.tenant_name)
  name = "${each.value}-profile"
  role = aws_iam_role.tenant_role[each.key].name
}