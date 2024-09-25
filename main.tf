resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_ecs_service" "my_service" {
  name          = "my-service"
  cluster       = aws_ecs_cluster.my_cluster.id
  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.allow_tls.id]
    assign_public_ip = true
  }

}
