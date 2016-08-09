---
title: Fixing moved subversion repositories when using git-svn
published: true
description: How to handle repository path changes when migrating from Subversion to Git (even if the noMetadata option is used.)
---
This is mostly for my own later reference, and in case anybody finds this of use.

The instructions are based off ones I found [here](http://duncan.mac-vicar.com/blog/archives/282) and [here](http://www.ruby-forum.com/topic/154892), and are simply modified for people who are using the noMetadata option for git-svn. This is useful for one-shot importing from svn to git.

Suppose that the files were moved in revision 100.

1. Fetch all of the unfetched svn revisions up to the point where the move occurred

        git svn init http://svn.example.com/svn --trunk trunk
        git svn fetch --authors-file "$AUTHORS" -r 1:100

2. git-svn init to the path of the trunk/tags/branches on a new svn remote

        git svn init http://svn.example.com/svn -R tmp --trunk project/trunk

3. Edit the .git/config file and replace refs/remotes/git-svn with refs/remotes/tmp-map in the "tmp" svn-remote

4. Fetch the initial revision after the move

        git svn fetch --authors-file "$AUTHORS" -r 100 tmp-map

5. Update the old trunk

        git update-ref $(git rev-parse trunk) $(git rev-parse tmp-map)

6. This is the tricky part if you're using noMetadata; you have to manually edit the git-svn revision db file, you can't remove it and have it get regenerated (since git-svn doesn't store the id's directly in the commits). The binary format is documented [here](https://kerneltrap.org/mailarchive/git/2007/12/9/484643). Here's a Python script that may help:

        #!/usr/bin/python
        import subprocess, binascii, struct
        dbfile = '.git/svn/git-svn/.rev_SVN_REVISION_HERE'
        rev = 100
        ref = subprocess.Popen(['git-rev-parse', 'tmp-map'],
            stdout=subprocess.PIPE).communicate()[0].strip()
        f = open(dbfile, 'a')
        f.write(struct.pack('!i', rev))
        f.write(binascii.hexlify(ref))
        f.close()

7. You can delete the tmp-map branch and the corresponding git-svn info now if you want:

        git branch -r -d tmp-svn
        rm -rf .git/svn/tmp-svn

Hope this helps!