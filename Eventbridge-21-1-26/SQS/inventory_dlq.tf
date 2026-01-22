resource "aws_sqs_queue" "inventory_dlq" {
  name = "inventory-consumer-dlq"
}
