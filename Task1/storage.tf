resource "aws_s3_bucket" "payroll_documents" {
  bucket = "payroll-documents-bucket-${random_string.suffix.result}"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.payroll_documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}