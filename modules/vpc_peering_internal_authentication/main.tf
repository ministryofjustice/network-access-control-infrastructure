resource "aws_vpc_peering_connection" "this" {
  peer_owner_id = var.target_aws_account_id
  peer_vpc_id   = var.target_vpc_id
  vpc_id        = var.source_vpc_id
  auto_accept   = true
}

resource "aws_route" "peering_route" {
  route_table_id = var.source_route_table_ids[0]

  destination_cidr_block    = "10.0.0.6/32"
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  depends_on                = [aws_vpc_peering_connection.this]
}

resource "aws_route" "peering_route_destination" {
  route_table_id = var.destination_route_table_ids[0]

  destination_cidr_block    = var.destination_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  depends_on                = [aws_vpc_peering_connection.this]
}