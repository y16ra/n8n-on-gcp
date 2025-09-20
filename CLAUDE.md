# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform Infrastructure as Code (IaC) project for deploying n8n workflow automation platform on Google Cloud Platform using Cloud Run and Supabase PostgreSQL database. The project creates a minimal, production-ready setup with proper secret management and container image mirroring.

## Key Architecture Components

- **Cloud Run**: Single instance n8n service (min=1, max=1) with auto-scaling disabled for filesystem binary data mode
- **Artifact Registry**: Hosts mirrored n8n Docker images from DockerHub
- **Secret Manager**: Manages sensitive credentials (encryption keys, database passwords, basic auth)
- **Supabase PostgreSQL**: External database with TLS connection
- **Service Account**: Dedicated IAM identity with minimal required permissions

## Directory Structure

```
envs/prod/          # Production environment (main Terraform execution directory)
modules/            # Reusable Terraform modules
  ├── artifact_registry/  # Docker image registry
  ├── cloud_run_n8n/     # n8n Cloud Run service with environment configuration
  ├── gcp_services/      # API enablement
  ├── iam/              # Service account and permissions
  └── secrets/          # Secret Manager resources and IAM bindings
.github/workflows/    # GitHub Actions for image mirroring
```

## Common Development Commands

### Terraform Operations
```bash
# Initialize and work in the production environment
cd envs/prod
terraform init
terraform plan
terraform apply
terraform destroy
```

### Image Management
```bash
# Configure Docker for Artifact Registry
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# Mirror n8n image to Artifact Registry (recommended method)
docker pull --platform linux/amd64 n8nio/n8n:latest
docker buildx imagetools create --tag asia-northeast1-docker.pkg.dev/PROJECT_ID/n8n/n8n:latest docker.io/n8nio/n8n:latest@sha256:SPECIFIC_DIGEST

# Alternative: Use GitHub Actions workflow "Build and Push n8n to Artifact Registry"
# (manual trigger with n8n_tag input parameter)
```

### Secret Management
```bash
# Generate encryption key
openssl rand -base64 32

# Add secret versions (required after initial terraform apply)
gcloud secrets versions add n8n-encryption-key --data-file=- <<<'your-encryption-key'
gcloud secrets versions add n8n-db-password --data-file=- <<<'supabase-password'
gcloud secrets versions add n8n-basic-auth-password --data-file=- <<<'basic-auth-password'
```

### Troubleshooting
```bash
# Check Cloud Run logs for debugging
gcloud beta run services logs read n8n --region=asia-northeast1 --project=PROJECT_ID --limit=50

# Common issues and solutions:
# - Database connection timeout: Verify Supabase host format (db.PROJECT_ID.supabase.co)
# - Container startup failure: Check image exists in Artifact Registry
# - Port configuration: Ensure container_port = 8080 in Cloud Run config
```

## Configuration

The main configuration is in `envs/prod/terraform.tfvars` (copy from `terraform.tfvars.example`):

- **Required**: `project_id`, `region`, `db_host`, `db_password_secret_name`
- **Security**: Always enable `n8n_basic_auth_user` when `public = true`
- **Image**: Set `image_tag` to specific version or "latest" after mirroring images

## Important Implementation Details

- **Single Instance**: Cloud Run scaling is fixed (min=1, max=1) because n8n uses `N8N_BINARY_DATA_MODE=filesystem`
- **Database**: Configured for Supabase with `DB_POSTGRESDB_SSL=true`, `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false`, and `DB_POSTGRESDB_CONNECTION_TIMEOUT=60000`
- **Container Configuration**: Requires explicit port configuration (`container_port = 8080`) and extended timeout (`timeout = "900s"`)
- **Images**: n8n images are mirrored from DockerHub to Artifact Registry using `docker buildx imagetools` to avoid multi-architecture manifest issues
- **n8n Authentication**: Basic Auth configuration becomes ineffective once n8n initial setup is completed and admin user is created

## Module Dependencies

Modules have explicit dependencies:
1. `gcp_services` (API enablement) runs first
2. `artifact_registry`, `iam`, `secrets` depend on services
3. `cloud_run_n8n` depends on all other modules through service account and image references

## Security Considerations

- Secrets are managed through Secret Manager (never in Terraform state)
- Service Account has minimal required permissions (logging, monitoring, artifact registry read, secret access)
- Basic Auth protects public endpoints during initial setup only
- TLS encryption for database connections
- Supabase database requires correct host format: `db.PROJECT_ID.supabase.co` (not `PROJECT_ID.supabase.co`)

## Deployment Requirements

- **Terraform**: Version 1.5.0+ (updated from original 1.6.0+ requirement)
- **Docker**: Required for image mirroring operations
- **gcloud beta components**: Required for Cloud Run logs access (`gcloud components install beta`)
- **Supabase**: External database service setup required before deployment

## Development Workflow

When making changes to this repository:

1. **Always create feature branches** before making commits:
   ```bash
   git checkout -b feature/your-feature-name
   # Make your changes
   git add .
   git commit -m "feat(scope): your conventional commit message"
   git push -u origin feature/your-feature-name
   # Create PR for review
   ```

2. **Use Conventional Commits format** for all commit messages (English):
   ```
   <type>[optional scope]: <description>

   [optional body]
   [optional footer(s)]
   ```

   **Common types:**
   - `feat`: New features
   - `fix`: Bug fixes
   - `docs`: Documentation changes only
   - `style`: Code style changes (formatting, semicolons, etc.)
   - `refactor`: Code changes that neither fix bugs nor add features
   - `test`: Adding or modifying tests
   - `chore`: Build process or auxiliary tool changes

   **Examples:**
   ```bash
   feat(terraform): add cloud run n8n deployment module
   fix(secrets): resolve secret manager IAM binding issue
   docs: update README with supabase setup instructions
   chore: update terraform version requirements to 1.5.0+
   ```

3. **Test infrastructure changes** in isolated environments before applying to production

4. **Verify deployments** using Cloud Run logs and n8n web interface accessibility

## Common Issue Resolution

- **"terraform.tfvars not found"**: Copy from `terraform.tfvars.example` and populate with your values
- **"Image not found in Artifact Registry"**: Run image mirroring commands or GitHub Actions workflow first
- **"Database connection refused"**: Verify Supabase host format and network connectivity
- **"Cloud Run startup timeout"**: Check container logs for application-level errors