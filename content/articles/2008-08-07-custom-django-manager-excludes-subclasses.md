---
title: Custom Django manager that excludes subclasses
published: true
description: 
---
When you're using Django model inheritance, sometimes you want to be able to get objects of the base class that aren't instances of any of the subclasses. You might expect the obvious way of doing this, `SuperModel.objects.filter(submodel__isnull=True)`, to work, but unfortunately it doesn't. (Neither does `SuperModel.objects.filter(submodel__supermodel_ptr=None)`, or any other convoluted way I could think of doing it.) Here's a nicer approach for doing this:

    from django.db import models, connection
    from django.db.models import signals
    
    class NoSubclassManager(models.Manager):
        """
        Custom manager that excludes subclasses.
        
        >>> class Place(models.Model):
        ...     address = models.CharField(max_length=30)
        ...     objects = models.Manager()
        ...     only = NoSubclassManager()
        ...     def __unicode__(self):
        ...         return self.address
        
        >>> class Restaurant(Place):
        ...     name = models.CharField(max_length=30)
        
        >>> class House(Place):
        ...     owner = models.CharField(max_length=30)
        
        >>> Place(address='123 Acme St.').save()
        >>> Restaurant(address='987 Pizza Rd.', name='PizzaPalace').save()
        >>> House(address='23 Joe Rd.', owner='Joe').save()
        
        # Place.objects gives every single Place, even Restaurants and Houses
        >>> Place.objects.all()
        [<Place: 123 Acme St.>, <Place: 987 Pizza Rd.>, <Place: 23 Joe Rd.>]
        
        # Place.only gives only Places that are neither Restaurants nor Houses
        >>> Place.only.all()
        [<Place: 123 Acme St.>]
        """
        def __init__(self, *args, **kwargs):
            super(NoSubclassManager, self).__init__(*args, **kwargs)
            self.excludes = []
    
        def _class_prepared(self, sender, **kwargs):
            # add the subclass to our list of excluded models
            if self.model in sender._meta.parents:
                self.excludes.append(sender)
    
        def contribute_to_class(self, model, name):
            super(NoSubclassManager, self).contribute_to_class(model, name)
            # connect the signal to pick up on subclasses
            signals.class_prepared.connect(self._class_prepared)
    
        def get_query_set(self):
            qn = connection.ops.quote_name
            return super(NoSubclassManager, self).get_query_set().extra(
                where=['''
                    not exists (
                        select 1
                        from   %s
                        where  %s.%s = %s
                    )
                ''' % (
                    qn(model._meta.db_table),
                    qn(model._meta.db_table),
                    qn(model._meta.pk.column),
                    qn(self.model._meta.pk.column)
                ) for model in self.excludes])