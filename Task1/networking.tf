resource "aws_vpc" "payroll_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "payroll-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.payroll_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.payroll_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_eip" "nat_eip" {
  count = length(var.availability_zones)
  tags = {
    Name = "nat-eip-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.payroll_vpc.id
  tags = {
    Name = "payroll-igw"
  }
}

resource "aws_nat_gateway" "public_nat" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "nat-gateway-${count.index + 1}"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.payroll_vpc.id
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.payroll_vpc.id
  tags = {
    Name = "private-rt-${count.index + 1}"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private_route" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public_nat[count.index].id
}

resource "aws_route_table_association" "public_rt_association" {
  count          = length(var.availability_zones)
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route_table_association" "private_rt_association" {
  count          = length(var.availability_zones)
  route_table_id = aws_route_table.private_rt[count.index].id
  subnet_id      = aws_subnet.private[count.index].id
}