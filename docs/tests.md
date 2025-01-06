# 🛠️ Local Development Environment Setup

This guide covers the setup of a local PostgreSQL development environment for testing the application stack.

## Prerequisites

- Linux environment (RHEL/Fedora/CentOS)
- Sudo privileges
- Node.js 14.x installed

## 🐘 PostgreSQL Installation & Configuration

### 1. Install PostgreSQL Server
```bash
# Install PostgreSQL and required tools
sudo dnf install postgresql-server postgresql-contrib

# Initialize database cluster
sudo postgresql-setup --initdb --unit postgresql

# Enable and start PostgreSQL service
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

### 2. Database Creation
Connect to PostgreSQL as superuser:
```bash
sudo -u postgres psql
```

Create development database and user:
```sql
-- Create user with secure password
CREATE USER jondaw WITH PASSWORD '123456789';  -- ⚠️ Change in production!

-- Create test database
CREATE DATABASE test OWNER jondaw;

-- Exit psql
\q
```

### 🔐 3. Configure Authentication

Edit PostgreSQL host-based authentication:
```bash
sudo vim /var/lib/pgsql/data/pg_hba.conf
```

Replace default configuration with password authentication:
```conf
# TYPE  DATABASE    USER        ADDRESS         METHOD
# Local socket connections
local   all        all                         password

# IPv4 local connections
host    all        all         127.0.0.1/32    password

# IPv6 local connections
host    all        all         ::1/128         password

# Replication privileges
local   replication all                        password
host    replication all        127.0.0.1/32    password
host    replication all        ::1/128         password
```

Restart PostgreSQL to apply changes:
```bash
sudo systemctl restart postgresql
```

### 4. Application Configuration ⚙️

Update your Node.js application's database configuration:

```javascript
const dbConfig = {
    user: 'jondaw',           // Database user
    database: 'test',         // Database name
    password: '123456789',    // User password
    host: 'localhost',        // Database host
    port: 5432               // Default PostgreSQL port
};
```

## 🧪 Testing the Connection

1. Connect to database:
```bash
psql -U jondaw -d test
```

2. Verify connection:
```sql
-- Check connection info
\conninfo

-- Test query
SELECT version();
```

## ⚠️ Security Notes

- This configuration is for **development only**
- For production:
  - Use strong passwords
  - Implement connection pooling
  - Enable SSL/TLS encryption
  - Restrict network access
  - Use environment variables for credentials

## 🔧 Troubleshooting

Common issues and solutions:

1. **Connection refused**
   ```bash
   # Check PostgreSQL service status
   sudo systemctl status postgresql

   # View logs
   sudo journalctl -u postgresql
   ```

2. **Authentication failed**
   ```bash
   # Verify pg_hba.conf was updated
   sudo grep "^host" /var/lib/pgsql/data/pg_hba.conf
   ```

3. **Permission denied**
   ```bash
   # Check PostgreSQL user permissions
   sudo -u postgres psql -c "\du"
   ```
