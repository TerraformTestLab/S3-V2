# use terraform providers aws, null and random to create an s3 bucket
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region
}

resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.bucket_name}-${random_id.bucket_id.hex}"
  tags = {
    Name      = "${var.bucket_name}-${random_id.bucket_id.hex}"
    canDelete = "true"
    updatedAt = timestamp()
  }
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_acl" "main" {
  depends_on = [aws_s3_bucket_ownership_controls.main]
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "null_resource" "hello" {
  triggers = {
    bucket_id = random_id.bucket_id.hex
  }

  provisioner "local-exec" {
    command = "echo ${aws_s3_bucket.main.bucket_domain_name}"
  }
}