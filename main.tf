resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_ecs_service" "my_service" {
  name          = "my-service"
  cluster       = aws_ecs_cluster.my_cluster.id
  desired_count = 1
  launch_type   = "FARGATE"

  task_definition = aws_ecs_task_definition.my_task.arn

  network_configuration {
    subnets          = [aws_subnet.public.id, aws_subnet.private.id]
    security_groups  = [aws_security_group.allow_tls.id]
    assign_public_ip = true
  }
}

// @TODO: allow ecs to pull images from ghcr.io
resource "aws_ecs_task_definition" "my_task" {
  family = "my-task"
  container_definitions = jsonencode([{
    name      = "subscription-solver-frontend"
    image     = "gchr.io/madhavrkumar/subscription-solver-frontend:main"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 8000
    }]
    },
    {
      name      = "subscription-solver-backend"
      image     = "gchr.io/madhavrkumar/subscription-solver:main"
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        {
          name  = "POSTGRES_URL"
          value = aws_db_instance.main.address
        },
      ]
      portMappings = [{
        containerPort = 8080
        hostPort      = 8080
      }]
    },
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  // needs to be able to connect to RDS instance
  task_role_arn = aws_iam_role.ecs_task_role.arn
}


///// IAM

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

/// ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name               = "ecs_task_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name = "main"
  }
}


// @TODO: allow access only to specific RDS instance
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  role       = aws_iam_role.ecs_task_role.name
}


/// ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name = "main"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}


///// RDS Instance
resource "aws_db_instance" "main" {
  identifier                  = "main"
  allocated_storage           = 10
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t2.micro"
  parameter_group_name        = "default.mysql8.0"
  manage_master_user_password = true
  username                    = "main"
  tags = {
    Name = "main"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.private.id]
}
