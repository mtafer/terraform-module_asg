output "this_launch_configuration_id" {
  description = "The ID of the launch configuration"
  value       = aws_autoscaling_group.this.id
}
