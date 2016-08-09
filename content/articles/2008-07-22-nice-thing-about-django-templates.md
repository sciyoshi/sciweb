---
title: The nice thing about Django templates
published: true
description: 
---
There's "polymorphism":

In `a.html`:

    {% block outer %}
        This is the outer block.
        {% block inner %}
        {% endblock %}
    {% endblock %}

In `b.html`:

    {% extends 'a.html' %}

    {% block outer %}
        This is the subtemplate.
        {{ block.super }}
    {% endblock %}

    {% block inner %}
        This is the inner block.
    {% endblock %}

This will render as expected (`block.super` will contain the inner block of the child template as well).