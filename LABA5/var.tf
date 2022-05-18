variable "vpc-cidr" {
  default = "10.0.0.0/16"
}

#--------Public Subnet-----------

variable "public-subnet-cidrs" {
  default = [
    "10.0.11.0/24",
    "10.0.21.0/24"
  ]
}

#--------Private Subnet------------

variable "private-subnet-cidrs" {
  default = [
    "10.0.12.0/24",
    "10.0.22.0/24"
  ]
}

#---------Database Subnet------------

variable "database-subnet-cidrs" {
  default = [
    "10.0.13.0/24",
    "10.0.23.0/24"
  ]
}
