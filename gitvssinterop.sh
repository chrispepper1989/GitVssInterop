#Directory version is currently the recommended and supported version
#However the branch version has the benifits of less space required
#But the directory aproach is less complicated and also automatically 
#strips source safe references for the git repo, which reduces confusion for VStudio 

alias sspush=sspushDir
alias sspull=sspullDir
alias ssinit=ssinitDir

alias sspushDiffFrom="sspushDiffFromDir"
alias ssclone="ss get "$CURRENT_SOURCE_SAFE_PROJECT" -W -R -Q -Y$SSNAME -I-N"
alias ssdelete="ss Delete "$DELETED_FILES" -Y$SSNAME -I-N"
alias initgitss=ssinit

#----These Need Setting:
##Your VSS user name
SSNAME=

##Your source safe project details
CURRENT_SOURCE_SAFE_PROJECT=
PROJ_DIR="/c/you/ukcpep/Documents/Projects/YourProject"

##Your Commit Details
ACTIVE_TRACK_REF=15
PROJECT_NAME=



#----SysVars
CURRENT_PROJ_DIR=
GIT_POSTFIX="_git"
GIT_DIR=$PROJ_DIR$GIT_POSTFIX
SOURCE_SAFE_POSTFIX="_SSUpstream"
SOURCE_SAFE_DIR=$PROJ_DIR$SOURCE_SAFE_POSTFIX


#---colours
red='\e[0;31m'
lred='\e[1;31m'
green='\e[0;32m'
lgreen='\e[1;32m'
NC='\e[0m'#NoColor

#----Depreciated SysVars
REF_APPEND="_REF"
##Your BeyondCompare Session
#its better to create a beyond compare session so you can set it up how you like
BEYOND_COMPARE_SESSION=
alias bcompare="START / \"C:\Program Files (x86)\Beyond Compare 3\BCompare.exe\""
#---functions
ssdiff()
{
	ss Diff -R > SSDiffReport.txt
	INPUT="SSDiffReport.txt"
	
	echo -e "\e[0m---"
	
	CHAR="     D "
	echo -e "Local Files Missing From SS Project:$red"
	extractBetween "Local files not in the current project:" "Diffing:" "SourceSafe files not in the current folder:" "SourceSafe files different from local files:" 
	echo -e "\e[0m---"
	
	CHAR="     A "
	echo -e "SourceSafe files Missing From Local :$lred"
	extractBetween "SourceSafe files not in the current folder:" "Diffing:" "Local files not in the current project:" "SourceSafe files different from local files:"
	echo -e "\e[0m---"
	
	CHAR="     M "
	echo -e "Modifed Local Files: $green"
	extractBetween "SourceSafe files different from local files:" "Diffing:" "Local files different from local files:" "SourceSafe files not in the current folder:"
	
	CHAR="     m "
	echo -e "\e[0m---"
	echo -e "Modified Source Safe Files: $lgreen"
	extractBetween "Local files different from local files:" "Diffing:" "SourceSafe files different from local files:" "SourceSafe files not in the current folder:"
	
	echo -e "\e[0m---"
	rm SSDiffReport.txt

}

