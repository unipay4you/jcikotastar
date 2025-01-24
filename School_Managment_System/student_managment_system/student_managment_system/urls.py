from django.contrib import admin
from django.urls import path
from django.conf import *
from django.conf.urls.static import static
from django.contrib.staticfiles.urls import *

from .import views, hod_views, staff_views, student_views

from django.contrib.auth.decorators import login_required

urlpatterns = [
    path('admin/', admin.site.urls),
    path('base/', views.BASE, name='base'),

    #login
    path('', views.LOGIN, name='login'),
    path('dologin', views.dologin, name='dologin'),
    path('dologout', views.dologout, name='logout'),

    # profile update
    path('profile', views.PROFILE, name='profile'),
    path('profile/update', views.PROFILE_UPDATE, name='profile_update'),


    #HOD Panel URLs
    path('Hod/home', hod_views.HOME, name='hod_home'),


] + static(settings.MEDIA_URL, document_root = settings.MEDIA_ROOT)
