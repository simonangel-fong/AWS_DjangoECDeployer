from django.urls import path
from .views import (InstanceListView, InstanceCreateView,
                    InstanceDetailView, SuccessView, InstanceTerminateView,
                    get_instance_info)

app_name = "ECDeploy"

urlpatterns = [
    path("list/", InstanceListView.as_view(), name="list"),
    path("create/", InstanceCreateView.as_view(), name="create"),
    path("<int:pk>/detail/",  InstanceDetailView.as_view(), name="detail"),
    path("<int:pk>/terminate/", InstanceTerminateView.as_view(), name="terminate"),
    path("success/", SuccessView.as_view(), name="success"),

    # json url
    path("info/<slug:instance_name>/", view=get_instance_info, name="info"),
    # path("code/<slug:instance_name>/", view=update_code, name="code"),
]
