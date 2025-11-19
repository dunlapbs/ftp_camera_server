FROM ubuntu:latest

# Install vsftpd and iproute2
RUN apt-get update && \
    apt-get install -y vsftpd iproute2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create FTP user and upload directory
RUN useradd -m -d /home/ftpuser -s /bin/bash ftpuser && \
    mkdir -p /var/ftp/camera_uploads && \
    chown -R ftpuser:ftpuser /var/ftp/camera_uploads

# Copy vsftpd configuration
COPY vsftpd.conf /etc/vsftpd.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose FTP ports
EXPOSE 21
EXPOSE 21100-21110

# Run entrypoint script
CMD ["/entrypoint.sh"]
