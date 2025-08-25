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

resource "aws_lb" "alb" {
    name               = "alb"
    internal           = false
    load_balancer_type = "application"
    subnets            = aws_subnet.public[*].id
    security_groups    = [aws_security_group.alb_sg.id]
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

resource "aws_ecs_cluster" "cluster" {
    name = "cluster"

    setting {
        name  = "containerInsights"
        value = "enabled"
    }
}

resource "aws_iam_role" "ecs_task_role" {
    name = "ecs-task-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "ecs-tasks.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
    role       = aws_iam_role.ecs_task_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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

resource "aws_security_group" "ecs_sg" {
    name   = "ecs-sg"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        from_port       = 8000
        to_port         = 8000
        protocol        = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_target_group" "lb_tg" {
    name     = "lb-tg"
    port     = 8000
    protocol = "HTTP"
    vpc_id   = aws_vpc.my_vpc.id

    health_check {
        path                = "/health"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 2
        unhealthy_threshold = 3
        matcher             = "200-299"    
    }

    target_type = "ip"
}

resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.lb_tg.arn
    }

    depends_on = [aws_lb_target_group.lb_tg]
}

resource "aws_security_group" "rds_sg" {
    name   = "rds-sg"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        security_groups = [aws_security_group.ecs_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_ecs_task_definition" "api_task" {
    family                   = "api_task"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                      = 512
    memory                   = 1024
    execution_role_arn       = aws_iam_role.ecs_task_role.arn
    task_role_arn            = aws_iam_role.ecs_task_role.arn

    container_definitions = jsonencode([
        {
            name = "api"
            image = var.image
            cpu = 256
            memory = 512
            essential = true
            portMappings = [{ 
                containerPort = 8000,
                protocol      = "tcp"
            }]
            environment = [
                {
                    name = "DATABASE_URL",
                    value = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres_db.endpoint}:5432/${var.db_name}"
                },
                {
                    name = "SECRET_KEY"
                    value = var.secret_key
                },
                {
                    name = "ALGORITHM"
                    value = var.algorithm
                },
                {
                    name = "ACCESS_TOKEN_EXPIRE_MINUTES"
                    value = var.access_token_expire_minutes
                }
            ]
        }
    ])
}

resource "aws_ecs_service" "api_service" {
    name = "api-service"
    cluster = aws_ecs_cluster.cluster.id
    task_definition = aws_ecs_task_definition.api_task.arn
    desired_count = 4
    launch_type = "FARGATE"

    network_configuration {
        subnets = aws_subnet.private[*].id
        security_groups = [aws_security_group.ecs_sg.id]
        assign_public_ip = false
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.lb_tg.arn
        container_name = "api"
        container_port = 8000
    }

    depends_on = [aws_lb_listener.listener]
}