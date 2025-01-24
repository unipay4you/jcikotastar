from django.shortcuts import render

from django.http import HttpResponse

def home(request):
   peoples = [
       {'name' : 'Dharmendra Agrawal' , 'age' : 43},
       {'name' : 'Hemlata Agrawal' , 'age' : 42},
       {'name' : 'Bhumik Agrawal' , 'age' : 15},
       {'name' : 'Lavish Agrawal' , 'age' : 10},
   ]

   return render(request , 'home/index.html' , context= {'page' : 'Home','peoples' : peoples})

def about(request):
    context = {'page' : 'About'}
    return render(request , 'home/about.html' , context)

def contact(request):
    context = {'page' : 'Contact'}
    return render(request , 'home/contact.html' , context)

def success_page(request):
    return HttpResponse("<h1>Hey this is a success page</h1>")