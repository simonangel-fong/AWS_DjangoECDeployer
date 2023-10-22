from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User

# Sign Up Form


class SignUpForm(UserCreationForm):
    class Meta:
        model = User
        fields = (
            'username',
            'password1',
            'password2',
        )
        widgets = {
            "username": forms.TextInput(
                attrs={"class": "form-control"}
            ),
            "password1": forms.PasswordInput(
                attrs={'class': 'form-control col-md-6', 'type': 'password',
                       'name': 'password', 'placeholder': 'Password'}
            ),
            "password2": forms.PasswordInput(
                attrs={"class": "form-control"}
            )
        }
