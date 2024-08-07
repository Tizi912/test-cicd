provider "aws" {
  region = "eu-central-1" # Replace with your desired AWS region
}

# Define a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Define a subnet within the VPC
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a" # Change as needed
  map_public_ip_on_launch = true
  tags = {
    Name = "main-subnet"
  }
}

# Define an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-internet-gateway"
  }
}

# Define a route table with a route to the Internet Gateway
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Define a security group
resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh_"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define an EC2 instance
resource "aws_instance" "my_instance" {
  ami                    = "ami-013efd7d9f40467af" # Replace with your AMI ID
  instance_type          = "t2.micro"
  key_name               = "test" # Replace with your key pair name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "MyEC2Instance"
  }

  user_data = file("userdata.sh")
}

resource "aws_ecr_repository" "my_repository" {
  name                 = "cicd-repo" # Replace with your desired repository name
  image_tag_mutability = "MUTABLE"   # Options: MUTABLE or IMMUTABLE
  lifecycle {
    prevent_destroy = true # Optional: Prevents accidental deletion
  }
}

#docker pull my-dockerhub-username/my-ml-model:latest
#docker run -d -p 80:80 my-dockerhub-username/my-ml-model:latest

output "instance_public_ip" {
  value = aws_instance.my_instance.public_ip
}


