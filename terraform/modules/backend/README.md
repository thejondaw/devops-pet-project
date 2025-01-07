## Backend Module

### Overview
Sets up secure S3 backend for Terraform state storage with DynamoDB locking.

### Key Features
- Encrypted state storage
- State file versioning
- Public access blocking
- State locking mechanism
- DynamoDB auto-scaling

### Resources Created
- S3 bucket configurations
  - Versioning
  - Encryption
  - Public access blocking
- DynamoDB table for state locking

### Design Decisions
- AES-256 encryption for data at rest
- Versioning enabled for state file history
- Complete public access blocking for security
- DynamoDB for reliable locking mechanism
