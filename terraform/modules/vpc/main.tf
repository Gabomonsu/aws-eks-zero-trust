locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, {
    Name       = "${var.name}-vpc"
    Component  = "vpc"
    Managed_By = "terraform"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ---------- Subnets privadas (sin acceso publico directo) ----------
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr_block, 4, count.index + var.private_subnet_offset)
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name                              = "${var.name}-private-${local.azs[count.index]}"
    Tier                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# ---------- Subnets publicas minimas (solo para el bastion/NAT) ----------
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr_block, 4, count.index + 8)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name                     = "${var.name}-public-${local.azs[count.index]}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_internet_gateway" "this" {
  count  = var.enable_nat ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_route_table" "public" {
  count  = var.enable_nat ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  count                  = var.enable_nat ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count          = var.enable_nat ? var.az_count : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_eip" "nat" {
  count  = var.enable_nat ? var.az_count : 0
  domain = "vpc"
  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${local.azs[count.index]}"
  })
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat ? var.az_count : 0
  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id
  tags = merge(var.tags, {
    Name = "${var.name}-nat-${local.azs[count.index]}"
  })
}

resource "aws_route_table" "private" {
  count  = var.enable_nat ? var.az_count : 1
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = var.enable_nat ? "${var.name}-private-rt-${local.azs[count.index]}" : "${var.name}-private-rt"
  })
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat ? var.az_count : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.enable_nat ? count.index : 0].id
}

# ---------- Gateway endpoint para S3 (gratis, no genera cargo) ----------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.enable_nat ? aws_route_table.private[*].id : [aws_route_table.private[0].id]
  tags = merge(var.tags, {
    Name = "${var.name}-s3-endpoint"
  })
}

# ---------- Interface endpoints para servicios privados ----------
resource "aws_vpc_endpoint" "interface" {
  for_each            = var.interface_endpoints
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = var.endpoint_sg_ids

  tags = merge(var.tags, {
    Name = "${var.name}-${each.value}-endpoint"
  })
}
