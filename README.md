# AWS ASG and ELB module

These types of resources are supported:

* [Launch Configuration](https://www.terraform.io/docs/providers/aws/r/launch_configuration.htmll)
* [Autoscaling Group](https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html)
* [Elastic Load Balancer](https://www.terraform.io/docs/providers/aws/r/elb.html)

## Terraform versions

Terraform 0.12.

## Usage

`asg`:
```hcl
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
```

`elb`:
```
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
```