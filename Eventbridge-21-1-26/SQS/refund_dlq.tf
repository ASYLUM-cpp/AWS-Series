resource "aws_sqs_queue" "refund_dlq" {
  name = "refund-consumer-dlq"
}