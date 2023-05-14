
# create an instance template that will be used by ASG
resource "aws_launch_template" "myapp" {
  name = "myapp"
  description = "My Launch Template"
  block_device_mappings {
    device_name = "/dev/sdf"
    ebs {
      volume_size = 20
      delete_on_termination = true
    }
  }
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.allow_http.id]
  }

  # instance IAM role
  iam_instance_profile {
    name = "S3DynamoDBFullAccessRole"
  }

  image_id = "ami-0577c11149d377ab7"
  instance_type = "t3.micro"
#   vpc_security_group_ids = [aws_security_group.allow_http.id]
  update_default_version = true
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "test"
    }
  }
  #  add the "web.sh" script that the instance will execute during the boot
 user_data     = "${filebase64("web.sh")}"

 depends_on = [
   aws_security_group.allow_http,
   aws_vpc.mainVPC,
   aws_subnet.subnet
 ]

}

# LB target group will be associated to the ASG
resource "aws_lb_target_group" "app-tg" {
  name     = "app-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mainVPC.id

  depends_on = [
    aws_vpc.mainVPC
  ]
}

# create autoscaling group within 2 desired instance , max=4, min=2
resource "aws_autoscaling_group" "ASG" {
#   availability_zones = ["eu-north-1a" , "eu-north-1b"]
  desired_capacity   = 2
  max_size           = 4
  min_size           = 2

  health_check_grace_period = 300
  vpc_zone_identifier = [for subnet in aws_subnet.subnet : subnet.id]

  # create instances from this AMI Template
  launch_template {
    id      = aws_launch_template.myapp.id
    version = "$Latest"
  }
  # the LB will distribute traffic on these ASG instances
  target_group_arns = [aws_lb_target_group.app-tg.arn]


  enabled_metrics = [ 
    "GroupMinSize",
    "GroupMaxSize",
    "GroupTotalCapacity",
    "GroupDesiredCapacity"
    
   ]
  depends_on = [
    aws_launch_template.myapp
  ]
}

# define what the Auto Scaling does when the metric become over the defined threshold 
resource "aws_autoscaling_policy" "scaleup-policy" {
  name                   = "ASG policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ASG.name
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.ASG.name
  lb_target_group_arn    = aws_lb_target_group.app-tg.arn  
  depends_on = [
    aws_lb.alb
  ]
}


# use cloud watch metrics to track the CPU utilization of ASG instances 
resource "aws_cloudwatch_metric_alarm" "cloudWatch" {

  # add more instance when CPU >= 80 
  alarm_name                = "CPU > 80"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "This metric monitors ec2 cpu utilization"
  dimensions = {
   AutoScalingGroupName = aws_autoscaling_group.ASG.name
  }
  actions_enabled = true
  alarm_actions = [ aws_autoscaling_policy.scaleup-policy.arn ]
}



