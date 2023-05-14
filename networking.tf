resource "aws_vpc" "mainVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main"
  }
}

# add IGW so the ALB can work
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mainVPC.id
  tags = {
    Name = "IGW"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.mainVPC.id

  # create 2 subnets in different AZs
  for_each = var.subnets
  cidr_block = each.value
  availability_zone = each.key

}


resource "aws_route_table" "public-RT" {
  vpc_id = aws_vpc.mainVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-RT"
  }
}


# associate the route table to the subnet "dina-public-subnet"

resource "aws_route_table_association" "RT_assoc1" {

  subnet_id =  aws_subnet.subnet["eu-north-1a"].id 
  route_table_id = aws_route_table.public-RT.id
}

resource "aws_route_table_association" "RT_assoc2" {

  subnet_id =  aws_subnet.subnet["eu-north-1b"].id 
  route_table_id = aws_route_table.public-RT.id
}

# add SG to instances
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow  HTTP  inbound traffic"
  vpc_id      = aws_vpc.mainVPC.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow http"
  }
}

# create an Application Loadbalancer for the previous subnets
resource "aws_lb" "alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [for subnet in aws_subnet.subnet : subnet.id]

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-tg.arn # forward traffic to the ASG
  }
  depends_on = [
    aws_lb_target_group.app-tg
  ]
}

