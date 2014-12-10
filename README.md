GitVssInterop
=============

# Description

A Bash script for interop between git and vss

# Purpose
I had to use VSS and I found it was hurting my productivity, I started using Git alongside VSS and found keeping them in synch a chore, so I created some scripts to help

###*Alternative Purpose*
*Alot of the commands* such as **ssclone**, **ssadd**, **ssdelete** and **sscommit** might be useful for anyone who wants to use pure VSS but is more used to git commands. Really all they are is 
VSS command line wrapped up with additional work to adjust for VSS command line style

# Before you start
- You will **need** to [install git](http://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for windows (personally I installed git extensions)
- You *might* want to grab [ConEmu](https://code.google.com/p/conemu-maximus5/) as frankly without it, windows cmd line is almost unusable
- Have quick acces to git bash (for example I have my defult ConEmu set to git bash)

# How To

##Initialisation 
- Open "gitvssinterop.sh" and Modify the correct variables (see [Bash Variables](https://github.com/chrispepper1989/GitVssInterop#bash-variables))
- Add "gitvssinterop.sh" in the method you prefer
  - e.g. open "~/.bashrc" and add source "path/to/gitvssinterop.sh"
- run "ssinit"

At this point you have a git repo with all the SS source code :-)

##General Usuage
The attempt has been to make the syntax familiar to users of git

- use **sspull** to grab the latest from SS and merge with git (its *recommended* you run this inside master or run *masterpullss*)
- use **sspush** to push SS

**NOTE** currently there is nothing stopping you from doing a sspush before sspull and overwriting changes, **make sure you always sspull before sspush**


For the most part you can therefore just use git, I personally use [git-diffall](https://github.com/thenigan/git-diffall) with master and rarely have much to do with source safe. In theory provided you always do an sspull before sspush all merge issues etc will be handled via git


- Use **ssdiff** when you want to double check my scripts are working :-)


As long as you stick to using git and only running these commands you *should'nt* need any of the other commands but see API for if you find yourself stuck


The most likley "fixit" command you will need is 
**ssamend**

#Bash Variables

####Your VSS user name
SSNAME=

####Your source safe project details
CURRENT_SOURCE_SAFE_PROJECT=

*Set to VSS source safe project e.g. : $ProjectFolder (visible in the VSS GUI when folder is selected "Contents of <CURRENT_SOURCE_SAFE_PROJECT>"*
##Where does your project live
PROJ_DIR="/c/Users/you/Documents/Projects/YourProject"

*<TODO: set on ssinit>*

####Your Commit Details

ACTIVE_TRACK_REF=15

PROJECT_NAME=

Currently the VSS comment is created by going:

SS_COMMENT="$PROJECT_NAME - TGR: $ACTIVE_TRACK_REF\n\n" 

in some places and:

SS_COMMENT="$PROJECT_NAME - TGR: $ACTIVE_TRACK_REF  \n\n$GIT_COMMENT"	

in the important place.

Where GIT_COMMENT is *"git log --pretty=format:"%h %s" --no-merges -n 3"*

This way the VSS comment is basically just a summary of your git comments, flavoured with the formal needs of the comment
This is by far the area that needs the most editing that is not currently easily done. *(TODO move comment into a function)*

In my case there is zero requirement for anything other then the TGR number, hence the lack of work

**NOTE** yes its currently geared for TGR, feel free to modify

#API
The attempt has been to make the syntax familiar to users of git and for it to be used with git, however you can use most of the commands without git

##ssamend
This command is for when you have modified something in upstream and want to add it without going through git and sspush.
its **not for amending a comment in the git sense, instead its more of a "I need to add this to SS but I don't want to add it to git" or "oops I have managed to confuse sspush"**

It basically works out what is different locally (git diff HEAD^) and then commits those changes to source safe

##ssclone
This uses ss get to grab all of the code within vss, making it writeable and leaving it "checked in"
*note* this may ask you for a password when it is ran depending on your VSS set up, it should be possible to embed the password *TODO*
##sspush
sspush works out what is different from your repo and "upstream", records it (updateModDelAddVars) (e.g. the folder) and then does a git push. At this point it jumps into "upstream" and runs "ssfullcommit"

##sspull
sspull jumps into "upstream" runs an "ssclone", commits it into git and then jumps back and runs a "git pull"

##ssfullcommit
At this point we knows the difference between SS and our folder, so we run ssadd on all the files that need adding, ssdelete on all the files that need deleting and sscommit on all the modified files

##ssdelete
Deletes files from source safe

##ssadd
Adds files to source safe

##sscommit
Checks the file out of source safe, overwrites it with our copy, checks file into source safe.

##ssdiff
Runs "ss Diff -R" but then transforms it into a more readable output

# Version : V0
I am evolving this as I use it, as such some features may not work "out of the box" as they have been updated after the fact and not updated. I appreciate any issues raised against these, I will at some point start actively unit testing.


#Depreciated Bash Variables
Originally when using the branch method I created a way of doing "hard diffs" this basically grabbed a new clone of SS and used beyondcompare to diff the folders. This hasn't been used in a while because I recommend using ssdiff instead and normal [git-diffall](https://github.com/thenigan/git-diffall) when you want to do a folder compare. 

##Your BeyondCompare Session
It's better to create a beyond compare session so you can set it up how you like, basically when you use beyondcompare you can save a "session" that keeps all your settings. So if you want to do "hard diffs" its a good idea to set this up

BEYOND_COMPARE_SESSION=

For a "hard diff" a new folder needs to be created and ss checked out to it,

REF_APPEND="_REF"


