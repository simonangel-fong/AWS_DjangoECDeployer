from django.db import models
from django.utils.translation import gettext_lazy as _
from django.urls import reverse_lazy


class Instance(models.Model):

    name = models.SlugField(max_length=50, unique=True)
    project_name = models.CharField(max_length=256)
    github_url = models.URLField(max_length=200)
    description = models.TextField(default="")
    instance_id = models.CharField(max_length=48, default=None, null=True)
    created_date = models.DateTimeField(auto_now_add=True)
    # domain = models.URLField(max_length=200, default=None, null=True)

    def __str__(self):
        return f"{self.name}"

    def get_absolute_url(self):
        return reverse_lazy("ECDeploy:detail", kwargs={"pk": self.pk})

    class Meta:
        ordering = ["-name"]
