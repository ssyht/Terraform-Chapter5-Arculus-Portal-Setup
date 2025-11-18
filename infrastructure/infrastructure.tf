terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ---------- VPC + SUBNET LOOKUP ----------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------- KEY PAIR ----------
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "arculus" {
  key_name   = "arculus-key-final-1"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_key" {
  filename = "${path.module}/arculus-key.pem"
  content  = tls_private_key.ssh.private_key_pem
}

# ---------- SECURITY GROUP ----------
resource "aws_security_group" "arculus" {
  name   = "arculus-final-sg-testing"
  vpc_id = data.aws_vpc.default.id

  # ----- HTTP / HTTPS -----
  ingress { 
    from_port = 80 
    to_port = 80 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  ingress { 
    from_port = 443 
    to_port = 443 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  # ----- UI Ports -----
  ingress { 
    from_port = 3000 
    to_port = 3000 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
    
  ingress { 
    from_port = 3003 
    to_port = 3003 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  # ----- Arculus Ports -----
  ingress { 
    from_port = 8440 
    to_port = 8440 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  ingress { 
    from_port = 8441 
    to_port = 8441 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  ingress { 
    from_port = 8442 
    to_port = 8442 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  ingress { 
    from_port = 8443 
    to_port = 8443 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  # ----- Kubernetes / Node Agent -----
  ingress { 
    from_port = 10250 
    to_port = 10250 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  # ----- Drone UDP Ports -----
  ingress { 
    from_port = 8285 
    to_port = 8285 
    protocol = "udp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  ingress { 
    from_port = 14550 
    to_port = 14558 
    protocol = "udp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  # ----- BGP (Seen in screenshot) -----
  ingress { 
    from_port = 179 
    to_port = 179 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  # ----- ALL TCP (because screenshot has this rule) -----
  ingress { 
    from_port = 0 
    to_port = 65535 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  # ----- ALL UDP (because screenshot has this rule) -----
  ingress { 
    from_port = 0 
    to_port = 65535 
    protocol = "udp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  # ----- SSH (CloudShell + global) -----
  ingress { 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    cidr_blocks = ["3.230.143.85/32"] 
    }

  ingress { 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  # ----- Outbound -----
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- EC2 INSTANCE ----------
resource "aws_instance" "arculus" {
  ami                         = "ami-06137137e85b40f89"
  instance_type               = "t2.medium"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.arculus.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.arculus.key_name

  tags = {
    Name = "arculus-final-instance"
  }
}

# ---------- OUTPUTS ----------
output "public_ip" {
  value = aws_instance.arculus.public_ip
}

output "key_path" {
  value = "${path.module}/arculus-key.pem"
}
