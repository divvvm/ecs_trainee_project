module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "subnets" {
  source                    = "./modules/subnets"
  vpc_id                    = module.vpc.vpc_id
  public_subnet_cidr_1      = var.public_subnet_cidr_1
  public_subnet_cidr_2      = var.public_subnet_cidr_2
  private_app_subnet_cidr_1 = var.private_app_subnet_cidr_1
  private_app_subnet_cidr_2 = var.private_app_subnet_cidr_2
  private_db_subnet_cidr_1  = var.private_db_subnet_cidr_1
  private_db_subnet_cidr_2  = var.private_db_subnet_cidr_2
  public_route_table_id     = module.vpc.public_route_table_id
}

module "nat_gateway" {
  source = "./modules/nat_gateway"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = [
    module.subnets.public_subnet_1_id,
    module.subnets.public_subnet_2_id
  ]
  private_subnet_ids_az1 = [
    module.subnets.private_app_subnet_1_id,
    module.subnets.private_db_subnet_1_id
  ]
  private_subnet_ids_az2 = [
    module.subnets.private_app_subnet_2_id,
    module.subnets.private_db_subnet_2_id
  ]
}

module "security_groups" {
  source   = "./modules/security_groups"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
}

module "alb" {
  source            = "./modules/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = [module.subnets.public_subnet_1_id, module.subnets.public_subnet_2_id]
  security_group_id = module.security_groups.alb_sg_id
}

module "rds" {
  source             = "./modules/rds"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = [module.subnets.private_db_subnet_1_id, module.subnets.private_db_subnet_2_id]
  security_group_id  = module.security_groups.rds_sg_id
}

module "cloudwatch_logs" {
  source = "./modules/cloudwatch_logs"

  cluster_name  = "chat-cluster"
  service_names = ["backend", "frontend", "prometheus", "grafana", "ollama"]
}

module "ecr" {
  source = "./modules/ecr"
}

module "ecs" {
  source                   = "./modules/ecs"
  private_subnet_ids       = [module.subnets.private_app_subnet_1_id, module.subnets.private_app_subnet_2_id]
  ecs_security_group_id    = module.security_groups.ecs_sg_id
  ollama_security_group_id = module.security_groups.ollama_sg_id
  target_group_arns        = module.alb.target_group_arns
  db_endpoint              = module.rds.db_endpoint
  ecr_repository_urls      = module.ecr.repository_urls
  depends_on               = [module.cloudwatch_logs]
  services = [
    {
      name           = "backend"
      image          = "${module.ecr.repository_urls["app-service"]}:latest"
      container_port = 8000
      cpu            = "256"
      memory         = "512"
      environment = [
        {
          name  = "DB_HOST"
          value = module.rds.db_host
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = "mydb"
        },
        {
          name  = "DB_USER"
          value = "denys"
        },
        {
          name  = "DB_PASSWORD"
          value = "password123"
        },
        {
          name  = "PGPASSWORD"
          value = "password123"
        }
      ]
    },
    {
      name           = "frontend"
      image          = "${module.ecr.repository_urls["web-service"]}:latest"
      container_port = 3080
      cpu            = "256"
      memory         = "2048"
      environment = [
        {
          name  = "ENDPOINT_NAME"
          value = "MyCustomAPI"
        },
        {
          name  = "ENDPOINT_API_KEY"
          value = "dummy-token"
        },
        {
          name  = "ENDPOINT_BASE_URL"
          value = "http://${module.alb.alb_dns_name}/v1"
        },
        {
          name  = "ENDPOINT_MODELS"
          value = "llama3"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
    },
    {
      name           = "prometheus"
      image          = "prom/prometheus:latest"
      container_port = 9090
      cpu            = "256"
      memory         = "512"
      environment    = []
    },
    {
      name           = "grafana"
      image          = "grafana/grafana:latest"
      container_port = 3000
      cpu            = "256"
      memory         = "512"
      environment    = []
    },
    {
      name           = "ollama"
      image          = "${module.ecr.repository_urls["ollama"]}:latest"
      container_port = 11434
      cpu            = "2048"
      memory         = "6144"
      environment    = []
    }
  ]
}