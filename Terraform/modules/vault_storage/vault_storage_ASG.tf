variable "subnets" {
  type = "list"
}

variable "management_sg_id"{
}

variable "ready" {

}

resource "aws_launch_configuration" "vault_storage_ASG_launch" {
  image_id      = "ami-bb9a6bc2"
  instance_type = "t2.micro"
  security_groups = ["${var.management_sg_id}"]
  key_name        = "admin-key"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "vault_storage_ASG" {
  vpc_zone_identifier		= ["${var.subnets}"]
  name                      = "vault_storage_ASG"
  max_size                  = 5
  min_size                  = 3
  health_check_grace_period = 300
  health_check_type			= "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.vault_storage_ASG_launch.name}"
  tag {
    key                 = "Name"
    value               = "vault_storage_ASG"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "vault_storage_ASG_policy" {
  name                   = "vault_storage_ASG_add_one_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.vault_storage_ASG.name}"
}

resource "aws_cloudwatch_metric_alarm" "vault_storage_ASG_alarm" {
  alarm_name          = "vault_storage_ASG_80_cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.vault_storage_ASG.name}"
  }

  alarm_description = "This metric monitors vault storage ASG cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.vault_storage_ASG_policy.arn}"]
}
