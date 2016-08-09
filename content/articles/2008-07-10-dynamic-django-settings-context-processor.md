---
title: Dynamic Django settings context processor
published: true
description: 
---
Here's a nice way of easily passing only certain settings variables to the template. Because of the way Django looks up context processors, we need a little hack with sys.modules.

    import sys

    from django.conf import settings as django_settings

    class SettingsProcessor(object):
        def __getattr__(self, attr):
            if attr == '__file__':
                # autoreload support in dev server
                return __file__
            else:
                return lambda request: {attr: getattr(django_settings, attr)}

    sys.modules[__name__ + '.settings'] = SettingsProcessor()

Assuming this is placed in a file called `utils/context_processors.py`, you can use this from the settings.py file like so:

    TEMPLATE_CONTEXT_PROCESSORS = (
        # ....
        'utils.context_processors.settings.GOOGLEMAPS_KEY',
        'utils.context_processors.settings.TEMPLATE_DEBUG',
        'utils.context_processors.settings.MAXMIND_URL',
    )

Nice and simple.