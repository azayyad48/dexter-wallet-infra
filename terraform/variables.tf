variable "project" {
  description = "Project name, used as a prefix on resource names"
  type        = string
  default     = "dexter-wallet"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region. eu-west-1 over af-south-1 for cost and service availability - see docs/DESIGN.md"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread across"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway instead of one per AZ. Saves ~$32/month per gateway in dev; set false in prod to avoid coupling app AZs to a single NAT AZ."
  type        = bool
  default     = true
}

variable "container_port" {
  description = "Port the API container listens on"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Baseline number of API tasks"
  type        = number
  default     = 2
}

variable "max_count" {
  description = "Upper bound for API task auto scaling"
  type        = number
  default     = 6
}

variable "db_instance_class" {
  description = "RDS instance class. Burstable is fine to start; revisit once we have real traffic numbers."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_multi_az" {
  description = "Run RDS in Multi-AZ. Off in dev to halve the DB bill, must be on in prod."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "wallet"
}
