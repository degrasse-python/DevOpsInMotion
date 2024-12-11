variable "GCP_ACCESS_KEY_ID" {
  description = "The aws_access_key"
  type        = string
  default = "value"
  validation {
    condition = length(var.GCP_ACCESS_KEY_ID) > 10
    error_message = "The file must be more than 10 chars"
  }
}

variable "GCP_SECRET_ACCESS_KEY" {
  description = "The id aws_secret_key"
  type        = string
  default = "value"
  validation {
    condition = length(var.GCP_SECRET_ACCESS_KEY) > 10
    error_message = "The file must be more than 10 chars"
  }
}



variable "GOOGLE_CREDENTIALS" {
  description = "Path to the GCP credentials file in HCL format."
  type        = string
  default = "value"

}

