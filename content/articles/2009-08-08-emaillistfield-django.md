---
title: EmailListField for Django
published: true
description: A simple Django form field for validating a list of email addresses.
---
Here's a simple Django form field which validates a list of email addresses:

	from email.utils import getaddresses, formataddr

	from django import forms
	from django.utils.translation import ugettext_lazy as _

	class EmailListField(forms.CharField):
		"""
		A Django form field which validates a list of email addresses.
		
		>>> EmailListField().clean('user1@example.com')
		[u'user1@example.com']
		
		>>> EmailListField().clean('User 1 <user1@example.com>, User 2 <user2@example.com>')
		[u'User 1 <user1@example.com>', u'User 2 <user2@example.com>']
		
		>>> EmailListField().clean('invalid email address')
		Traceback (most recent call last):
		  File "<console>", line 1, in <module>
		  File "/home/sciyoshi/chideit/apps/chide/common/mail/forms.py", line 21, in clean
			raise forms.ValidationError(self.error_messages['invalid'])
		ValidationError: [u'Please enter a valid list of e-mail addresses.']
		
		>>> EmailListField().clean('"User 3>" <  "Abc\\@def"@example.com  >, User 2 <$A12345@example.com >  , 3rd guy <!def!xyz%abc@example.com >')
		[u'"User 3>" <"Abc@def"@example.com>', u'User 2 <$A12345@example.com>', u'3rd guy <!def!xyz%abc@example.com>']
		"""
		default_error_messages = {
			'invalid': _('Please enter a valid list of e-mail addresses.')
		}

		def clean(self, value):
			value = super(EmailListField, self).clean(value)

			field = forms.EmailField()

			try:
				return [
					formataddr((name, field.clean(addr)))
				for name, addr in getaddresses([value])]
			except forms.ValidationError:
				raise forms.ValidationError(self.error_messages['invalid'])
