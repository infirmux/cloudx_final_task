module "network" {
  source = "./network"
}

provider "aws" {
  region = module.network.region
}

#SUBNET GROUP

resource "aws_ssm_parameter" "secret" {
  name        = "/ghost/dbpassw"
  description = "ghost DB pass"
  type        = "SecureString"
  value       = var.database_pass

  tags = {
    Project = "cloudx_final_task"
  }
}

resource "aws_db_subnet_group" "ghost" {
  name = "ghost_db_subnet_group"
  subnet_ids = [for s in module.network.cloudx_private_db_subnets_id: s]
  tags = {
    Project = "cloudx_final_task"
  }
}

#DB INSTANCE
resource "aws_db_instance" "ghost" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.16"
  instance_class       = "db.t2.micro"
  db_name              = "gh_db"
  username             = "gh_user"
  password             = var.database_pass
  db_subnet_group_name = aws_db_subnet_group.ghost.id
  vpc_security_group_ids = [module.network.sg_mysql_vpc_id]
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
  depends_on = [module.network.sg_mysql_vpc_id]
}

#resource "aws_db_instance" "default" {
#  allocated_storage    = 20
#  engine               = "mysql"
# engine_version       = "8.0"
#  storage_type         = "gp2"
#  instance_class       = "db.t2.micro"
#  db_name              = "ghost"
#  username             = "foo"
#  password             = "foobarbaz"
#  parameter_group_name = "default.mysql8.0"
#  skip_final_snapshot  = true
#  security_group_names = [module.network.sg_mysql_name]
#  db_subnet_group_name = aws_db_subnet_group.ghost.name
#}

###SSH KEYPAIR
#
#
#
#
#
#
#

###IAM
#POLICY
resource "aws_iam_policy" "ghost_app_policy" {
  name        = "cloudx_policy"
  path        = "/"
  description = "My test policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "ec2:Describe",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ssm:GetParameter*",
            "secretsmanager:GetSecretValue",
            "kms:Decrypt",
            "elasticfilesystem:DescribeFileSystems",
            "elasticfilesystem:ClientMount",
            "elasticfilesystem:ClientWrite"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
  tags = {
    Project = "cloudx_final_task"
  }
}

###IAM
#ROLE
resource "aws_iam_role" "cloudx_policy" {
  name = "cloudx_role"

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
  tags = {
    Project = "cloudx_final_task"
  }
}

resource "aws_iam_instance_profile" "cloudx_profile" {
  name = "cloudx_profile"
  role = aws_iam_role.cloudx_policy.name
  tags = {
    Project = "cloudx_final_task"
  }
}

resource "aws_iam_role_policy" "cloudx_role_policy" {
  name = "cloudx_role_policy"
  role = aws_iam_role.cloudx_policy.id
  policy = aws_iam_policy.ghost_app_policy.policy
}

###EFS
resource "aws_efs_file_system" "ghost_content" {
  creation_token = "ghost_content"
  tags = {
    Name = "ghost_content"
    Project = "cloudx_final_task"
  }
}
#MOUNT TARGETS
resource "aws_efs_mount_target" "mount_ghost_a" {
  count = length(module.network.cloudx_private_subnets_id)
  file_system_id = aws_efs_file_system.ghost_content.id
  subnet_id      = element(module.network.cloudx_private_subnets_id, count.index)
  security_groups = [module.network.cloudx_sg_efs_id]
}

####ALB
#TARGET GROUPS
resource "aws_lb" "cloudx_alb" {
  name               = "cloudxalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.network.cloudx_sg_alb_id]
  subnets            = [for s in module.network.cloudx_public_subnets_id: s]
}

resource "aws_lb_target_group" "ghost-ec2" {
  name     = "ghost-ec2"
  port     = 2368
  protocol = "HTTP"
  vpc_id   = module.network.cloudx_vpc_id
}

resource "aws_lb_target_group" "ghost-fargate" {
  name     = "ghost-fargate"
  port     = 2368
  protocol = "HTTP"
  vpc_id   = module.network.cloudx_vpc_id
}


resource "aws_lb_listener" "cloudx_lb_listener" {
  load_balancer_arn = aws_lb.cloudx_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.ghost-ec2.arn
        weight = 100
      }

      target_group {
        arn    = aws_lb_target_group.ghost-fargate.arn
        weight = 0
      }
   }
 }
}
###LAUNC TEMPLATE
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "ghost" {
  name = "ghost"

  iam_instance_profile {
    name = "cloudx_profile"
  }

  image_id = data.aws_ami.latest_amazon_linux.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t2.micro"

  key_name  = "333"

  vpc_security_group_ids = [module.network.cloudx_sg_ec2pool_id]

  user_data = filebase64("userdata.sh")
}

###AUTO-SCALING

resource "aws_autoscaling_group" "ghost_ec2_pool" {
  name                      = "ghost_ec2_pool"
  max_size                  = 3
  min_size                  = 3
  vpc_zone_identifier       = [for s in module.network.cloudx_private_subnets_id: s]
  
  launch_template {
    id      = aws_launch_template.ghost.id
    version = "$Latest"
  }

 # initial_lifecycle_hook {
 #   name                 = "ghost_ec2_pool"
 #   default_result       = "CONTINUE"
 #   heartbeat_timeout    = 2000
 #   lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
 # }

}


###ECS
#resource "aws_ecs_cluster" "ghost" {
#  name = "ghost"
#
#  setting {
#    name  = "containerInsights"
#    value = "enabled"
#  }
#}
#ECR
#resource "aws_ecr_repository" "gost_repo" {
#  name                 = "gost_repo"
#  image_tag_mutability = "MUTABLE"
#
#  image_scanning_configuration {
#    scan_on_push = true
#  }
#}