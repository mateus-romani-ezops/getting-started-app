output "lb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "Public DNS of the ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "Default target group ARN (frontend)"
}

output "listener_arn" {
  value       = aws_lb_listener.http.arn
  description = "HTTP listener ARN (port 80)"
}

output "security_group_id" {
  value       = var.lb_sg_id
  description = "Security group ID attached to the ALB"
}