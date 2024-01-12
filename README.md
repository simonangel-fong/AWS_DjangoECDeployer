# EC Django Deployer

- [EC Django Deployer](#ec-django-deployer)
  - [Overview](#overview)
  - [Features](#features)
  - [Use Cases](#use-cases)
  - [Demo](#demo)
  - [Diagram](#diagram)
  - [Documentation](#documentation)
    - [Deployment steps](#deployment-steps)
    - [Create a Golden Image](#create-a-golden-image)
    - [Provision EC2 instance](#provision-ec2-instance)
    - [Instance Creation](#instance-creation)

---

## Overview

- `EC Django Deployer` is a streamlined solution designed to simplify the deployment process of Django applications on AWS EC2 instances.
- Ideal for developers looking to deploy Django applications on AWS without the complexities of manual setup.

---

## Features

- **Simplified Deployment:**

  - Requires only two arguments: the name of the Django project and the GitHub repository URL.

- **GitHub Repository Structure:**

  - Enforces a rule for the target Django project's directory structure:
    - The project directory must be located in a direct child subdirectory of the GitHub repository, ensuring a consistent and organized layout.

- **CICD Implementation**:

  - Use AWS `CodeBuild`, `CodePipeline`, and `CodeDeploy` Integration
  - Automates the entire deployment pipeline, from source code changes to EC2 instance provisioning and application deployment.

- **EC2 Instance Provisioning**:
  - Utilizes a predefined `EC2 instance template` with `user data` to host the Django application.
  - Leverages `AWS SDK boto3` to provision infractures.

---

## Use Cases

- **Development Teams**:

  - Facilitates quick and hassle-free deployment of Django projects on AWS for development teams, enabling developers to **focus on coding instead of managing deployment infrastructure**.

- **Solo Developers and Small Projects**:

  - Ideal for solo developers or small projects **with minimal infrastructure requirements**.
  - Offers an efficient and automated solution for deploying Django applications on AWS **without the need for extensive DevOps expertise**.

---

## Demo

- video

- screenshot

---

## Diagram

![diagram](./pic/diagram.png)

- **EC Django Deployer CICD Workflow**:

  - EC Django Deployer developer commits and pushes new version to the GitHub repository, triggering the CICD workflow using CodePipeline, CodeBuild, and CodeDeploy.

- **Target Django Project Deployment Workflow**:

  - 1. Target Django Project owner signs into the EC Django Deployer website with domain name and creates a provision request.
  - 2. Provision request saves the information of the target Django project.
  - 3. A new EC2 instance is provisioned using AWS SDK boto3, predefined AMI, and user data script.

- **Public users access to Target Project**:
  - Once the target project's deployment finishes, public users can access to target project using the EC2 instance's public IP address.

---

## Documentation

### Deployment steps

- This project uses the approach of `Django + Gunicorn + Nginx + Supervisor` to deploy Django project.
- The sequential steps includes:

  - update OS packages
  - upgrade OS packages
  - Install Nginx package
  - Install Supervisor package
  - Install CodeDeploy
  - Install python3-venv
  - Create python virtual environment
  - Install Gunicorn within venv
  - Clone target Django project's GitHub
  - Activate venv
  - Install target project's dependencies
  - Configure Gunicorn
  - Configure Nginx
  - Configure Supervisor
  - Collect static files
  - Migrate database
  - Start gunicorn, ngnix, supervisor

- To improve user experience and automate deployment, the deployment steps should be well-organized:

  - using a `Golden Image` to pre-configure the deployment environment.
  - using `user data` script to automate deployment configuration when an EC2 instance is provisioned.

- Deconstruction steps:
  - **Golden Image**:
    - includes only the required packages.
    - Not includes creation of env, because each push of CICD might required new env.
    - include the log file of creating the Image
    - key steps:
      - update OS packages
      - upgrade OS packages
      - Install Nginx package
      - Install Supervisor package
      - Install CodeDeploy
      - Install python3-venv
  - **user data** of provision EC2:
    - include the log file of deploying app
    - key steps:
      - Create python virtual environment
      - Install Gunicorn within venv
      - Clone target Django project's GitHub
      - Activate venv
      - Install target project's dependencies
      - Configure Gunicorn
      - Configure Nginx
      - Configure Supervisor
      - Collect static files
      - Migrate database
      - Start gunicorn, ngnix, supervisor

---

### Create a Golden Image

- The Golden Image contains:

      - update and upgrade OS packages
      - Install CodeDeploy package
      - Install Nginx, Supervisor, python3-venv package

- To create the Golden Image, a user data script is created:

  - Bash script: [userdata_image.sh](./user_data/userdata_image.sh)

---

### Provision EC2 instance

- Use user data to customize deployment for each Django project.

- The steps includes:

  - Create python virtual environment
  - Install Gunicorn within venv
  - Clone target Django project's GitHub
  - Install target project's dependencies
  - Configure Gunicorn
  - Configure Nginx
  - Configure Supervisor
  - Collect static files
  - Migrate database
  - Start gunicorn, ngnix, supervisor

- Bash script: [userdata_provision.sh](./scripts/userdata_provision.sh)

- To improve development efficiency, scripts must be consistent for
  - deployment of the current app ECDjangoDeployer
  - CodeDeploy configuration of the current app ECDjangoDeployer
  - provision of target Django instance

---

### Instance Creation

- **Create or update instance record**

  - The model to store EC2 instance includs instance_id field which is the ID of the launched EC2 instance. This ID is available only when the EC2 instance has been launched.

  - To save or update an Instance in the table, it needs to
    - save or update the data first,
    - then wait until untill the instance id is available,
    - and finally save the instance id.

```py
  def post(self, request, *args, **kwargs):

        form = self.form_class(request.POST)
        if form.is_valid():

            # Creates new instance record
            obj, created = Instance.objects.update_or_create(
                name=form.cleaned_data["name"],
                github_url=form.cleaned_data["github_url"],
                project_name=form.cleaned_data["project_name"],
                description=form.cleaned_data["description"],
            )

            # code block to create ec2 instance

            # get the instance id when it is created
            obj.instance_id = ec2[0]["instance_id"]

            # update the instance id with record
            obj.save()

            # redirect to the detail page
            return redirect("ECDeploy:detail", pk=obj.pk)

        return render(request, self.template_name, {"form": form})

```

---

- Using boto3 to create EC2 instance with user data

---

---

[TOP](#ec-django-deployer)
