output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "db_url" {
  value = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres_db.endpoint}/${var.db_name}"
  sensitive = true
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}