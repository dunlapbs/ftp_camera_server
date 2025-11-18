#!/bin/bash
set -e

# Default FTP credentials
FTP_USER=${FTP_USER:-ftpuser}
FTP_PASSWORD=${FTP_PASSWORD:-camera123}

echo "Starting FTP Camera Server..."
echo "FTP User: $FTP_USER"

# Set FTP user password
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

# Ensure upload directory exists and has correct permissions
mkdir -p /var/ftp/camera_uploads
chown -R $FTP_USER:$FTP_USER /var/ftp/camera_uploads

# Create vsftpd secure chroot directory
mkdir -p /var/run/vsftpd/empty

# Start vsftpd in foreground
echo "Starting FTP server on port 21..."
echo "Passive ports: 21100-21110"
exec /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
