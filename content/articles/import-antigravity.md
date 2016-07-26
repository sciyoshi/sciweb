---
title: import antigravity
---

I was looking through Python 3.0's standard library today (/usr/lib/python30/) to see what had changed, and found this interesting tidbit: apparently, "`import antigravity`" now works, and opens up a web browser pointing to the classic XKCD comic. Doesn't seem like this has been backported to 2.6 yet :-). I guess that's another nice easter egg to add to the list, along with `import this` and `from __future__ import braces`. Note that, ironically, since `print`s need parentheses now, the code in the comic won't actually work in Python 3.0.

Also, here's the SVN changeset where antigravity was implemented in Python.