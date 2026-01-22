resource "aws_sqs_queue" "notification_dlq" {
  name = "notification-consumer-dlq"
}