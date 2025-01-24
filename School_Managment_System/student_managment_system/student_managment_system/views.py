from django.shortcuts import render, redirect, HttpResponse
from app.EmailBackEnd import EmailBackEnd
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from app.models import CustomUser

def BASE(request):
    return render(request, 'base.html')


def LOGIN(request):
    return render(request, 'login.html')


def dologin(request):
    if request.method == 'POST':
        username = request.POST.get('email')
        password = request.POST.get('password')
        

        user = EmailBackEnd.authenticate(request, username = username, password = password,)
        

        if user != None:
           
            login(request, user)
            user_type = user.user_type
           
            if user_type == '1':
                return redirect('hod_home')

            elif user_type == '2':
                return HttpResponse('This is STAFF Panal')

            elif user_type == '3':
                return HttpResponse('This is STUDENT Panal')

            else:
                messages.error(request, "User Type Not Exist")
                return redirect('login')
        
        else:
            messages.error(request, "Username and password not Match")
            return redirect('login')
        
def dologout(request):
    logout(request)
    return redirect('login')


@login_required(login_url='/')
def PROFILE(request):
    return render(request, 'profile.html')

@login_required(login_url='/')
def PROFILE_UPDATE(request):
    if request.method == 'POST':
        profile_pic = request.FILES.get('profile_pic')
        first_name = request.POST.get('first_name')
        last_name = request.POST.get('last_name')
        #email = request.POST.get('email')
        #username = request.POST.get('username')
        password = request.POST.get('password')

        try:
            customuser = CustomUser.objects.get(id = request.user.id)
            customuser.first_name = first_name
            customuser.last_name = last_name
            
            if profile_pic != None and profile_pic != '':
                customuser.profile_pic = profile_pic

            if password != None and password != '':
                customuser.set_password(password)

            customuser.save()
            messages.success(request, 'Profile update successfully')
            return redirect('profile')
        except:
            messages.success(request, 'Profile not update, plz try again...')


    return render(request, 'profile.html')
