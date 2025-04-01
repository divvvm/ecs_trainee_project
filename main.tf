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