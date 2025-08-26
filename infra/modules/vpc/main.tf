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
    }
}

resource "aws_subnet" "private" {
    count             = var.private_count
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + var.public_count)
    availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
    tags = {
        Name = "private-${count.index}"
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

resource "aws_security_group" "alb_sg" {
    name   = "alb-sg"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
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

resource "aws_eks_fargate_profile" "eks_fargate_profile" {
    cluster_name           = aws_eks_cluster.eks_cluster.name
    fargate_profile_name   = "fargate-profile"
    pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
    subnet_ids             = aws_subnet.private[*].id

    selector {
        namespace = "default"
    }

    selector {
        namespace = "kube-system"
        labels = {
            k8s-app = "kube-dns"
        }
    }
}

resource "aws_iam_role" "eks_fargate_pod_execution_role" {
    name = "eks-fargate-pod-execution-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement =[{
            Effect = "Allow"
            Action = "sts:AssumeRole"
            Principal = { Service = "eks-fargate-pods.amazonaws.com" }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution_policy" {
    role = aws_iam_role.eks_fargate_pod_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

data "tls_certificate" "oidc" {
    url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_identifier" {
    url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
    client_id_list  = ["sts.amazonaws.com"]
    thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}


data "aws_iam_policy_document" "alb_controller_assume_role" {
    statement {
        actions = ["sts:AssumeRoleWithWebIdentity"]
        effect  = "Allow"
        principals {
            type        = "Federated"
            identifiers = [aws_iam_openid_connect_provider.eks_identifier.arn]
        }
        condition {
            test     = "StringEquals"
            variable = "${replace(aws_iam_openid_connect_provider.eks_identifier.url, "https://", "")}:sub"
            values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
        }
    }
}

resource "aws_iam_role" "alb_controller" {
    name               = "aws-load-balancer-controller"
    assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json
}

resource "aws_iam_policy" "alb_controller_policy" {
  name = "alb-controller-policy"
  policy  = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
    policy_arn = aws_iam_policy.alb_controller_policy.arn
    role       = aws_iam_role.alb_controller.name
}

data "aws_iam_policy_document" "eks_irsa_ecr_document" {
    statement {
        actions = ["sts:AssumeRoleWithWebIdentity"]
        effect  = "Allow"
        principals {
            type        = "Federated"
            identifiers = [aws_iam_openid_connect_provider.eks_identifier.arn]
        }
        condition {
            test     = "StringEquals"
            variable = "${replace(aws_iam_openid_connect_provider.eks_identifier.url, "https://", "")}:sub"
            values   = ["system:serviceaccount:default:ecr-sa"]
        }
    }
}

resource "aws_iam_role" "eks_irsa_ecr_role" {
    name               = "eks-irsa-ecr-role"
    assume_role_policy = data.aws_iam_policy_document.eks_irsa_ecr_document.json
}

resource "aws_iam_role_policy_attachment" "eks_irsa_role_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.eks_irsa_ecr_role.name
}

data "aws_eks_cluster_auth" "eks" {
    name = aws_eks_cluster.eks_cluster.name
}

provider "kubernetes" {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
}

resource "kubernetes_service_account" "ecr_sa" {
  metadata {
    name      = "ecr-sa"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_irsa_ecr_role.arn
    }
  }
}