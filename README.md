
# How this works
- Creates the infrastructure in AWS using Terraform and outputs the ECS cluster name
- each container image is tagged and pushed to ghcr.io
- then each pipeline updates the ECS service with the new image by updating the task definition


