# FTP Camera Server

A lightweight FTP server Docker container specifically designed for IP camera uploads. Built on Alpine Linux with vsftpd for secure, reliable file transfers from security cameras.

## Features

### 🎥 Camera Upload Optimized
- **Multi-Camera Support**: Each camera uploads to its own directory
- **Automatic Directory Creation**: Cameras can create their own folder structure
- **Passive FTP Mode**: Works with cameras behind NAT/firewalls
- **Persistent Storage**: Camera footage stored on host filesystem
- **Lightweight**: Alpine-based image (~10MB)

### 🔒 Security
- **No Anonymous Access**: Requires authentication
- **Chroot Jail**: Users cannot access files outside their directory
- **Configurable Credentials**: Change username/password via environment variables
- **UTF-8 Support**: Handles international characters in filenames

## Quick Start

### 1. Run the Container

```bash
# Create directory for camera uploads
mkdir camera_uploads

# Copy configuration
cp .env.example .env

# IMPORTANT: Change the default password!
nano .env

# Start the container
docker-compose up -d
```

### 2. Configure Your Cameras

**FTP Settings to enter in your cameras:**
- **Server/Host**: `192.168.1.100` (your Docker host IP)
- **Port**: `21`
- **Username**: `ftpuser`
- **Password**: `camera123` (or your custom password from `.env`)
- **Directory/Path**: `/{CameraName}` (e.g., `/FrontDoor`, `/Backyard`)

**Example for Reolink Camera:**
1. Go to Settings → Network → FTP
2. Enable FTP
3. Server: Your Docker host IP
4. Port: 21
5. Username: ftpuser
6. Password: (your password from `.env`)
7. Remote Directory: /FrontDoor
8. Save and Test

### 3. Verify Uploads

```bash
# Check uploaded files
ls -la camera_uploads/

# View logs
docker-compose logs -f
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FTP_PORT` | `21` | FTP control port |
| `FTP_USER` | `ftpuser` | FTP username |
| `FTP_PASSWORD` | `camera123` | FTP password (⚠️ change this!) |
| `UPLOADS_DIRECTORY` | `./camera_uploads` | Host directory for uploads |

**⚠️ SECURITY WARNING**: Always change `FTP_PASSWORD` from the default in production!

```env
# .env file example
FTP_USER=mycameras
FTP_PASSWORD=MySecurePassword123!
UPLOADS_DIRECTORY=/mnt/camera-storage
```

### Directory Structure

The FTP server allows cameras to create their own directory structure:

```
camera_uploads/
├── FrontDoor/              # Camera 1
│   └── 11/                 # Month
│       └── 20251113123456/ # Timestamp folder
│           ├── video1.mp4
│           └── video1.jpg
├── Backyard/               # Camera 2
│   └── 11/
│       └── 20251113123500/
│           ├── video2.mp4
│           └── video2.jpg
└── Driveway/               # Camera 3
    └── 11/
        └── 20251113123505/
            ├── video3.mp4
            └── video3.jpg
```

**Key Points:**
- Each camera uploads to its own top-level directory
- Cameras can organize files however they want (by date, time, etc.)
- All directories are automatically created as needed

## Docker Deployment

### Basic Deployment

```bash
docker-compose up -d
```

### Custom Port

```bash
# In .env file
FTP_PORT=2121
```

Then configure cameras to use port 2121.

### Custom Upload Directory

```bash
# In .env file
UPLOADS_DIRECTORY=/mnt/camera-storage
```

Update docker-compose.yml volume:
```yaml
volumes:
  - /mnt/camera-storage:/var/ftp/camera_uploads
```

### View Logs

```bash
# Follow logs in real-time
docker-compose logs -f

# View recent logs
docker-compose logs --tail=100
```

### Update

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Network Configuration

### Firewall Rules

The FTP server requires these ports to be open:

**Required Ports:**
- **21/TCP**: FTP control port
- **21100-21110/TCP**: Passive mode data ports (range of 10 ports)

**Example iptables rules:**
```bash
# Allow FTP control
iptables -A INPUT -p tcp --dport 21 -j ACCEPT

# Allow FTP passive mode
iptables -A INPUT -p tcp --dport 21100:21110 -j ACCEPT
```

**Example UFW rules:**
```bash
sudo ufw allow 21/tcp
sudo ufw allow 21100:21110/tcp
```

### Router Port Forwarding

If accessing from outside your network, forward these ports:
- External 21 → Internal 21 (Docker host IP)
- External 21100-21110 → Internal 21100-21110

### Passive Mode

The server is configured for passive FTP mode, which works better with:
- Cameras behind NAT/routers
- Firewall configurations
- Modern network setups

Passive ports are configured as `21100-21110` (10 concurrent connections).

## Testing FTP Connection

### From Command Line

