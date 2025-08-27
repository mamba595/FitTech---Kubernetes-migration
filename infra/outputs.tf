output "vpc_id" {
    value = module.vpc.vpc_id
}

output "public_subnet_ids" {
    value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
    value = module.vpc.private_subnet_ids
}

output "db_url" {
    value = module.vpc.db_url
    sensitive = true
}

output "cluster_name" {
    value = module.vpc.cluster_name
}