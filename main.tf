terraform {
  backend "s3" {
    bucket = "terrific-terraform-bucket"
    key    = "terraform.tfstate"
    region = "eu-west-2"

  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">=1.2.0"
}
provider "aws" {
  region = "eu-west-2"
}

resource "aws_ecrpublic_repository" "my_repository" {
  name = "bish-bash-bosh-repo"
  # Optional configurations
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_elastic_beanstalk_application" "bish_bash_bosh_app" {
  name        = "bish-bash-bosh-task-listing-app"
  description = "Task listing app"
}

resource "aws_elastic_beanstalk_environment" "bish_bash_bosh_app_environment" {
  name                = "bi-ba-bo-task-list-app-env"
  application         = aws_elastic_beanstalk_application.bish_bash_bosh_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.bish_bash_bosh_app_ec2_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "bish-bash-bosh"
  }
}

resource "aws_iam_role" "bish_bash_bosh_app_ec2_role" {
  name = "bish-bash-bosh-task-listing-app-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]

  })
}
resource "aws_s3_bucket" "docker_deploy_bucket" {
  bucket = "bish-bash-bucket"  # Replace "your_bucket_name" with your desired bucket name
  acl    = "private"            # Set ACL as per your requirement, e.g., "private", "public-read", etc.
}
# data "aws_s3_bucket_object" "dockerrun" {
#   bucket = aws_s3_bucket.elasticbeanstalk_bucket.bucket
#   key    = "path/to/Dockerrun.aws.json"
# }
resource "aws_iam_role_policy_attachment" "web_tier" {
  role       = aws_iam_role.bish_bash_bosh_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}
resource "aws_iam_role_policy_attachment" "multi_container_docker" {
  role       = aws_iam_role.bish_bash_bosh_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}
resource "aws_iam_role_policy_attachment" "worker_tier" {
  role       = aws_iam_role.bish_bash_bosh_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}
resource "aws_iam_role_policy_attachment" "example_app_ec2_role_policy_attachment" {
  role       = aws_iam_role.bish_bash_bosh_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_instance_profile" "bish_bash_bosh_app_ec2_instance_profile" {
  name = "bish-bash-bosh-task-listing-app-ec2-instance-profile"
  role = aws_iam_role.bish_bash_bosh_app_ec2_role.name
}


resource "aws_db_instance" "rds_app" {
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t3.micro"
  identifier           = "bishdbid"
  name                 = "bishdbname"
  username             = "thebosh"
  password             = "bishbashbosh"
  skip_final_snapshot  = true
  publicly_accessible = true
}