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

resource "aws_ecs_task_definition" "my_task" {
  family = "my-task"
  container_definitions = jsonencode([{
    name   = "dummy-task"
    image  = "busybox"
    cpu    = 256
    memory = 512
    },
  ])
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
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
resource "aws_db_instance" "postgres" {
  identifier                  = "main"
  allocated_storage           = 10
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "16.4"
  instance_class              = "db.m5.large"
  manage_master_user_password = true
  username                    = "main"
  tags = {
    Name = "main"
  }

}
