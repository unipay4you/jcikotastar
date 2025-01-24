from django.shortcuts import render, redirect
from .models import *
from django.http import HttpResponse
from django.contrib.auth.models import User
from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator
from django.db.models import Q, Sum

from django.contrib.auth import get_user_model

User = get_user_model()

# Create your views here.

@login_required(login_url="/login/")
def receipes(request):
    if request.method == "POST":

        data = request.POST
        receipe_image = request.FILES.get('receipe_image')
        receipe_name = data.get('receipe_name')
        receipe_description = data.get('receipe_description')
        

        Receipe.objects.create(
            receipe_image = receipe_image,
            receipe_name = receipe_name,
            receipe_description = receipe_description,
            )

        return redirect('/receipes/')
    
    queryset = Receipe.objects.all()

    if request.GET.get('search'):
        
        queryset = queryset.filter(receipe_name__icontains = request.GET.get('search'))

    context = {'receipes' : queryset}
    return render(request, 'receipes.html', context)

@login_required(login_url="/login/")
def delete_receipe(request, id):
    queryset = Receipe.objects.get(id = id)
    queryset.delete()
    return redirect('/receipes/')

@login_required(login_url="/login/")
def update_receipe(request, id):
    queryset = Receipe.objects.get(id = id)
    if request.method == "POST":

        data = request.POST
        receipe_image = request.FILES.get('receipe_image')
        receipe_name = data.get('receipe_name')
        receipe_description = data.get('receipe_description')
        
        queryset.receipe_name = receipe_name
        queryset.receipe_description = receipe_description

        if receipe_image:
            queryset.receipe_image = receipe_image
        
        queryset.save()
        return redirect('/receipes/')
    context = {"receipe" : queryset}
    return render(request, 'update_receipes.html', context)


def login_page(request):
     if request.method == "POST":
        data = request.POST
        
        username = data.get('username')
        password = data.get('password')

        user = User.objects.filter(username = username)

        if not user.exists():
            messages.error(request, "User not exist, Plz register first...")
            return redirect('/login/')
        
        user = authenticate(username = username, password = password)
        if user is None:
            messages.error(request, "Username and password not Match")
            return redirect('/login/')
        else:
            login(request, user)
            return redirect('/receipes/')


     return render(request, 'login.html')

def logout_page(request):
    logout(request)
    return redirect('/login/')

def base1(request):
    return render(request, 'base1.html')

def register(request):

    if request.method == "POST":
        data = request.POST
        first_name = data.get('first_name')
        last_name = data.get('last_name')
        username = data.get('username')
        password = data.get('password')

        user = User.objects.filter(username = username)

        if user.exists():
            messages.error(request, "Username already exist/taken.")
            return redirect('/register/')

        user = User.objects.create(
            first_name = first_name,
            last_name = last_name,
            username = username
        )

        user.set_password(password)
        user.save()

        messages.success(request, "User create successfully.")

        return redirect('/register/')


    return render(request, 'register.html')


def get_students(request):
    queryset = Student.objects.all()

    
    if request.GET.get('search'):
        search = request.GET.get('search')

        queryset = queryset.filter(
            Q(student_name__icontains = search) |
            Q(student_id__student_id__icontains = search) |
            Q(department__department__icontains = search) |
            Q(student_age__icontains = search) |
            Q(student_email__icontains = search)
            )

    paginator = Paginator(queryset, 10)  # Show 25 contacts per page.

    page_number = request.GET.get("page")
    page_obj = paginator.get_page(page_number)
    num_pages = paginator.num_pages
    
    context = {
        'queryset' : page_obj,
        'num_pages' : num_pages,
        }
    return render(request, 'report/students.html', context)


def see_marks(request, student_id):
    
    queryset = SubjectMarks.objects.filter(student__student_id__student_id = student_id)
    total_marks = queryset.aggregate(total_marks = Sum('marks'))
    
    context = {
        'queryset' : queryset,
        'total_marks' : total_marks
        }

    return render(request, 'report/see_marks.html', context)

