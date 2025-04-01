terraform {
  backend "s3" {
    bucket = "dmisi-ecs-terraform-state"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}