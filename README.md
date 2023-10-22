# EC-Django-Deploy

A repository of a project to deploy Django web application using AWS services.

Team Name: CraftyCoders

---

- [x] Dedicated server

  - Load balancing
  - Route53 alias

- [x] CICD:
  - Build
  - Deploy
  - Pipline
- AWS Optimize

  - [x] Craete account: EC Deploy Admin

    - Create temp IAM key
    - EC Deploy Admin

  - [x] AWS AMI
    - Ubuntu
    - install package
      - gunicorn
      - nginx
      - supervisor
    - Template

- [x] App:

  - [x] update script: user data
  - [x] Login required
  - [x] Admin account

- [x] RDS:
  - cli connect to EC2, then connect to RDS
  - `mysql -uuser -hendpoint -p`
