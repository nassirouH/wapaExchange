variable "name" { type = string }

resource "aws_kms_key" "kyc" {
  description             = "${var.name} KYC documents at rest"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "kyc" {
  name          = "alias/${var.name}-kyc"
  target_key_id = aws_kms_key.kyc.key_id
}

resource "aws_s3_bucket" "kyc" {
  bucket = "${var.name}-kyc-docs"
}

resource "aws_s3_bucket_versioning" "kyc" {
  bucket = aws_s3_bucket.kyc.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "kyc" {
  bucket                  = aws_s3_bucket.kyc.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kyc" {
  bucket = aws_s3_bucket.kyc.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.kyc.arn
    }
  }
}

# 7-year retention (AML legal hold). Use lifecycle, not deletion blocking.
resource "aws_s3_bucket_lifecycle_configuration" "kyc" {
  bucket = aws_s3_bucket.kyc.id

  rule {
    id     = "aml-7y-retention"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 2555 # 7 years
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

output "bucket_name" { value = aws_s3_bucket.kyc.id }
output "bucket_arn"  { value = aws_s3_bucket.kyc.arn }
output "kms_key_arn" { value = aws_kms_key.kyc.arn }
