variable "k_connect_subnets" {
  type = "list"
}

variable "az_list"{
  type = "list"
}

variable "kafka_connect_ebs_vol_size" {
}

variable "kafka_connect_ebs_vol_type" {
}

variable "lounge_sg_id"{
}

variable "ready" {
}
variable "kready" {
}

resource "aws_s3_bucket" "kafka_connect_bucket" {
  bucket = "kafka-connect-bucket-pp"
  acl    = "bucket-owner-full-control"
  force_destroy = true

  tags {
    Name        = "kafka-connect-bucket"
  }
}

resource "aws_s3_bucket_policy" "kafka_connect_bucket_policy" {
  bucket = "${aws_s3_bucket.kafka_connect_bucket.id}"
  policy =<<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowList",
        "Effect": "Allow",
        "Principal": {
          "AWS": "<ARN predefined to allow Terraform to create everything>"
        },
        "Action": "s3:*",
        "Resource": [
            "arn:aws:s3:::kafka-connect-bucket-pp",
            "arn:aws:s3:::kafka-connect-bucket-pp/*"
        ]
      }
    ]
  }
  POLICY
}

resource "aws_launch_configuration" "kafka_connect_ASG_launch" {
  depends_on = ["aws_s3_bucket.kafka_connect_bucket","aws_s3_bucket_policy.kafka_connect_bucket_policy"]
  image_id      = "ami-bb9a6bc2"
  instance_type = "t2.micro"
  //depends_on = ["aws_ebs_volume.kafka_connect_ebs_AZ1","aws_ebs_volume.kafka_connect_ebs_AZ2","aws_ebs_volume.kafka_connect_ebs_AZ3"]
  security_groups = ["${var.lounge_sg_id}"]
  key_name          = "admin-key"

  lifecycle {
    create_before_destroy = true
  }
  /*
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = "${var.kafka_connect_ebs_vol_size}"
    volume_type = "${var.kafka_connect_ebs_vol_type}"
  }
  */
}

resource "aws_autoscaling_group" "kafka_connect_ASG" {
  vpc_zone_identifier		= ["${var.k_connect_subnets}"]
  name                      = "kafka_connect_ASG"
  max_size                  = 5
  min_size                  = 3
  health_check_grace_period = 300
  health_check_type			    = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.kafka_connect_ASG_launch.name}"
  tag {
    key                 = "Name"
    value               = "kafka_connect_ASG"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "kafka_connect_ASG_policy" {
  name                   = "kafka_connect_ASG_add_one_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.kafka_connect_ASG.name}"
}

resource "aws_cloudwatch_metric_alarm" "kafka_connect_ASG_alarm" {
  alarm_name          = "kafka_connect_ASG_70_cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.kafka_connect_ASG.name}"
  }

  alarm_description = "This metric monitors kafka connect ASG write operations"
  alarm_actions     = ["${aws_autoscaling_policy.kafka_connect_ASG_policy.arn}"]
}