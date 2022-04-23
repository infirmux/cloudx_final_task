module "network" {
  source = "./network"
}

provider "aws" {
  region = module.network.region
}

#SUBNET GROUP
#resource "aws_db_subnet_group" "ghost" {
#  subnet_ids = [join(", ", module.network.cloudx_private_db_subnets_id)]
#}

#DB INSTANCE
#resource "aws_db_instance" "default" {
#  allocated_storage    = 20
#  engine               = "mysql"
#  engine_version       = "8.0"
#  storage_type         = "gp2"
#  instance_class       = "db.t2.micro"
#  db_name              = "ghost"
#  username             = "foo"
# password             = "foobarbaz"
#  parameter_group_name = "default.mysql5.7"
#  skip_final_snapshot  = true
#  security_group_names = [module.network.sg_mysql_name]
#  db_subnet_group_name = aws_db_subnet_group.ghost.name
#}

###SSH KEYPAIR


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
}

#resource "aws_iam_instance_profile" "cloudx_profile" {
#  name = "cloudx_profile"
#  role = aws_iam_role.cloudx_policy.name
#}

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
  }
}
#MOUNT TARGETS
resource "aws_efs_mount_target" "mount_ghost_a" {
  file_system_id = aws_efs_file_system.ghost_content.id
  subnet_id      = element(module.network.cloudx_private_subnets_id, 0)
  security_groups = [module.network.cloudx_sg_efs_id]
}

resource "aws_efs_mount_target" "moutn_ghost_b" {
  file_system_id = aws_efs_file_system.ghost_content.id
  subnet_id      = element(module.network.cloudx_private_subnets_id, 1)
  security_groups = [module.network.cloudx_sg_efs_id]
}

resource "aws_efs_mount_target" "mount_ghost_c" {
  file_system_id = aws_efs_file_system.ghost_content.id
  subnet_id      = element(module.network.cloudx_private_subnets_id, 2)
  security_groups = [module.network.cloudx_sg_efs_id]
}

