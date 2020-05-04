terraform {
  backend "s3" {
    bucket = "terraform-state-035388670db775f438cf"
    region = "us-east-2"
    key = "global/terrform.tfstate"

    dynamodb_table = ""
    encrypt = true
  }
 }
