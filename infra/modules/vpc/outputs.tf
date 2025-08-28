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
  value = "postgresql+psycopg2://${var.db_username}:${var.db_password}@${aws_db_instance.postgres_db.address}:${aws_db_instance.postgres_db.port}/${var.db_name}"
  sensitive = true
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}