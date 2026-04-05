resource "aws_security_group" "tenant_sg" {
    for_each = toset(var.tenant_name)
    name = "${each.value}-sg"
    description = "Security group for ${each.value} instances"
    vpc_id = aws_vpc.payroll_vpc.id
    tags = {
        Name = "${each.value}-sg"   
        Tenant = each.value
    }
}

resource "aws_network_acl" "private_nacl" {
    vpc_id = aws_vpc.payroll_vpc.id
    subnet_ids = aws_subnet.private[*].id

    ingress {
        rule_no = 100
        protocol = "tcp"
        cidr_block = "10.0.0.0/16"
        from_port = 0
        to_port = 65535
        action = "allow"

    }

    egress {
        rule_no = 100
        protocol = "-1"
        cidr_block = "0.0.0.0/10"
        from_port = 0
        to_port = 0
        action = "allow"
    }
    tags = {
        Name = "private-nacl"
    }
}