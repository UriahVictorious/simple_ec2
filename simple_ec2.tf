provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "shadows" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "2-shadows"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.shadows.id
  cidr_block              = "10.245.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "2-shadows-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.shadows.id

  tags = {
    Name = "2-shadows-internet-gateway"
  }
}

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.shadows.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "2-shadows-route-table"
  }
}

resource "aws_route_table_association" "route-table" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route-table.id
}





resource "aws_security_group" "EC2" {
  name        = "EC2-security-group"
  description = "Security Group for the EC2 instance"
  vpc_id      = aws_vpc.shadows.id

  ingress {
    description     = "Allow HTTP from CloudFront only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_eip" "first_eip" {
#   instance = aws_instance.first_instance.id
# }

# resource "aws_eip" "second_eip" {
#   instance = aws_instance.second_instance.id
# }

# resource "aws_eip_association" "first_assoc" {
#   instance_id   = aws_instance.first_instance.id
#   allocation_id = aws_eip.first_eip.id
# }
# resource "aws_eip_association" "second_assoc" {
#   instance_id   = aws_instance.second_instance.id
#   allocation_id = aws_eip.second_eip.id
# }
resource "aws_instance" "first_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet1.id
  associate_public_ip_address = true
  user_data_base64            = filebase64("${path.module}/ec2-webpage.sh")
  vpc_security_group_ids      = [aws_security_group.EC2.id]

}

resource "aws_instance" "second_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet1.id
  associate_public_ip_address = true
  user_data_base64            = filebase64("${path.module}/ec2-webpage2.sh")
  vpc_security_group_ids      = [aws_security_group.EC2.id]
}