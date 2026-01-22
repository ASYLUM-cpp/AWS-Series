resource "aws_cloudwatch_event_bus" "ecommerce" {
  name = var.event_bus_name
}
