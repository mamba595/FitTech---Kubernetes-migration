variable "vpc_cidr" {
    type = string
}

variable "public_count" {
    type = number
}

variable "private_count" {
    type = number
}

variable "db_name" {
    type = string
}

variable "db_username" {
    type = string
}

variable "db_password" {
    type = string
}

variable "image" {
    type = string
}

variable "secret_key" {
    type = string
}

variable "algorithm" {
    type = string
}

variable "access_token_expire_minutes" {
    type = string
}