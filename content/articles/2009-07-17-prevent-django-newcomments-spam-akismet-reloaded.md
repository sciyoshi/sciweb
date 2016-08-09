---
title: Prevent Django newcomments spam with Akismet (reloaded)
published: true
description: How to use Akismet to prevent comment spam using signals in Django's new commenting system.
---
This is a rewrite of my [previous post](http://sciyoshi.com/blog/2008/aug/27/using-akismet-djangos-new-comments-framework/) about preventing spam for Django's new comments framework. By using the [moderation features](http://docs.djangoproject.com/en/dev/ref/contrib/comments/moderation/) that are available, the spam prevention can be done in a much nicer and robust way. Assuming you have an `Entry` model representing blog posts, you can paste the following below it in your `models.py` file:

	from django.contrib.comments.moderation import CommentModerator, moderator
	from django.contrib.sites.models import Site
	from django.conf import settings

	class EntryModerator(CommentModerator):
		def check_spam(self, request, comment, key, blog_url=None, base_url=None):
			try:
				from akismet import Akismet
			except:
				return False

			if blog_url is None:
				blog_url = 'http://%s/' % Site.objects.get_current().domain

			ak = Akismet(
				key=settings.AKISMET_API_KEY,
				blog_url=blog_url
			)

			if base_url is not None:
				ak.baseurl = base_url

			if ak.verify_key():
				data = {
					'user_ip': request.META.get('REMOTE_ADDR', '127.0.0.1'),
					'user_agent': request.META.get('HTTP_USER_AGENT', ''),
					'referrer': request.META.get('HTTP_REFERER', ''),
					'comment_type': 'comment',
					'comment_author': comment.user_name.encode('utf-8'),
				}

				if ak.comment_check(comment.comment.encode('utf-8'), data=data, build_data=True):
					return True

			return False

		def allow(self, comment, content_object, request):
			allow = super(EntryModerator, self).allow(comment, content_object, request)

			# change this depending on which spam provider you want to use
			spam = self.check_spam(request, comment,
				key=settings.AKISMET_API_KEY,
			) or self.check_spam(request, comment,
				key=settings.TYPEPAD_ANTISPAM_API_KEY,
				base_url='api.antispam.typepad.com/1.1/'
			)

			return not spam and allow

	moderator.register(Entry, EntryModerator)

This is more customizable than the signals approach and works well if other moderation features are being used. If you want to make comments that are flagged as spam become hidden instead of deleted, change the allow() method to moderate(). See also the [Django snippet here](http://www.djangosnippets.org/snippets/1638/).