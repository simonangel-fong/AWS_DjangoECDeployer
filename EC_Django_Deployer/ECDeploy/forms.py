from django import forms
from .models import Instance
from django.utils.translation import gettext_lazy as _


class InstanceForm(forms.ModelForm):

    class Meta:
        model = Instance
        fields = (
            "name",
            "project_name",
            "github_url",
            "description"
        )
        labels = {
            "name": _("Server Name"),
            "project_name": _("Django Projct Name"),
            "github_url": _("Github Url"),
            "description": _("Project Description"),
        }
        error_messages = {
            "name": {
                "required": _("Server name is required."),
                "unique": _("Server name exists already."),
            },
            "project_name": {
                "required": _("Project name is required."),
            },
            "github_url": {
                "required": _("Github url is required."),
            },
        }
        help_texts = {
            "name": _("The name of server to deploy django project."),
            "project_name": _("The name of django project. (Or the name of the directory where manage.py file locates.)"),
            "github_url": _("The Url of Github repository."),
            "description": _("The description of this project."),
        }

        widgets = {
            "name": forms.TextInput(attrs={
                "class": "form-control"
            }),
            "project_name": forms.TextInput(attrs={"class": "form-control"}),
            "github_url": forms.TextInput(attrs={"class": "form-control"}),
            "domain": forms.TextInput(attrs={"class": "form-control"}),
            "description": forms.Textarea(attrs={"class": "form-control editor", "rows": "3"}),
        }
