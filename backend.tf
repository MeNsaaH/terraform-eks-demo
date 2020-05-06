terraform {
  backend "s3" {
    bucket = "terraform-state-a99f81aafd36feface47"
    region = "us-east-2"
    key = "global/terrform.tfstate"

    dynamodb_table = ""
    encrypt = true
  }
 }
