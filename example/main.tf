terraform {
  required_version = ">= 0.12"

  backend "s3" {
    key          = "state-file-commodoties-testing"
    session_name = "commodoties-testing-deployment"
  }
}

provider "aws" {
  region = "${var.region}"
}

module "iam_role" {
  source = "git::https://git.sami.int.thomsonreuters.com/cloud-service-catalog/aws-tf-iam-roles.git?ref=v1.0.0"

  iam_role_name        = "a206256-instance-role-commodoties-testing"
  iam_role_description = "a206256-instance-role-commodoties-testing"
  # iam_role_path           = "/service-role/"
  iam_policy_name         = "a206256-policy-commodoties-testing"
  iam_policy_description  = "a206256-policy-commodoties-testing"
  assume_role_policy_file = "example/assume-policy.json.tpl"
  role_policy_file        = "example/policy.json.tpl"
  tags                    = var.tags
}

resource "aws_iam_instance_profile" "this" {
  name = "a206256-instance-profile-commodoties-testing"
  role = "${module.iam_role.role_name}"
}

module "sg" {
  source = "git::https://git.sami.int.thomsonreuters.com/cloud-service-catalog/aws-tf-securitygroups.git?ref=v1.0.0"

  name        = "a206256-sg-commodoties-testing"
  description = "a206256-sg-commodoties-testing"
  vpc_id      = "vpc-0e21d88ce6980772d"
  tags        = var.tags
}


module "asg" {
  source = "../asg"
  # source = "git::https://git.sami.int.thomsonreuters.com/cloud-service-catalog/aws-tf-autoscaling.git//asg?ref=v1.0.0"

  name = "a206256-asg-commodoties-testing"

  # Lanch Configuration
  image_id             = "ami-016a6972aad802caf"
  instance_type        = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.this.name}"
  security_groups      = ["${module.sg.this_security_group_vpc_id}"]
  load_balancers       = ["${module.elb.this_elb_id}"]
  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "10"
      delete_on_termination = "true"
    },
  ]
  root_block_device = [
    {
      volume_size           = "10"
      volume_type           = "gp2"
      delete_on_termination = "true"
    },
  ]
  vpc_zone_identifier = "${var.subnets}"

  # Autoscaling
  health_check_type         = "ELB"
  min_size                  = 3
  max_size                  = 3
  desired_capacity          = 3
  wait_for_capacity_timeout = 0
  # service_linked_role_arn   = "${aws_iam_service_linked_role.autoscaling.arn}"

  tags = [
    {
      key                 = "tr:application-asset-insight-id"
      value               = "206256"
      propagate_at_launch = "true"
    },
    {
      key                 = "tr:testing"
      value               = "true"
      propagate_at_launch = "true"
    },
  ]
}

module "elb" {
  source = "../elb"
  # source = "git::https://git.sami.int.thomsonreuters.com/cloud-service-catalog/aws-tf-autoscaling.git//elb?ref=v1.0.0"

  name            = "a206256-elb-commodoties-testing"
  subnets         = var.subnets
  security_groups = ["${module.sg.this_security_group_vpc_id}"]
  internal        = "false"

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "http"
      lb_port           = "80"
      lb_protocol       = "http"
    },
    # {
    #   instance_port     = "483"
    #   instance_protocol = "https"
    #   lb_port           = "483"
    #   lb_protocol       = "https"
    #   ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
    # },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = merge(
    var.tags,
    {
      "Name" = "a206256-elb-commodoties-testing"
    },
  )
}

