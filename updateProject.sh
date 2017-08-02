#!/bin/bash

BRANCH="master"
VERSION=""
PLISTBUDDY="/usr/libexec/PlistBuddy"
RES_FROM="/Users/userName/buildLive/ResourceForBundleID/"
BUNDLEID="com.xxx.xxx"
GROUP_KEY="group.com.xxx.xxx.release"
PROJECT_PATH=${PWD}


while getopts "b:v:i:g:h" arg
do
    case $arg in
        h)
            help
            exit 0
            ;;
        b)
            BRANCH=$OPTARG
            ;;
        v)
            VERSION=$OPTARG
            ;;
        i)
            BUNDLEID=$OPTARG
            ;;
        g)
            GROUP_KEY=$OPTARG
            ;;
        ?)
            echo "unknow option $arg"
            exit 1
            ;;
    esac
done

echo "bundleId="$BUNDLEID "branch="$BRANCH "groupKey="$GROUP_KEY "version="$VERSION

#Function For Check Run Status 
checkError()
{
	if [ $? != 0 ]
		then
		echo "=====Error "$1" ====="
        exit 1
	else
		echo "=====Success "$1" ====="
	fi
}


#Function For PlistVersion
setPlistVersion()
{
    if [ -f "$2" ]
    then
        $PLISTBUDDY -c  "Set :CFBundleVersion $1" "$2"
        $PLISTBUDDY -c  "Set :CFBundleShortVersionString $1" "$2"
    fi
}


#Function For Git Commit And Push
gitCommitAndPush()
{
    git commit -am "$1"
    git push origin ${BRANCH}
}


cd ${PROJECT_PATH}


#git pull
git checkout $BRANCH
git pull
checkError "git checkout branch And pull"


#pod update
pod update
checkError "pod update"


#update MainProject version 
setPlistVersion ${VERSION} ${PROJECT_PATH}/xxx/Info.plist
#update Extension version
setPlistVersion ${VERSION} ${PROJECT_PATH}/xxxBoardcast/Info.plist
setPlistVersion ${VERSION} ${PROJECT_PATH}/xxxBoardcastUI/Info.plist
checkError "modify plist version to "${VERSION}

#git commit
git commit -am "modify version to "${VERSION}


#set groupkey
if [ -n "$GROUP_KEY" ]; then
$PLISTBUDDY -c  "Set :com.apple.security.application-groups:0 ${GROUP_KEY}" "${PROJECT_PATH}/xxx/xxx.entitlements"
else
$PLISTBUDDY -c  "Delete :com.apple.security.application-groups" "${PROJECT_PATH}/xxx/xxx.entitlements"
fi

#modify bundleId
$PLISTBUDDY -c  "Set :CFBundleIdentifier ${BUNDLEID}" "${PROJECT_PATH}/xxx/Info.plist"
$PLISTBUDDY -c  "Set :CFBundleIdentifier ${BUNDLEID}.NotificationService" "${PROJECT_PATH}/NotificationService/Info.plist"
git commit -am "modify bundleId: "${BUNDLEID}


#copy resource for bundleID
if [ $BUNDLEID == "com.xxx.xxx" ]
then
  cp -r ${RES_FROM}${BUNDLEID}/shopping/  ${PROJECT_PATH}/xxx/Shopping/sdk
  checkError "copy resource form " ${RES_FROM}${BUNDLEID}/shopping/ " to "${PROJECT_PATH}/Shopping/sdk
  git commit -am  "replace shoppingSDK resource"
fi



#push To Branch
git push origin ${BRANCH}


echo "++++++++++Success updateProject"
