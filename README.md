# Setting Up GitHub Runners with Docker Compose and GitHub App Authentication

This guide outlines the process of setting up GitHub runners using Docker Compose, with a focus on configuring multiple runners for various repositories. It includes authenticating through a GitHub App, allowing for dynamic management of tokens used for runner registration.

## Prerequisites

Ensure you have:

- **Docker and Docker Compose**: Installed and running on your system.
- **A GitHub Account**: With access to the repositories for which you want to add runners.
- **A GitHub App**: Created within your GitHub account, equipped with:
  - An **App ID**
  - An **Installation ID**
  - A downloaded **private key** (`*.pem` file)

## Configuration Steps

### 1. GitHub App Setup

1. Create a GitHub App in your GitHub account's settings under Developer settings → GitHub Apps.
2. Record the **App ID** and generate a **private key**. Store this `.pem` file securely.
3. Install the GitHub App in your account or organization and note the **Installation ID**.

### 2. Environment Setup

1. Place the GitHub App's `*.pem` private key in a secure, accessible location.
2. Create a `.env` file with your GitHub App's credentials and the repositories' details:

```env
GH_OWNER=your_github_username_or_organization
INSTALLATION_ID=your_app_installation_id
APP_ID=your_app_id
CLIENT_ID=your_client_id
# Add more variables as needed for multiple repositories
```

### 3. Docker Compose Configuration

Using the provided Docker Compose template, configure each service for your GitHub runners. Ensure you update the `environment` variables and the `GH_REPOSITORY` for each service according to your setup:

```yaml
version: '3.8'

services:
  your-service:
    user: "1000"
    build:
      context: .
      dockerfile: dockerfile.yaml
      args:
        RUNNER_VERSION: '2.312.0'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    privileged: true
    environment:
      GH_TOKEN: ${GH_TOKEN}
      GH_OWNER: ${GH_OWNER}
      GH_REPOSITORY: 'natedresume'
      # Include other environment variables as needed
  # Define additional runners as needed following the same pattern

```

- **Note**: The `user: "1000"` line configures the container to run as a user with ID `1000`, ensuring proper permissions for Docker socket interactions.

### 4. Build and Run Your GitHub Runners

With your Docker Compose file configured, start your GitHub runners:

```sh
docker-compose up -d
```

This command launches your GitHub runners in detached mode, ready to listen for actions from their respective repositories.

## Verification

Check the Actions section in your GitHub repository settings to see your new runners listed under the Runners tab.

## Cleanup and Security

- Secure your `.env` file and private key from unauthorized access.
- Consider implementing additional security measures for runners with Docker access.

---

