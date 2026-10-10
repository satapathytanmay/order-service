provider "aws" {
  region = var.region
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# resource "aws_key_pair" "orders" {
#   key_name   = "orders-key"
#   public_key = file(pathexpand("~/.ssh/orders-key.pub"))
# }

resource "aws_security_group" "orders" {
  name        = "orders-sg"
  description = "SSH from my IP, app port open"

  # ingress {
  #   description = "SSH"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = [var.my_ip_cidr]
  # }

  ingress {
    description = "App"
    from_port   = 8080
    to_port     = 8080
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

resource "aws_instance" "orders" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  # key_name               = aws_key_pair.orders.key_name
  vpc_security_group_ids = [aws_security_group.orders.id]
  iam_instance_profile = aws_iam_instance_profile.ssm.name

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOF

  tags = {
    Name = "orders-service"
  }
}

resource "aws_iam_role" "ssm" {
  name = "orders-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "orders-ec2-ssm-profile"
  role = aws_iam_role.ssm.name
}