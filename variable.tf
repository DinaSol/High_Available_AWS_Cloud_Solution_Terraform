variable "region" {
  default = "eu-north-1"
}

variable "subnets" {
    type = map
    default = {
        eu-north-1a = "10.0.1.0/24"
        eu-north-1b = "10.0.2.0/24"
    }
}


