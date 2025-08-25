variable "region" { 
    type    = string 
    default = "us-east-1"
}

variable "vpc_cidr" {
    type    = string
    default = "10.0.0.0/16"
}

variable "public_count" {
    type    = number
    default = 2
}

variable "private_count" {
    type    = number
    default = 2
}

variable "db_name" {
    type = string
}

variable "db_username" {
    type = string
}

variable "db_password" {
    type = string
    sensitive = true
}

variable "image" {
    type = string
    sensitive = true
}

variable "secret_key" {
    type = string
    sensitive = true
}

variable "algorithm" {
    type = string
    sensitive = true
}

variable "access_token_expire_minutes" {
    type = string
    sensitive = true
}