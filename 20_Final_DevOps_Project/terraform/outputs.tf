output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

output "backup_bucket" {
  value = aws_s3_bucket.backups.bucket
}

output "backup_writer_role_arn" {
  value = aws_iam_role.backup_writer.arn
}

output "eks_cluster_name" {
  value = var.enable_eks ? aws_eks_cluster.main[0].name : "(EKS disabled - LocalStack community does not emulate it)"
}
