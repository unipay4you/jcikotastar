

from django.contrib import admin
from django.urls import path
from home.views import *
from vege.views import *
from django.conf import *
from django.contrib.staticfiles.urls import *



urlpatterns = [
    path('', home , name="home"),

    path('receipes/', receipes , name="receipes"),
    path('delete-receipe/<id>', delete_receipe , name="delete_receipe"),
    path('update-receipe/<id>', update_receipe , name="update_receipe"),

    path('login/', login_page , name="login_page"),
    path('register/', register , name="register"),
    path('logout/', logout_page , name="logout_page"),

    path('contact/', contact , name="contact"),
    path('about/', about , name="about"),

    path('success-page/', success_page , name="success_page"),
    path('students/', get_students , name="students"),
    path('see_marks/<student_id>', see_marks , name="see_marks"),

    path('base1/', base1, name='base1'),

    path('admin/', admin.site.urls),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root = settings.MEDIA_ROOT)

    
urlpatterns += staticfiles_urlpatterns()
