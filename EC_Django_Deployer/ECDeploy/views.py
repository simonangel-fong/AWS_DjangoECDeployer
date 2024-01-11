from django.http import JsonResponse
from django.shortcuts import render, redirect
from django.urls import reverse_lazy
from django.views.generic import ListView, CreateView, DetailView, TemplateView, DeleteView
from django.contrib.messages.views import SuccessMessageMixin
from .models import Instance
from .forms import InstanceForm
from pathlib import Path
import json
from .aws_ec2_script import (create_instance_by_template,
                             terminate_instance_by_name, read_user_data_script,
                             list_instance_by_name, list_all_instance)
from django.contrib.auth.mixins import LoginRequiredMixin


SCRIPT_PATH = Path(
    Path(__file__).resolve().parent,
    "script",
    "script_easy_deploy.sh"
)
EC2_TEMPLATE = "EC-Deploy-Template"


class InstanceListView(LoginRequiredMixin, ListView):
    ''' A view to list all EC2 instances '''

    model = Instance
    extra_context = {"title": "Django-EC2 Deployment",
                     "heading": "All Running EC2 Instances"}


class InstanceCreateView(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    ''' A view to create a new EC2 instance '''

    model = Instance
    form_class = InstanceForm
    # success_url = reverse_lazy("ECDeploy:success")
    success_message = 'Instance "%(name)s" was created successfully. Waiting for AWS to response.'
    template_name = "ECDeploy/instance_form.html"
    extra_context = {"title": "Create new EC2 Instance",
                     "heading": "Django Easy Deployment"}

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

            # try:
            # Generates bash script based on given parameters.
            user_data = read_user_data_script(
                SCRIPT_PATH,
                form.cleaned_data["project_name"],
                form.cleaned_data["github_url"],
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
            # except Exception as err:
            #     print(f"{err}")

            # redirect to the detail page
            return redirect("ECDeploy:detail", pk=obj.pk)

        return render(request, self.template_name, {"form": form})


class SuccessView(LoginRequiredMixin, TemplateView):
    ''' A view to display success message. '''

    template_name = "ECDeploy/success.html"
    extra_context = {"title": "Success",
                     "heading": "Success"}


class InstanceDetailView(LoginRequiredMixin, DetailView):
    ''' A view for details of a specified instance '''

    model = Instance
    extra_context = {"title": "EC2 Instance Detail Info",
                     "heading": "EC2 Instance Detail"}


class InstanceTerminateView(LoginRequiredMixin, SuccessMessageMixin, DeleteView):
    ''' A view to terminate a specified instance '''

    model = Instance
    success_url = reverse_lazy("ECDeploy:success")
    # define a success message to display
    success_message = 'Instance "%(name)s" was terminated successfully. Waiting for AWS to response.'
    extra_context = {"title": "Terminate EC2 Instance",
                     "heading": "Terminate EC2 Instance"}

    def get_success_message(self, cleaned_data):
        return self.success_message % dict(
            cleaned_data,
            name=self.object.name,
        )

    def form_valid(self, form):
        # if valid, calls terminate function.
        # try:
        terminate_instance_by_name((self.object.name,))
        # except Exception as err:
        #     print(f"{err}")
        return super().form_valid(form)


def get_instance_info(request, instance_name):
    ''' A Json response to retrieve an instance info '''

    try:
        print(instance_name)
        ec2_list = list_instance_by_name((instance_name,))
        print(ec2_list)
        return JsonResponse({'status': 'success', 'data': json.dumps(ec2_list)}, status=200)
    except Exception as ex:
        return JsonResponse({'status': 'error', 'error': ex}, status=404)


# def get_all_instance_info(request, instance_name):
#     ''' A Json response to retrieve all instances info '''

#     try:
#         print(instance_name)
#         ec2_list = list_all_instance()
#         print(ec2_list)
#         return JsonResponse({'status': 'success', 'data': json.dumps(ec2_list)}, status=200)
#     except Exception as ex:
#         return JsonResponse({'status': 'error', 'error': ex}, status=404)
