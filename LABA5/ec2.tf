data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#-------------------------------------------------------------

resource "aws_security_group" "web" {
  name   = "Dynamic Sequrity Group"
  vpc_id = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = ["80", "443", "22"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Dynamic Sequrity Group"
    Owner = "Yura Korabel"
  }
}


resource "aws_launch_configuration" "web" {
  name = "WebServer-Highly-Available-LC"
  # name_prefix     = "WebServer-Highly-Available-LC-"
  image_id        = data.aws_ami.latest_amazon_linux.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web.id]
  user_data       = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "web" {
  name                 = "ASG-${aws_launch_configuration.web.name}"
  max_size             = 2
  min_size             = 2
  min_elb_capacity     = 2
  launch_configuration = aws_launch_configuration.web.name
  vpc_zone_identifier = [
    aws_subnet.public-subnets[0].id,
    aws_subnet.public-subnets[1].id
  ]

  load_balancers    = [aws_elb.web.name]
  health_check_type = "ELB"

  dynamic "tag" {
    for_each = {
      Name   = "WebServer-in-ASG"
      Owner  = "Yura Korabel"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}


resource "aws_elb" "web" {
  name               = "WebServer-Highly-Available-ELB"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups    = [aws_security_group.web.id]
  subnets = [
    aws_subnet.public-subnets[0].id,
    aws_subnet.public-subnets[1].id
  ]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 5
  }

  tags = {
    Name = "WebServer-Highly-Available-ELB"
  }
}
