provider "aws" {
  region = "us-east-1"
  access_key= "AKIA56BBH7Q4QXG34IB5"
  secret_key= "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"
  
  
}

variable vpc_cidr_block {}
variable subnet_1_cidr_block {}
variable env_prefix {}
variable avail_zone {}
variable my_ip {}
variable instance_type {}




data "aws_ami" "amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "ami_id" {
  value = data.aws_ami.amazon-linux-image.id
}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
      Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_1_cidr_block
  availability_zone = var.avail_zone
  tags = {
      Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
        vpc_id = aws_vpc.myapp-vpc.id

    tags = {
     Name = "${var.env_prefix}-internet-gateway"
   }
}

/*resource "aws_route_table" "myapp-route-table" {
   vpc_id = aws_vpc.myapp-vpc.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.myapp-igw.id
   }

   tags = {
     Name = "${var.env_prefix}-route-table"
   }
 } */

 resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
}



resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}


resource "aws_key_pair" "ssh-key" {
  key_name   = "myapp-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDE6VBBOhxQKGXIt4efYQ1KvPT5R901DhH6qcMD9NIkbZqxOt1QBrmaEGFFKODscb7+ZUdnNi14iProm1BcMqYix+VdIolwEuf/2w7rYxIb2pxiK/+5IjfzDvD/g6/azCJOOBwdERztf37i2tUxQ58f5dfSAjttZaURrjawF6jWdJUVmI8WXwJf38vor/kJ1Qu4euAaM4NOfFp8QxuG1mTL9oM9NKaVHDVqd+cwmTpAmf8cMvmgm7dY0InuNW0ovAjfyTB3I3BczHd44ru1w1/9zcP9lFGa2JApopUZOtzI/6vk8aauvSBQ5UbN7HWZwdUJ53QL0mIAjb18o/YhzY+pIs5HJbv2LP5ssk0iY0d6brg1GZLJqFlNv+106YybHhAjUiU5uTtb7T2m6SvhWAcbR+u4zBY1Eig9SxEM4pp3XRb6GqsHh0qcdVmmt/b5rAy1/wg3Ffgowt+zJ4cwl2CsUtYoh1dOslz6DPTxsnj+dxY/j0HNg+VOimH6Vh7TDk0= ubuntu@ip-172-31-30-188"
}

output "server-ip" {
    value = aws_instance.myapp-server.public_ip
}

resource "aws_instance" "myapp-server" {
  ami                         = data.aws_ami.amazon-linux-image.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh-key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids      = [aws_default_security_group.default-sg.id]
  availability_zone                           = var.avail_zone


user_data = file("entrypoint.sh")

  tags = {
    Name = "${var.env_prefix}-server"
  }

}
