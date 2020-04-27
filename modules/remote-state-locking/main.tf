resource "random_id" "this" {
  byte_length = "10"
}

##### Locals
locals {
  bucket_name      = var.bucket_name != "" ? var.bucket_name : "terraform-state-${random_id.this.hex}"
  dynamo_lock_name = var.dynamo_lock_name != "" ? var.dynamo_lock_name : "dynamo-db-lock-${random_id.this.hex}"
}

################# CREATING THE REMOTE S3 BUCKET
resource "aws_s3_bucket" "remote_state" {
  bucket        = local.bucket_name
  acl           = "private"
  region        = var.region
  force_destroy = var.force_destroy

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning {
    enabled = var.enable_versioning
  }
}

################# CREATING THE DYNAMODB STATE LOCK  #######
resource "aws_dynamodb_table" "terraform_locks" {
  count        = var.use_lock ? 1 : 0
  name         = local.dynamo_lock_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}


################# AUTOMATING REMOTE STATE LOCKING
data "template_file" "remote_state" {
  template = "${file("${path.module}/templates/remote_state.tpl")}"
  vars = {
    remote_state_bucket = local.bucket_name
    bucket_region       = var.region
    bucket_key          = var.bucket_key
  }
}

resource "null_resource" "remote_state_locks" {
  depends_on = [aws_dynamodb_table.terraform_locks, aws_s3_bucket.remote_state]
  provisioner "local-exec" {
    command = "sleep 20;cat > ${var.backend_output_path}<<EOL\n${data.template_file.remote_state.rendered}"
  }
}
