from django.urls import path
from .views import SignUpView, LoginView, ProfileView
from django.contrib.auth import views as auth_views
from django.conf import settings

app_name = "Account"

urlpatterns = [

    path("signup/", SignUpView.as_view(), name="signup"),
    path("login/", LoginView.as_view(), name="login"),
    path("logout/", auth_views.LogoutView.as_view(next_page=settings.LOGOUT_REDIRECT_URL), name="logout"),
    path("profile/", ProfileView.as_view(), name="profile"),
]
