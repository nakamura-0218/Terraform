provider "aws" {
  region = "us-east-2"  
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

resource "aws_launch_template" "example" {
  image_id = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
  #!/bin/bash
  echo "Hello, World" > index.html
  nohup busybox httpd -f -p ${var.server_port} &
  EOF

# Autoscaling Groupがあるlaunch templateを使った場合に必須
lifecycle {
  create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_autoscaling_group" "example" {
  min_size = 2
  max_size = 10

  launch_template {
    id = aws_launch_template.example
  }
  vpc_zone_identifier = data.aws_subnets.default.ids

tag {
  key = "name"
  value = "terraform-asg-example"
  propagate_at_launch = true
  }
}

resource "aws_security_group" "instance"{
  name = "terraform-example-instance"
  
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}