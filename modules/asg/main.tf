data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 (SSM + CloudWatch)
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Launch Template
resource "aws_launch_template" "this" {
  name          = "${var.project_name}-${var.environment}-lt"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = "lin-test"

  vpc_security_group_ids = [var.instance_sg_id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(templatefile("${path.module}/../../scripts/user-data.sh.tpl", {
    container_image = var.container_image
    container_port  = var.container_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-${var.environment}-volume"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                = "${var.project_name}-${var.environment}-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.public_subnet_ids
  target_group_arns   = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 120

  # Required for reusing ASG name
  force_delete = true

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = true
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "asg_name" {
  value = aws_autoscaling_group.this.name
}

output "launch_template_id" {
  value = aws_launch_template.this.id
}
