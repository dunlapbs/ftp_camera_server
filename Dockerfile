FROM alpine:latest

# Install vsftpd
RUN apk add --no-cache vsftpd bash

# Create FTP user and upload directory
RUN adduser -D -h /home/ftpuser ftpuser && \
    mkdir -p /var/ftp/camera_uploads && \
    chown -R ftpuser:ftpuser /var/ftp/camera_uploads

# Copy vsftpd configuration
COPY vsftpd.conf /etc/vsftpd/vsftpd.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose FTP ports
EXPOSE 21
EXPOSE 21100-21110

# Run entrypoint script
CMD ["/entrypoint.sh"]
