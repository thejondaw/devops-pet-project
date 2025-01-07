## RDS Module

### Overview
Deploys Aurora PostgreSQL in serverless v2 mode with enhanced security and monitoring.

### Key Features
- Serverless v2 for cost optimization
- Multi-AZ deployment
- KMS encryption
- Enhanced monitoring
- Performance insights
- Automated backups
- CloudWatch alarms

### Resources Created
- Aurora PostgreSQL cluster
- Parameter group with optimized settings
- Subnet group for network isolation
- Security group for access control
- KMS keys for encryption
- IAM role for monitoring
- CloudWatch alarms
- Secrets Manager secret

### Design Decisions
- Serverless v2 for auto-scaling and cost efficiency
- Performance Insights enabled for query analysis
- 14-day backup retention for disaster recovery
- Enhanced monitoring for detailed metrics
- Secrets in AWS Secrets Manager for security
