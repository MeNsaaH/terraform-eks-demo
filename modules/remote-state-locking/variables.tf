variable "region" {
  description = "Region of for remote state bucket"
}

variable "bucket_key" {
  description = "The Key to store bucket in"
  default     = "global/terrform.tfstate"
}

variable "bucket_name" {
  description = "Name of bucket"
  default     = ""
}

variable "dynamo_lock_name" {
  description = "Name of bucket"
  default     = ""
}

variable "use_lock" {
  description = "Whether to enable locking using dynamo_db"
  default     = true
  type        = bool
}

variable "force_destroy" {
  default     = false
  type        = bool
  description = "Whether to allow a forceful destruction of this bucket"
}

variable "enable_versioning" {
  default     = true
  description = "enables versioning for objects in the S3 bucket"
  type        = bool
}

variable "backend_output_path" {
  default     = "./backend.tf"
  description = "The default file to output backend configuration to"
}

