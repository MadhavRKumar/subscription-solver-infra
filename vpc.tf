resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "main" {

  vpc_id = aws_vpc.main.id

  tags = {

    Name = "internet_gateway"

  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.main.id

  }

}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private_subnet_route" {
  subnet_id = aws_subnet.private.id

  route_table_id = aws_route_table.private_route_table.id

}


resource "aws_route_table_association" "subnet_route" {
  subnet_id = aws_subnet.public.id

  route_table_id = aws_route_table.route_table.id
}


resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_tls"
  }

}

resource "aws_vpc_security_group_ingress_rule" "allow_tls" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


resource "aws_security_group" "allow_rds_access" {
  name        = "allow_rds_access"
  description = "Allow RDS access"

  tags = {
    Name = "allow_rds_access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_rds_access" {
  security_group_id = aws_security_group.allow_rds_access.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_rds_access" {
  security_group_id = aws_security_group.allow_rds_access.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
