variable "aws_region" {
  default = "us-east-2"
}

variable "amis" {
  type = map(string)
  default = {
    us-east-2 = "ami-05b04a28f20f54601"
  }
}

variable "vpc-subnet-cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "The VPC Subnet CIDR"
}

variable "private-subnet-cidr" {
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  type        = list
  description = "Private Subnet CIDR"
}

variable "public-subnet-cidr" {
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  type        = list
  description = "Public Subnet CIDR"
}
