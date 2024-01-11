from pathlib import Path
import boto3
from asgiref.sync import sync_to_async


def read_user_data_script(script_path, project_name, github_url, mysql_user=None, mysql_pwd=None, db_name=None, domain_name=None):
    ''' Reads bash script from a script file and inject key data. '''

    user_data = ""
    try:
        with open(script_path) as f:
            user_data = f.read()
    except Exception as ex:
        raise ex
    else:
        user_data = user_data.replace("py_project_name", project_name)
        user_data = user_data.replace(
            "py_repo_name", github_url[:-4].split("/")[-1])
        user_data = user_data.replace("py_github_url", github_url)

        return user_data


def list_all_instance():
    ''' Lists all running instances. '''

    ec2 = boto3.resource(
        service_name='ec2',
        region_name='us-east-1'
    )
    filters = [
        {
            "Name": "instance-state-name",
            'Values': ['running', "pending"]
        }
    ]
    ec2_list = ec2.instances.filter(Filters=filters)

    # helping function to filter data, keep it for future version
    def getNameTag(tag_dict):
        if tag_dict["Key"] == "Name":
            return True
        else:
            return False

    return [
        {
            "instance_id": instance.instance_id,
            "public_ip": instance.public_ip_address,
            "status": instance.state["Name"],
            "launch_time":instance.launch_time.strftime("%Y-%m-%d %H:%M:%S")
        }
        for instance in ec2_list
    ]


def list_instance_by_name(name_list):
    ''' Lists running or stopped instances within a name list. '''

    ec2 = boto3.resource(
        service_name='ec2',
        region_name='us-east-1'
    )
    filters = [
        {
            'Name': 'instance-state-name',
            'Values': ['running', "pending", 'stopped']
        },
        {
            'Name': 'tag:Name',
            'Values': name_list
        },
    ]
    ec2_list = ec2.instances.filter(Filters=filters)

    # helping function to filter data, keep it for future version
    def getNameTag(tag_dict):
        if tag_dict["Key"] == "Name":
            return True
        else:
            return False

    return [
        {
            "instance_id": instance.instance_id,
            "public_ip": instance.public_ip_address,
            "status": instance.state["Name"],
            "launch_time":instance.launch_time.strftime("%Y-%m-%d %H:%M:%S")
        }
        for instance in ec2_list
    ]


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
                "launch_time":instance.launch_time.strftime("%Y-%m-%d %H:%M:%S")
            }
            for instance in ec2_list
        ]


def stop_instance_by_name(name_list):
    ''' Stop running instances within a name list. '''

    ec2 = boto3.resource(
        service_name='ec2',
        region_name='us-east-1'
    )
    filter = [
        {
            'Name': 'instance-state-name',
            'Values': ['running', 'stopped']
        },
        {
            'Name': 'tag:Name',
            'Values': name_list
        },
    ]
    instances = ec2.instances.filter(Filters=filter)
    return instances.stop()


def terminate_instance_by_name(name_list):
    ''' Terminates running instances within a name list. '''

    if name_list == None:
        raise ValueError("Parameter name_list is required.")
    else:

        ec2 = boto3.resource(
            service_name='ec2',
            region_name='us-east-1'
        )
        filter = [
            {
                'Name': 'instance-state-name',
                'Values': ['running', 'stopped']
            },
            {
                'Name': 'tag:Name',
                'Values': name_list
            },
        ]
        instances = ec2.instances.filter(Filters=filter)
        return instances.terminate()
