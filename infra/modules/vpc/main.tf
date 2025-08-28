data "aws_availability_zones" "available" {}

resource "aws_vpc" "my_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "my_vpc"
    }
}

resource "aws_subnet" "public" {
    count = var.public_count
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
    tags = {
        Name = "public-${count.index}"
        "kubernetes.io/cluster/eks-cluster" = "owned"
        "kubernetes.io/role/elb" = "1"
    }
}

resource "aws_subnet" "private" {
    count             = var.private_count
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + var.public_count)
    availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
    tags = {
        Name = "private-${count.index}"
        "kubernetes.io/cluster/eks-cluster" = "owned"
        "kubernetes.io/role/internal-elb" = "1"
    }
}

resource "aws_internet_gateway" "IG" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "vpc-igw"
    }
}

resource "aws_eip" "nat" {
    count = var.public_count
    domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
    count         = var.public_count
    allocation_id = aws_eip.nat[count.index].id
    subnet_id     = aws_subnet.public[count.index].id
}

resource "aws_route_table" "private_route_table" {
    count = var.private_count
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.ngw[count.index].id
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IG.id
    }
}

resource "aws_route_table_association" "private_associations" {
    count          = var.private_count
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private_route_table[count.index].id
}

resource "aws_route_table_association" "public_associations" {
    count          = var.public_count
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "rds_sg" {
    name   = "rds-sg"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        cidr_blocks = aws_subnet.private[*].cidr_block
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = aws_subnet.private[*].cidr_block
    }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
    name = "rds-subnet-group"
    subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "postgres_db" {
    identifier        = "postgres-db"
    engine            = "postgres"
    engine_version    = "15.13"
    instance_class    = "db.t3.micro"
    allocated_storage = 20

    db_name  = var.db_name
    username = var.db_username
    password = var.db_password

    db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
    vpc_security_group_ids = [aws_security_group.rds_sg.id]

    publicly_accessible = false
    multi_az            = false
    skip_final_snapshot = true
}

resource "aws_eks_cluster" "eks_cluster" {
    name     = "eks-cluster"
    role_arn = aws_iam_role.eks_cluster_role.arn

    vpc_config {
        subnet_ids = aws_subnet.private[*].id
    }

    version = "1.30"
    enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

resource "aws_iam_role" "eks_cluster_role" {
    name = "eks-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action = "sts:AssumeRole"
            Principal = { Service = "eks.amazonaws.com" }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_node_group" "default" {
    cluster_name    = aws_eks_cluster.eks_cluster.name
    node_group_name = "default"
    node_role_arn   = aws_iam_role.eks_nodes.arn
    subnet_ids      = aws_subnet.private[*].id

    scaling_config {
        desired_size = 2
        max_size     = 3
        min_size     = 1
    }

    instance_types = ["t3.micro"]
    disk_size      = 20

    ami_type       = "AL2_x86_64"
}


resource "aws_iam_role" "eks_nodes" {
    name = "eks-nodes"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement =[{
            Effect = "Allow"
            Action = "sts:AssumeRole"
            Principal = { Service = "ec2.amazonaws.com" }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKSWorkerNodePolicy" {
    role       = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKS_CNI_Policy" {
    role       = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEC2ContainerRegistryReadOnly" {
    role       = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_cloudwatch_logging" {
    role       = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}