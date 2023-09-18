output "aws_transfer_server_endpoint" {
  description = "aws_transfer_server_endpoint"
  value       = aws_transfer_server.sftp_server.endpoint
}