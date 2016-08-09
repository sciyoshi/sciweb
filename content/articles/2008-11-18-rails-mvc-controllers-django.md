---
title: Rails-like MVC Controllers for Django
published: true
description: A simple example of grouping views in Django in order to be able to easily override functionality.
---
One thing that sometimes annoys me about Django is how views inside an application are simply top-level functions inside the views.py module. This is fine for simple applications, but if you're trying to make anything more complicated this can become a burden. Suppose that a view needs some logic to decide whether or not the logged-in user can access it. If you want to allow this logic to be customized by the person using the application, its much nicer if the views are grouped into a "controller" (similar to how things are done in the Django admin.)

    class Controller(object):
        def view(self, request):
            if not self.can_view(request):
                raise Http404
            # proceed

        def can_view(self, request):
            return True

Subclasses can then override can_view to provide custom behaviors for permission checking.

The problem with the way this is currently done in the Django admin is that the regex-based parsing of URLs is lost, as well as reverse resolving by name.

You can also see this on [DjangoSnippets](http://www.djangosnippets.org/snippets/1204/).

    """
    Helpers for coding in a more MVC-fashion using Controller classes as opposed
    to views.
    """

    from django.shortcuts import get_object_or_404
    from django.contrib.auth.decorators import login_required

    def view(path=None, name=None):
        def decorator(func):
            func.view = True
            func.name = name if name is not None else func.__name__
            func.path = path if path is not None else '^%s/$' % func.name
            return func
        return decorator

    class ControllerMetaclass(type):
        @property
        def _meta(self):
            return self.Meta

        def urls(self, path_prefix=''):
            return [
                (path_prefix + view.path, self.get_handler(view), {}, self._meta.url_prefix + view.name)
            for view in (getattr(self, name) for name in dir(self)) if getattr(view, 'view', False)]

    class Controller(object):
        __metaclass__ = ControllerMetaclass

        def __init__(self, request, *args, **kwargs):
            self.request = request

        @classmethod
        def get_view(cls, view, request, *args, **kwargs):
            return view(cls(request), *args, **kwargs)

        @classmethod
        def get_handler(cls, view):
            def inner(request, *args, **kwargs):
                return cls.get_view(view, request, *args, **kwargs)
            return reduce(lambda func, dec: dec(func), cls._meta.decorators, inner)

        class Meta(object):
            url_prefix = ''
            decorators = []

Place this in a file called `mvc.py`. Now in `views.py`:

    import mvc

    class MyController(mvc.Controller):
       @mvc.view('myview/$', 'myview')
       def my_view(self):
           # do something with self.request
           return HttpResponse('something')

       class Meta(mvc.Controller.Meta):
           url_prefix = 'mycontroller-'

In `urls.py`:

    from . import views

    urlpatterns = patterns('',
        # ... other urls here ...
        *views.MyController.urls(r'prefix/')
    )

Then the view `MyController.my_view` will be accessible from `'prefix/myview/'` and have the name `'mycontroller-myview'`, i.e. `reverse('mycontroller-myview')` will work as expected.