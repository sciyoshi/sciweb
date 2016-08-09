---
title: Using Akismet/TypePad AntiSpam with Django's new comments framework
published: true
description: 
---
I've just recently started getting lots of spam in my comments. I was originally using a custom OpenID-enabled commenting app that I had written, but decided to switch to the new Django commenting system since it looked interesting. The honeypot doesn't seem to be working though, because spam's still getting through...

Although `django-comment-utils` provides similar functionality, it hasn't yet been updated to use the new `django.contrib.comments`. For those of you that are interested, here's how you can use Akismet to protect your blog.

*UPDATE: TypePad's AntiSpam service is 100% API compatible with Akismet, so the code below works nicely with it as well.*

Sign up at Wordpress to get your API key for Akismet. Paste it into your settings file:

    AKISMET_API_KEY = 'your-key-here'

If you'd rather use TypePad's AntiSpam service, paste instead the following:

    TYPEPAD_ANTISPAM_API_KEY = 'your-key-here'

Download the [Python Akismet module](http://www.voidspace.org.uk/python/akismet_python.html) and put `akismet.py` somewhere on your `PYTHONPATH`.

Now paste the following code into any file that gets imported from your Django project. I'm using my own custom blog app, so this went at the end of my blog's `models.py` file.

    from django.contrib.comments.signals import comment_was_posted

    def on_comment_was_posted(sender, comment, request, *args, **kwargs):
        # spam checking can be enabled/disabled per the comment's target Model
        #if comment.content_type.model_class() != Entry:
        #    return

        from django.contrib.sites.models import Site
        from django.conf import settings

        try:
            from akismet import Akismet
        except:
            return

        # use TypePad's AntiSpam if the key is specified in settings.py
        if hasattr(settings, 'TYPEPAD_ANTISPAM_API_KEY'):
            ak = Akismet(
                key=settings.TYPEPAD_ANTISPAM_API_KEY,
                blog_url='http://%s/' % Site.objects.get(pk=settings.SITE_ID).domain
            )
            ak.baseurl = 'api.antispam.typepad.com/1.1/'
        else:
            ak = Akismet(
                key=settings.AKISMET_API_KEY,
                blog_url='http://%s/' % Site.objects.get(pk=settings.SITE_ID).domain
            )

        if ak.verify_key():
            data = {
                'user_ip': request.META.get('REMOTE_ADDR', '127.0.0.1'),
                'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                'referrer': request.META.get('HTTP_REFERER', ''),
                'comment_type': 'comment',
                'comment_author': comment.user_name.encode('utf-8'),
            }

            if ak.comment_check(comment.comment.encode('utf-8'), data=data, build_data=True):
                comment.flags.create(
                    user=comment.content_object.author,
                    flag='spam'
                )
                comment.is_public = False
                comment.save()

    comment_was_posted.connect(on_comment_was_posted)

This code can be tweaked to delete the comment outright if Akismet or TypePad detects that it's spam - connect instead to the `comment_will_be_posted` signal and return `False`. The flag is created so that a script can go through and periodically delete all spam.

Thanks to [Coulix.net](http://www.coulix.net/blog/2006/oct/07/django-freecomment-spam-protection/) for the original implementation.

*UPDATE*: Fixed encoding issues when sending data to Akismet.
*UPDATE #2*: TypePad AntiSpam support.