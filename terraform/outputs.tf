output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.app.public_dns
}

output "app_url" {
  description = "URL to access the application (HTTP)"
  value       = "http://${aws_instance.app.public_ip}"
}

output "ssh_command" {
  description = "Example SSH command to access the instance"
  value       = "ssh -i /path/to/your/key.pem ubuntu@${aws_instance.app.public_ip}"
}
