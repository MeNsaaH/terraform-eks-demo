terraform {
  backend "s3" {
    bucket = "manasseh-tf-state"
    key    = "development/trials.tfstate"
    region = "us-east-2"
  }
}
