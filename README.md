# EC-Django-Deploy
A repository of a project to deploy Django web application using AWS services.

Team Name: CraftyCoders

- Dedicated server
  - Load balancing
  - Route53 alias

- CICD:
  - 1. AWS AMI
    - Ubuntu
    - install package
      - nginx
      - supervisor
    - Snapshot

  - 2. Build + Pipline
  - 3. Create temp IAM key
  - 4. setup Server

- App:
  - Admin account
  - Login required
  