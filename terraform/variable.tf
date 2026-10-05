variable "region" {
  default = "ap-south-1"
}

variable "my_ip_cidr" {
  description = "Your public IP with /32, example 1.2.3.4/32"
  type        = string
}