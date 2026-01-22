resource "aws_cloudwatch_event_target" "inventory_target" {
  rule           = aws_cloudwatch_event_rule.order_created.name
  event_bus_name = aws_cloudwatch_event_bus.ecommerce.name
  arn            = aws_lambda_function.inventory.arn
  role_arn       = aws_iam_role.eventbridge_inventory_role.arn

  dead_letter_config {
    arn = aws_sqs_queue.inventory_dlq.arn
  }
}

resource "aws_cloudwatch_event_target" "notification_target" {
  rule           = aws_cloudwatch_event_rule.order_created.name
  event_bus_name = aws_cloudwatch_event_bus.ecommerce.name
  arn            = aws_lambda_function.notification.arn
  role_arn       = aws_iam_role.eventbridge_notification_role.arn

  dead_letter_config {
    arn = aws_sqs_queue.notification_dlq.arn
  }
}

resource "aws_cloudwatch_event_target" "refund_target" {
  rule           = aws_cloudwatch_event_rule.order_created.name
  event_bus_name = aws_cloudwatch_event_bus.ecommerce.name
  arn            = aws_lambda_function.refund.arn
  role_arn       = aws_iam_role.eventbridge_refund_role.arn

  dead_letter_config {
    arn = aws_sqs_queue.refund_dlq.arn
  }
}