```bash
# Install FTP client
apt-get install ftp

# Connect to server
ftp <docker-host-ip>
# Username: ftpuser
# Password: camera123 (or your password)

# Test commands
ls
mkdir TestCamera
cd TestCamera
put test.txt
ls
quit
```

### From FileZilla

1. Host: `<docker-host-ip>`
2. Username: `ftpuser`
3. Password: (from .env)
4. Port: `21`
5. Click "Quickconnect"

## Troubleshooting

### Camera Can't Connect

**Check network connectivity:**
```bash
# From camera's network, test if port is open
telnet <docker-host-ip> 21
```

**Check firewall:**
```bash
# Verify ports are open
sudo ufw status
# or
sudo iptables -L -n
```

**Check container is running:**
```bash
docker ps | grep ftp-camera-server
```

### Camera Connects But Can't Upload

**Check credentials:**
- Verify FTP_USER and FTP_PASSWORD match what's in camera settings
- Check container logs for authentication errors:
  ```bash
  docker-compose logs | grep -i auth
  ```

**Check permissions:**
```bash
# Verify upload directory is writable
docker exec ftp-camera-server ls -la /var/ftp/camera_uploads
```

### Passive Mode Issues

**If cameras can't enter passive mode:**

1. Check passive port range is open in firewall:
   ```bash
   sudo ufw allow 21100:21110/tcp
   ```

2. Verify passive ports in logs:
   ```bash
   docker-compose logs | grep -i pasv
   ```

3. Some cameras may need active mode - check camera documentation

### Files Upload But Don't Appear

**Check directory:**
```bash
# List uploaded files
docker exec ftp-camera-server ls -la /var/ftp/camera_uploads

# Or on host
ls -la ./camera_uploads
```

**Check container logs:**
```bash
docker-compose logs -f
```

## Camera-Specific Configuration

### Reolink Cameras

**FTP Settings:**
- Common Picture Path: `/{CameraName}/Pictures/%Y%M%D`
- Common Video Path: `/{CameraName}/Videos/%Y%M%D`
- Use these variables: `%Y` (year), `%M` (month), `%D` (day), `%h` (hour), `%m` (minute), `%s` (second)

### Hikvision Cameras

**FTP Settings:**
- Picture Naming: Configure in Storage → Upload Picture
- Directory Structure: Can be customized per camera

### Amcrest Cameras

**FTP Settings:**
- Setup → Storage → FTP
- Remote Directory: `/{CameraName}`
- Enable "Create Folder by Date"

## Integration

This FTP server works seamlessly with the [Camera Clips Server](https://github.com/dunlapbs/camera-clips-server) for viewing uploaded footage:

```bash
# 1. Start FTP server (this container)
cd ftp_camera_server
docker-compose up -d

# 2. Start viewer (separate container)
cd camera-clips-server
# Point CLIPS_DIRECTORY to same location
CLIPS_DIRECTORY=/path/to/camera_uploads docker-compose up -d
```

Both containers can share the same upload directory:
- FTP server writes footage
- Clips server reads and displays footage

## Performance

- **Concurrent Connections**: 10 (passive port range)
- **Memory Usage**: ~10-20MB
- **CPU Usage**: Minimal (Alpine Linux + vsftpd)
- **Disk I/O**: Limited by camera upload speed and disk performance

## Security Best Practices

1. **Change Default Password**: Always set a strong FTP_PASSWORD
2. **Restrict Network Access**: Use firewall rules to limit access
3. **Use Strong Passwords**: Minimum 12 characters with mixed case, numbers, symbols
4. **Regular Updates**: Keep container image updated
5. **Monitor Logs**: Check for unauthorized access attempts
6. **Consider VPN**: For remote access, use VPN instead of exposing FTP publicly

## Logs

FTP server logs all connections and transfers:

```bash
# View all logs
docker-compose logs

# View specific time range
docker-compose logs --since 1h

# Follow logs in real-time
docker-compose logs -f

# Search for specific camera
docker-compose logs | grep FrontDoor
```

## Development

### Building Locally

```bash
# Build image
docker build -t ftp-camera-server .

# Run container
docker run -d \
  -p 21:21 \
  -p 21100-21110:21100-21110 \
  -v $(pwd)/camera_uploads:/var/ftp/camera_uploads \
  -e FTP_USER=ftpuser \
  -e FTP_PASSWORD=camera123 \
  ftp-camera-server
```

### Testing

```bash
# Create test upload
mkdir -p camera_uploads/TestCamera
echo "test" > test.txt

# Test FTP upload
ftp localhost 21
# username: ftpuser
# password: camera123
# > cd TestCamera
# > put test.txt
# > quit

# Verify upload
ls camera_uploads/TestCamera/
```

## License

MIT License - feel free to modify and distribute.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review container logs: `docker-compose logs -f`
3. Test FTP connection manually
4. Verify camera FTP settings
5. Check firewall/network configuration
