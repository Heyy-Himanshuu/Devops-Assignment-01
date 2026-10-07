# Bucket for nightly `pg_dump` backups of the SpendBoard database.
resource "aws_s3_bucket" "backups" {
  bucket        = "${var.project}-${var.environment}-db-backups"
  force_destroy = var.environment != "prod" # dev buckets may be torn down with their contents
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    id     = "expire-old-dumps"
    status = "Enabled"
    filter { prefix = "pg_dump/" }
    expiration { days = var.backup_retention_days }
    noncurrent_version_expiration { noncurrent_days = 7 }
  }
}

# Least-privilege role the in-cluster backup CronJob assumes (via IRSA on EKS):
# it may only write and list under pg_dump/ in this one bucket.
data "aws_iam_policy_document" "backup_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup_writer" {
  name               = "${var.project}-${var.environment}-backup-writer"
  assume_role_policy = data.aws_iam_policy_document.backup_trust.json
}

data "aws_iam_policy_document" "backup_write" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.backups.arn}/pg_dump/*"]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.backups.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["pg_dump/*"]
    }
  }
}

resource "aws_iam_role_policy" "backup_write" {
  name   = "write-pg-dumps"
  role   = aws_iam_role.backup_writer.id
  policy = data.aws_iam_policy_document.backup_write.json
}
