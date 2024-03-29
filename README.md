# Django ECDeployer

- [Django ECDeployer](#django-ecdeployer)
  - [Overview](#overview)
  - [Features](#features)
  - [Use Cases](#use-cases)
  - [Demo](#demo)
  - [Diagram](#diagram)
  - [Documentation](#documentation)
    - [Deployment Overview](#deployment-overview)
    - [How to save EC2 Instance Information in the Database](#how-to-save-ec2-instance-information-in-the-database)
    - [How to provision EC2 Instance to host Django project](#how-to-provision-ec2-instance-to-host-django-project)
      - [Create a Golden Image](#create-a-golden-image)
      - [Create a Launch Template](#create-a-launch-template)
    - [Provision EC2 using boto3](#provision-ec2-using-boto3)
    - [How to deploy this project](#how-to-deploy-this-project)
      - [Create an EC2 Instance as this project's server](#create-an-ec2-instance-as-this-projects-server)
      - [Create `.env` file and configure boto3 on EC2 Instance](#create-env-file-and-configure-boto3-on-ec2-instance)
      - [Implement Continuous Integration and Deployment (CICD)](#implement-continuous-integration-and-deployment-cicd)

---

## Overview

- `Django ECDeployer` is a streamlined solution designed to simplify the deployment process of Django applications on `AWS EC2 instances`.
- Ideal for developers looking to deploy Django applications on AWS without the complexities of manual setup.

---

## Features

- **CICD Implementation**:

  - This project uses AWS `CodeBuild`, `CodePipeline`, and `CodeDeploy` Integration
  - Automates the entire deployment pipeline, from source code changes to EC2 instance provisioning and application deployment.

- **Simplified Deployment:**

  - To simplify the Django project deployment, users are required to provide only two key arguments:
    - the **name of the Django project**
    - and the **GitHub repository URL**.

- **GitHub Repository Structure:**

  - This project enforces a rule for the target Django project's directory structure:
    - The project directory must be located in a direct child subdirectory of the GitHub repository, ensuring a consistent and organized layout.

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

- video:

  - [Project Demo: Django ECDeployer (Django+Bootstrap+AWS)](https://youtu.be/-J_D7dRdriU)

- Deploy a Django project just in less than 2 minutes.

---

## Diagram

![diagram](./pic/diagram.png)

- **EC Django Deployer CICD Workflow**

  - EC Django Deployer developers commit and push a new version to the GitHub repository, triggering the CICD workflow using CodePipeline, CodeBuild, and CodeDeploy.

- **Target Django Project Deployment Workflow**

  1. The Target Django Project owner signs into the Django ECDeployer website with a domain name and creates a provisioning request.
  2. The provisioning request saves the information of the target Django project.
  3. A new EC2 instance is provisioned using AWS SDK boto3, a predefined AMI, and a user data script.

- **Public Users' Access to the Target Project**
  - Once the deployment of the target project finishes, public users can access the target project using the EC2 instance's public IP address.

---

## Documentation

### Deployment Overview

- This project utilizes the `Django + Gunicorn + Nginx + Supervisor` approach to deploy Django projects.
- The sequential steps include:

  - Update OS packages
  - Upgrade OS packages
  - Install Nginx package
  - Install Supervisor package
  - Install CodeDeploy
  - Install python3-venv
  - Create a Python virtual environment
  - Install Gunicorn within the virtual environment
  - Clone the target Django project's GitHub repository
  - Install the target project's dependencies
  - Configure Gunicorn
  - Configure Nginx
  - Configure Supervisor
  - Migrate the database
  - Restart Gunicorn, Nginx, Supervisor

- To enhance the user experience and automate deployment, the deployment steps should be well-organized:

  - Utilize a `Golden Image` to pre-configure the deployment environment.
  - Use a `user data` script to automate deployment configuration when an EC2 instance is provisioned.

- The use of a **Bash script** is helpful for automating the deployment steps.

---

### How to save EC2 Instance Information in the Database

- When users initiate the deployment process by clicking the "create" button, the project not only provisions EC2 instances but also intelligently records essential details in the database.

- **Implementation Steps**

  - **Django Class-Based View**:

    - The project employs Django's class-based views, specifically overriding the post function, to handle deployment requests.
    - Upon successful form validation, deployment information is prepared for storage.

  - **Database Storage**:
    - Utilizing Django's `update_or_create()` function, the project securely saves the deployment details into the database.
    - When EC2 instances are provisioned accordingly leveraging the AWS SDK boto3, the instance ID are saved into the database.

- **Code**:

```py
def post(self, request, *args, **kwargs):
    # get the form
    form = self.form_class(request.POST)

    # check if the form is valiated
    if form.is_valid():

        # Creates new instance record
        obj, created = Instance.objects.update_or_create(
            name=form.cleaned_data["name"],
            github_url=form.cleaned_data["github_url"],
            project_name=form.cleaned_data["project_name"],
            description=form.cleaned_data["description"],
        )

        # Creates an new EC2 instance
        ec2 = create_instance_by_template(
            EC2_TEMPLATE,
            form.cleaned_data["name"],
            user_data
        )

        # get the instance id when it is created
        obj.instance_id = ec2[0]["instance_id"]

        # update the instance id with record
        obj.save()

        # redirect to the detail page
        return redirect("ECDeploy:detail", pk=obj.pk)

    return render(request, self.template_name, {"form": form})

```

---

### How to provision EC2 Instance to host Django project

#### Create a Golden Image

- To improve the performance of provision, this project create a golden image.
- The Golden Image contains:

  - update and upgrade OS packages
  - Install CodeDeploy package
  - Install Nginx, Supervisor, python3-venv package

- To create the Golden Image, a user data script is created:

  - Bash script: [userdata_image.sh](./user_data/userdata_image.sh)

- Create an EC2 instance for golden Image and check the log.

![golden_image03](./pic/golden_image03.png)

- Save the image as a Golden Image

![golden_image01](./pic/golden_image01.png)

![golden_image02](./pic/golden_image02.png)

---

#### Create a Launch Template

- using the Golden Image

![golden_image01](./pic/golden_image01.png)

![golden_image02](./pic/golden_image02.png)

---

### Provision EC2 using boto3

- This project defines custom functions using the AWS SDK boto3 to provision EC2 instance to host user's Django project.
  - [aws_ec2_script.py](./EC_Django_Deployer/ECDeploy/aws_ec2_script.py)
  - using launch template
  - boto3 function `create_instances()`
  - return the instance's information such as ID, public IP, and etc.

```py
def create_instance_by_template(launch_template_name, instance_name=None, user_data=None):
    ''' Creates an instance from a launch template '''

    if launch_template_name == None:
        raise ValueError("Parameter launch_template_name is required.")
    else:
        ec2 = boto3.resource(
            service_name='ec2',
            region_name='us-east-1'
        )
        ec2_list = ec2.create_instances(
            # launch template
            LaunchTemplate={
                "LaunchTemplateName": launch_template_name
            },
            # name tag
            TagSpecifications=[
                {
                    'ResourceType': 'instance',
                    'Tags': [
                        {
                            'Key': 'Name',
                            'Value': instance_name
                        },
                    ]},
            ],
            MinCount=1,
            MaxCount=1,
            UserData=user_data,
        )
        return [
            {
                "instance_id": instance.instance_id,
                "public_ip": instance.public_ip_address,
                "status": instance.state["Name"],
                "launch_time": instance.launch_time.strftime("%Y-%m-%d %H:%M:%S")
            }
            for instance in ec2_list
        ]
```

- This project also create a user data template that custom functions will overwrite to provision EC2 intance based on user's parameters.
  - [userdata_boto3.sh](./EC_Django_Deployer/ECDeploy/userdata_boto3.sh)

---

### How to deploy this project

#### Create an EC2 Instance as this project's server

- Using Launch Template
- Using Golden Image

![instance01](./pic/instance01.png)

![instance02](./pic/instance02.png)

![instance03](./pic/instance03.png)

---

#### Create `.env` file and configure boto3 on EC2 Instance

- For security season, the credential data are stored within a `.env` file.
- Using SSH connect or SSM to create this file.

![env_file01](./pic/env_file01.png)

- Install AWS CLI

- configure boto3 on EC2 Instance

---

#### Implement Continuous Integration and Deployment (CICD)

- This project employs `CodePipeline`, `CodeBuild`, and `CodeDeploy` to implement **CICD**.

- **AWS CodeDeploy application specification files**

  - This project implements a robust Continuous Integration and Deployment (CICD) pipeline using `AWS CodeDeploy`. The deployment process is defined by an `appspec.yml` file, which orchestrates the following three main phases:

  1. [BeforeInstall.sh](./CodeDeploy/BeforeInstall.sh)

     - Removes the existing virtual environment directory and GitHub repository directory.
     - Ensures a clean slate before the new deployment.

  2. [AfterInstall.sh](./CodeDeploy/AfterInstall.sh)

     - Creates a virtual environment.
     - Installs project dependencies and Gunicorn.
     - Configures Gunicorn, Nginx, and Supervisor.
     - Sets up the necessary environment for the application.

  3. [ApplicationStart.sh](./CodeDeploy/ApplicationStart.sh)
     - Handles tasks like migrating the database for Django.
     - Restarts the service to apply the changes.
     - Ensures a smooth transition to the updated version of the application.

  - **Deployment Logging**

    - To facilitate troubleshooting and traceability, a detailed log file named `deploy.log` is created in the `/home/ubuntu/log` directory.
    - This log captures key steps during the deployment process, providing valuable insights into the CICD pipeline.
    - In case of any issues during the deployment, consult the `deploy.log` file for a comprehensive record of the deployment steps.

![pipeline04](./pic/pipeline04.png)

- Create a `AWS CodePipeline`

![pipeline01](./pic/pipeline01.png)

- Push local code to GitHub and trigger Deployment

![pipeline02](./pic/pipeline02.png)

- Visit the public IP of the server

![pipeline03](./pic/pipeline03.png)

- Now this project has been deployed on the EC2 instance.

---

[TOP](#django-ecdeployer)