extractBetween()
{
	 #sed -n "/Local/,/Diffing/p" $INPUT | sed s/'Local files not in the current project:'/start/ | sed s/'Diffing:'/end/
	 sed -n "/$1/,/$2/p" $INPUT | sed -n "/$1/,/$3/p" | sed s/"$1"// | sed s/"$2"// | sed s/"$3"// | sed s/"$4"// |  sed s/"Project"// |  sed s/"has"//  | sed s/"no"// | sed s/"(Can't open)"// | sed s/"corresponding"// | sed s/"folder"// |  tr ' ' '\n' | sed '/^$/d' |  sed -e 's/^[ \t]*//' | sed  s/^/"$CHAR"/ 

}
#--variable set up helper 
sset()
{
	if [ $# -eq 0 ]
	  then
		echo "No arguments supplied, please supply the SS project name"
	fi
	
	CURRENT_SOURCE_SAFE_PROJECT=$1
	CURRENT_PROJ_DIR=$(pwd)
}
#---reset to current project
ssreset()
{
	echo "Make sure we are in the correct source safe project"
	ss CP $CURRENT_SOURCE_SAFE_PROJECT
	ss project
}
#quiet reset
ssresetq()
{
	ss CP $CURRENT_SOURCE_SAFE_PROJECT -O-
}



#----Commit *one file* -that is already added- to SS----#
sscommitone()
{

	FULLPATH=$1
	DIR=$(echo ${FULLPATH%/*})
	
	SS_COMMENT="$PROJECT_NAME - TGR: $ACTIVE_TRACK_REF\n\n"
	
	#go to correct place in working directory 
	
	
	if [ ! -n "$DIR" ]; then
		DIR="."		
	fi
	
	pushd $DIR
	
	#checkout file without overwriting local copy
	#echo Y | ss checkout "$FULLPATH" -G-WR -Y$SSNAME
	ss checkout "$FULLPATH" -G-WR -Y$SSNAME -I-Y
	#check in the file with comment
	#echo Y | ss checkin "$1" -C"$SS_COMMENT" -W -Y$SSNAME	
	ss checkin "$1" -C"$SS_COMMENT" -W -Y$SSNAME -I-Y	
	#go back to the directoy we were in -root-
	popd
	
}

#-------*todo* use these instead of reset & cp
pushcp()
{
	OLD_PROJECT=$(ss project)
	ss cp $1
}
popcp()
{
	ss cp $OLD_PROJECT
}
function trycp()
{
    local  __resultvar=$1
    local  myresult=$(pushcp $directory 2>&1 | grep -c 'exist' 2>&1)
    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$myresult'"
    else
        echo "$myresult"
    fi
}
#----bulk commit---#
sscommit()
{
	echo "Sanity check"
	for file in $@; do
		echo "Modify file $file"
	done
	
	for file in $@; do
		sscommitone $file
	done
}
#----bulk add-----#
ssadd()
{
	printf "\n\nAdding files requires us to loop, so we can add to the correct directory"

	echo "Sanity check"
	for file in $@; do
		echo "Add file $file"
	done
	
	for file in $@; do

	printf "\n--Resetting Dir---\n"
	ssresetq
	printf " ----\n\n"
	new_file=$(echo ${file##*/})
	directory=$(echo ${file%/*})


	#cp to folder
	echo "Directory is: $directory"
	ssresetq
	test=$(ss CP $directory 2>&1 | grep -c 'exist' 2>&1)


	if (( "1"== $test )); 
	then
	echo "Did not to find directory! It does not exist!....yet";

	new_directory=$directory;
	last_directory=$directory;
	while (( "1"== $test )); 
	do
		echo "->This parent directory does not exist, try going up";
		echo "---trying to cp to $new_directory"
		last_directory=$(echo ${new_directory})
		new_directory=$(echo ${new_directory%/*})

		ssresetq
		test=$(ss CP $new_directory 2>&1 | grep -c 'exist' 2>&1)
		
		echo "[+]"
	done

	echo "Directory does not exit, need to add $last_directory";
	ss Add $last_directory -R -C"$SS_COMMENT" -Y$SSNAME -I-N

	else
	echo "Directory already exist, need to add file: ${file}";
	ss Add $file -C"$SS_COMMENT" -Y$SSNAME -I-N
	fi 
	
	
	ssresetq

	done
	
	echo "exit loop"

}

#use this function for when mistakes are made during push/pull
ptgr()
{
	updateModDelAddVars $1
	printDiffInfo
}
#--- vars needed for to perform ss operations ----
updateModDelAddVars()
{
	#files to check out and in again from SS
	MODIFIED_FILES=$( git diff --name-only $1  --diff-filter=M) 
	#files to add to SS
	ADDED_FILES=$( git diff --name-only  $1  --diff-filter=A) 
	#file to delete from SS
	DELETED_FILES=$( git diff --name-only  $1  --diff-filter=D) 
}

printDiffInfo()
{
	printf "Please update your bug/feature tracker with the following changed files:"
	printf " \n***********************\n"
	printf "|--Modified Files --\n\n"
	printf "$MODIFIED_FILES"
	printf " \n--\n"
	printf "|--New Files --\n\n"
	printf "$ADDED_FILES"
	printf " \n--\n"
	printf "|--Deleted Files --\n\n"
	printf "$DELETED_FILES"
	printf " \n\n ********************* \n"
}



##------Pull
sspullBranch()
{
	if [ ! -d ".git" ]; then
	  echo "Must be ran from root git/ss rep"
	  exit;
	fi
	
	#save branch we are on
	BRANCH=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
	
	
	
	#jump to "fake upstream"
	
	git checkout vss_branch
	
	#update vss branch to match vss..	
	echo "grabbing all files from sourcesafe"
	ssclone
	
	##figure out files I have changed
	FILES=$( git diff --name-only master vss_branch) 
	
	##grab the recent history for those files & everything else seperately	
	NOW=$(date)
	SSFILEHISTORY=$(ss History . $FILES -#3)
	SSHISTORY=$(ss History . -#3)
	
	##now add & commit those files with a comment
	git add --all	
	MESSAGE=$(echo -e "Source safe sync: $NOW \n Changes to my files: \n $SSFILEHISTORY  \nChanges To Other Files:\n $SSHISTORY")
	git commit -a -m"$MESSAGE"
	
	
	#jump back to branch that wants to pull
	git checkout $BRANCH
	git pull	
	
}
#ammend directly within *upstream* (Don't make a habit of using this)
#this is for the specific use case where you have modified something within the upstream folder that you want to add directly to source safe
ssamend()
{
	updateModDelAddVars HEAD^
	ssfullcommit
}
ssfullcommit()
{
	#check the file in with latest git comments but keep files as writeable
	#--TODO-- read -p "Please enter the TGR this commit relates to: " TGR 

	
	#Add each file (and possible directory)
	printf "\n---------------------------------------------------\n"
	printf "Adding new files \n->\n $ADDED_FILES"
	printf "\n---------------------------------------------------\n"
	SS_COMMENT="$PROJECT_NAME - TGR: $ACTIVE_TRACK_REF  \n\n$GIT_COMMENT"	
	ssadd $ADDED_FILES
	
	printf "\n---------------------------------------------------\n"
	printf "Deleting old files \n->\n $DELETED_FILES"
	printf "\n---------------------------------------------------\n"
	ss Delete $DELETED_FILES -Y$SSNAME -I-N
	
	#Loop through the files, checking in and out from correct directory	
	printf "\n---------------------------------------------------\n"
	printf "Overwriting modified files \n->\n $MODIFIED_FILES"
	printf "\n---------------------------------------------------\n" 	
	sscommit $MODIFIED_FILES
}


#--Dir Versions---

#--create a git project from a VSS project and set everything up ---#
#*TODO* test this!
ssinitDir()
{
	if [ -z ${CURRENT_SOURCE_SAFE_PROJECT+x} ]; 
		then echo "CURRENT_SOURCE_SAFE_PROJECT is unset"; 
		exit;
	fi
		
	mkdir $PROJ_DIR
	cd $PROJ_DIR
	mkdir $SOURCE_SAFE_DIR
	
	cd $SOURCE_SAFE_DIR
	
	#get all the SS sourcecode
	echo "Switching to $CURRENT_SOURCE_SAFE_PROJECT"
	ss cp $CURRENT_SOURCE_SAFE_PROJECT	
	ssclone
	"Intial clone" > fullGitHistory.githistory
	ss Add fullGitHistory.githistory -C"Log of all git history"
	
	#init git "upstream"
	git init
	git add --all
	git commit -m "Initial Source Safe Clone"
	
		
	#clone "upstream" into GIT_DIR
	cd ..
	git clone $SOURCE_SAFE_DIR/.git $GIT_DIR
	cd $SOURCE_SAFE_DIR
	
	#create a branch to move to so that pushes can work (git will not allow you to push to a branch that is checked out)
	git checkout -b not_master	
	
	cd ..
	cd $GIT_DIR	
	
}

sspullDir()
{
	if [ ! -d ".git" ]; then
	  echo "Must be ran from root git/ss rep"
	  exit;
	fi
	
	##figure out files I have changed
	FILES=$( git diff --name-only origin/master) 
	
	if [ ! -n "$SOURCE_SAFE_DIR" ]; then
		echo "Source Safe Dir Empty"
		return -1
	fi
	
	#jump to "fake upstream"	
	pushd $SOURCE_SAFE_DIR
	git checkout master
	
	#update vss branch to match vss..	
	echo "grabbing all files from sourcesafe"
	ssclone
	

	
	##grab the recent history for those files & everything else seperately	
	NOW=$(date)
	SSFILEHISTORY=$(ss History . $FILES -#3)
	SSHISTORY=$(ss History . -#3)
	
	##now add & commit those files with a comment
	git add --all	
	MESSAGE=$(echo -e "Source safe sync: $NOW \n Changes to my files: \n $SSFILEHISTORY  \nChanges To Other Files:\n $SSHISTORY")
	git commit -a -m"$MESSAGE"	
		
	#jump back to branch that wants to pull
	git checkout not_master
	popd
	git pull	
	
}
sspushDiffFromDir()
{
	sreset
	if [ ! -d ".git" ]; then
	  echo "Must be ran from root git/ss rep"
	  exit;
	fi
	
	
	
	#get a suitable amount of git master comments for SS comment SS comment IS limted to 500chars though...
	GIT_COMMENT=$(git log --pretty=format:"%h %s" --no-merges -n 3)
	

	#figure out files that need to go into source safe
	updateModDelAddVars $1
	

	
	pushd $SOURCE_SAFE_DIR
	git checkout master
	git log --no-merges > fullGitHistory.githistory
	ssfullcommit
	
	#update git history file -this way SS has all the rich comment history I store with git despite SS's 500 comment character limit-
	
	sscommitone fullGitHistory.githistory
	
	#now print the message needed for the TGR comment
	printTGRInfo
	git checkout not_master
	popd
}

sspushDir()
{
	sspushDiffFromDir origin
	#ok now make origin up to date -this keeps git happy :)-
	git push

}

#---Branch versions---
ssinitBrach()
{
	
	if [ -z ${CURRENT_SOURCE_SAFE_PROJECT+x} ]; 
		then echo "CURRENT_SOURCE_SAFE_PROJECT is unset"; 
		exit;
	fi
	
	git init

	#get all the SS sourcecode
	echo "Switching to $CURRENT_SOURCE_SAFE_PROJECT"
	ss cp $CURRENT_SOURCE_SAFE_PROJECT

	ssclone
	"Intial clone" > fullGitHistory.githistory
	ss add fullGitHistory.githistory -C"Log of all git history"
	
	git add --all
	git commit -m "Initial Source Safe Clone"
	#create fake upstream
	git checkout -b vss_branch
	#create a dev branch
	git checkout -b dev
	git checkout master
	#set master to treat "vss_branch" as upstream
	git branch --set-upstream-to vss_branch
	SynchMasterToSS
	
}
sspushBranch()
{
	if [ ! -d ".git" ]; then
	  echo "Must be ran from root git/ss rep"
	  exit;
	fi
	
	BRANCH=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
	
	##-TODO- check for git error at checkout attempt instead!
	##we might have some work uncommitted (naughty) 
	##git stash
	
	#get a suitable amount of git master comments for SS comment SS comment IS limted to 500chars though...
	GIT_COMMENT=$(git log --pretty=format:"%h %s" --no-merges -n 3)
	git log --no-merges > fullGitHistory.githistory

	#figure out files that need to go into source safe
	updateModDelAddVars vss_branch
	
	#ok now make vss_branch up to date -this keeps git happy :)-
	#the odd syntax is due to the fact we are treating vss_branch as our upstream
	git push . HEAD:vss_branch
	
	git checkout vss_branch
		
	ssfullcommit
	
	#update git history file -this way SS has all the rich comment history I store with git despite SS's 500 comment character limit-
	
	sscommitone fullGitHistory.githistory
	
	#now print the message needed for the TGR comment
	printDiffInfo
	
	
	#"unpop" all the things we just did to restore working tree
	git checkout $BRANCH
	
	##--TODO-- check for git error at checkout attempt instead!
	##git stash apply 
}

#---unrecommended helpers-----

#replace Source-safe code with my master branch code
masterpushss()
{	
	echo "to master branch"
	git checkout master	
	sspush	
}
#merge master with source safe code
masterpullss()
{	
	echo "to master branch"
	git checkout master
	sspull
}

#get master to perform pull and push 
synch()
{	
	masterpullss
	masterpushss
}
##----Diffs (for use with branch version)---
hardrefupdate()
{
	REF_FOLDER="$CURRENT_PROJ_DIR$REF_APPEND"
	rm -rf $REF_FOLDER
	updateref
	
}
updateref()
{
	REF_FOLDER="$CURRENT_PROJ_DIR$REF_APPEND"
	if [ ! -d $REF_FOLDER ]; then	  
		mkdir $REF_FOLDER
	fi
	pushd $REF_FOLDER
	ssclone
	popd
	
}

compare_toREF()
{

	if [ -z "$BEYOND_COMPARE_SESSION" ]; then
		bcompare $CURRENT_PROJ_DIR $REF_FOLDER /iu /filters="-*.scc;-*.opensdf;-*.sdf;-*.orig" /qc=size 
	else	
		bcompare $BEYOND_COMPARE_SESSION
	fi

	

}
#should only be needed for sanity checks -diff with vss_branch *should* achieve the same-
diffallss()
{
	if [ -z ${CURRENT_PROJ_DIR+x} ]; 
		then echo "CURRENT_PROJ_DIR is unset"; 
		exit;
	fi
	
	UpdateRef
	compare_toREF	
}
harddiffallss()
{
	if [ -z ${CURRENT_PROJ_DIR+x} ]; 
		then echo "CURRENT_PROJ_DIR is unset"; 
		exit;
	fi
	
	hardrefupdate
	compare_toREF	
}

	

#PS1='[\u@\h`__git_ps1` \W]\$ 
