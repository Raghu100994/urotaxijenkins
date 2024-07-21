terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "urotaxi-tfs-bucket"
    region = "ap-south-1"
    key = "terraform.tfstate"
    dynamodb_table = "urotaxi-tfs-lock"
  }
}

provider "aws" {
    region = "ap-south-1"
}

resource "aws_vpc" "urotaxivpc" {
  cidr_block = var.urotaxivpc_cidr
  tags = {
    Name = "urotaxivpc"
  }
}

resource "aws_subnet" "urotaxi_pubsn1" {
  vpc_id = aws_vpc.urotaxivpc.id
  cidr_block = var.urotaxi_pubsn1_cidr
  tags = {
    Name = "urotaxiPusn1"
  }
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "urotaxi_prvsn2" {
  vpc_id = aws_vpc.urotaxivpc.id
  cidr_block = var.urotaxi_prvsn2_cidr
  tags = {
    Name = "urotaxiPrvsn2"
  }
  availability_zone = "ap-south-1b"
}

resource "aws_subnet" "urotaxi_prvsn3" {
  vpc_id = aws_vpc.urotaxivpc.id
  cidr_block = var.urotaxi_prvsn3_cidr
  tags = {
    Name = "urotaxiPrvsn3"
  }
  availability_zone = "ap-south-1c"
}

resource "aws_internet_gateway" "urotaxiig" {
  vpc_id = aws_vpc.urotaxivpc.id
  tags = {
    Name = "urotaxiig" 
  }
}

resource "aws_route_table" "urotaxiigrt" {
  vpc_id = aws_vpc.urotaxivpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.urotaxiig.id
  }
  tags = {
    Name = "uriotaxiigrt"
  }
}

resource "aws_route_table_association" "uriotaxiigrtassociation" {
  route_table_id = aws_route_table.urotaxiigrt.id
  subnet_id = aws_subnet.urotaxi_pubsn1.id
}

resource "aws_security_group" "urotaxijavaserversg" {
  vpc_id = aws_vpc.urotaxivpc.id
  ingress {
    from_port = "8080"
    to_port = "8080"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "urotaxiJserversg"
  }
}

resource "aws_security_group" "urotaxidbsg" {
  vpc_id = aws_vpc.urotaxivpc.id
  ingress {
    from_port = "3306"
    to_port = "3306"
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "urotaxidbsg"
  }
}

resource "aws_db_subnet_group" "urotaxidbsngrp" {
  name = "urotaxidbsubnetgrp"
  subnet_ids = [aws_subnet.urotaxi_prvsn2.id, aws_subnet.urotaxi_prvsn3.id]
  tags = {
    Name = "urotaxidbsngroup"
  }
}

resource "aws_db_instance" "urotaxidb" {
  allocated_storage    = 10
  db_name              = var.db_name
  engine               = "mysql"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_type
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.urotaxidbsngrp.name
}

resource "aws_key_pair" "urotaxikp" {
  key_name = "urotaxikey"
  public_key = var.urotaxi_public_key
}

resource "aws_instance" "urotaxiec2" {
  vpc_security_group_ids = [aws_security_group.urotaxijavaserversg.id]
  subnet_id = aws_subnet.urotaxi_pubsn1.id
  ami = var.ami_id
  key_name = aws_key_pair.urotaxikp.key_name
  instance_type = var.instance_shape
  associate_public_ip_address = true
  tags = {
    Name = "urotaxiserver"
  }
}
