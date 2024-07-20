output "db_endpoint" {
    value = aws_db_instance.urotaxidb.endpoint
}
output "javaserver_ip" {
  value = aws_instance.urotaxiec2.public_ip
}