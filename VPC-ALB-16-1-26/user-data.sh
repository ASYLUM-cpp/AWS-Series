#!/bin/bash
set -euxo pipefail

# Log everything user-data does
exec > /var/log/user-data.log 2>&1

# Update system and install Nginx
yum update -y
yum install -y nginx

# Ensure Nginx runs on boot and start it now
systemctl enable nginx
systemctl start nginx

# Fetch instance metadata using IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

# Create a simple webpage showing instance info
cat <<HTML > /usr/share/nginx/html/index.html
<html>
  <body style="font-family: Arial">
    <h1>Hello from EC2</h1>
    <p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>
    <p><strong>Private IP:</strong> ${PRIVATE_IP}</p>
  </body>
</html>
HTML

# Restart Nginx just in case
systemctl restart nginx
