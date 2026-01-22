resource "aws_cloudwatch_event_rule" "order_created" {
  name           = "order-created"
  event_bus_name = aws_cloudwatch_event_bus.ecommerce.name

  event_pattern = jsonencode({
    source = ["com.mycompany.orders"]
    detail-type = ["OrderCreated"]
  })
}
