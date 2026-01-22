output "eventbridge_bus_arn" {
  description = "ARN of the EventBridge bus"
  value       = aws_cloudwatch_event_bus.ecommerce_bus.arn
}

output "eventbridge_bus_name" {
  description = "Name of the EventBridge bus"
  value       = aws_cloudwatch_event_bus.ecommerce_bus.name
}

output "inventory_lambda_arn" {
  description = "ARN of the inventory Lambda function"
  value       = aws_lambda_function.inventory.arn
}

output "notification_lambda_arn" {
  description = "ARN of the notification Lambda function"
  value       = aws_lambda_function.notification.arn
}

output "refund_lambda_arn" {
  description = "ARN of the refund Lambda function"
  value       = aws_lambda_function.refund.arn
}

output "inventory_dlq_url" {
  description = "URL of the inventory dead-letter queue"
  value       = aws_sqs_queue.inventory_dlq.url
}

output "notification_dlq_url" {
  description = "URL of the notification dead-letter queue"
  value       = aws_sqs_queue.notification_dlq.url
}

output "refund_dlq_url" {
  description = "URL of the refund dead-letter queue"
  value       = aws_sqs_queue.refund_dlq.url
}
