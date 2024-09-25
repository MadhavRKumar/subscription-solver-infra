resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags = {
        Name = "main"
    }
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
    map_public_ip_on_launch = true
    availability_zone = "us-east-1"
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

        gateway_id = aws_internet_gateway.internet_gateway.id

    }

}


resource "aws_route_table_association" "subnet_route" {
    subnet_id      = aws_subnet.subnet.id

    route_table_id = aws_route_table.route_table.id

}


resource "aws_security_group" "allow_tls" {
    name        = "allow_tls"
    description = "Allow TLS inbound traffic"
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "allow_tls"
    }

}

resource "aws_vpc_security_group_ingress" "allow_tls" {
    security_group_id = aws_security_group.allow_tls.id
    cidr_ipv4 = aws_vpc.main.cidr_block
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
}

resource "aws_vpc_security_group_egress" "allow_all" {
    security_group_id = aws_security_group.allow_tls.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}
