from typing import Any, Dict
from django.views.generic import TemplateView
from django.contrib.auth import views as auth_views
from django.contrib.auth.mixins import LoginRequiredMixin


class LoginView(auth_views.LoginView):

    template_name = 'Account/login.html'

    def get_context_data(self, **kwargs: Any) -> Dict[str, Any]:
        context = super().get_context_data(**kwargs)
        context["title"] = "Login"
        context["heading"] = "Login"
        return context


class ProfileView(TemplateView):
    template_name = "Account/profile.html"

    def get_context_data(self, **kwargs: Any) -> Dict[str, Any]:
        context = super().get_context_data(**kwargs)
        context["title"] = "User profile"
        context["heading"] = "User profile"
        return context
