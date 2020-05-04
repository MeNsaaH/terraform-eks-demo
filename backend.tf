terraform {
  backend "s3" {
    bucket = "terraform-state-65575d9d349f04d7c9b7"
    region = "us-east-2"
    key = "global/terrform.tfstate"

    dynamodb_table = ""
    encrypt = true
  }
 }
