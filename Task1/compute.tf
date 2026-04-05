resource "aws_instance" "tenant_ec2" {
  for_each = toset(var.tenant_name)

  ami           = "ami-0c02fb55956c7d316"   # Amazon Linux 2023 
  instance_type = var.instance_type

  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.tenant_sg[each.key].id]
  iam_instance_profile   = aws_iam_instance_profile.tenant_profile[each.key].name

  tags = {
    Name   = "${each.value}-backend"
    Tenant = each.value
  }
}