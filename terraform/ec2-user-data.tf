provider "aws" {
  region = "eu-west-3"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name = "master-ec2-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "master-ec2"
  }
}

resource "aws_iam_instance_profile" "ssm" {
  name = "ssm"
  role = aws_iam_role.ssm.name
}

resource "aws_iam_role" "ssm" {
  name = "ssm_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_key_pair" "student" {
  key_name   = "student"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCz2R7B74v9XjZ8QBIK3vlmiEwE7D3s750IGsdoEE1WyzErqSD0pau8tVLcct6o/IP8F9irD5vTsbgfbBR7h3Tcchr+sBUgIIIPRJw2Xvfb0XdYVSnHgG1UdLVGjuSmaRgMkxdy0BndRE6noxMSM764tpbmJmXDQSK7VwwFzfmgm/h40nPN6ERd3vHz1VmQflh93+nS+88dZl3cYlIbMQY9nAXQ0BNpTcW4NEnw6+snNx+POkC9SGqDuMPA9Irb0N2JRUYCy0yfA9yawycw+81r1gT3aPZ44vFXkyC6s8DxxB/4EpsJ1uEaMOFydqpXlRXJpLvQ65FH89BZQainNAXd4QP0173hObsIicNze2v3kpM7SUHh8zfrTFbUJMrKd3Lz6HLWaZhifdAGfEjosPevKNCLzAsgBZHC2gbyaPvL6KpBDERs+y3FQr0ki3i4q5YwlIBmlRnjlSdSJr+r+ch96y+CK6Ojk0sZikiXlzpTX1SillcLzg2kVmkolUe63sk= student"
}

resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}