output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the web security group."
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID of the EC2 web server."
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP of the web server."
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "Where the site would be served."
  value       = "http://${aws_instance.web.public_ip}/"
}

output "assets_bucket" {
  description = "S3 bucket holding the site assets."
  value       = aws_s3_bucket.assets.bucket
}
