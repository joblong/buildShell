#!/bin/bash

BRANCH="master"
VERSION=""
BUNDLEID="com.xxx.xxx"
CODESIGN=""
TEAMNAME=""
GROUP_KEY=""
CRASHEYE_APPKEY=""

PROJECT_NAME="ProjectName"
BUILD_CONFIG="Release"
PROJECT_PATH=${PWD}
PUBLISH_DIR=${PROJECT_PATH}/publish
DEVELOPER_NAME=""
DEVELOPER_PW=""
PREFIX="prefixName"


PLISTBUDDY="/usr/libexec/PlistBuddy"
EXPORT_OPTIONS_PLIST_PATH="${PROJECT_PATH}/buildShell/AppStoreOptions.plist"
ALTOOL_PATH="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support"

RESULT_UPLOADING=${PUBLISH_DIR}/alToolResult.xml
RELEASE_HISTORY_DIR="/Users/userName/buildLive/ReleaseHistory"


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




while getopts "x:u:p:b:v:i:g:h" arg
do
    case $arg in
        h)
            help
            exit 0
            ;;
        x)
            PROJECT_NAME=$OPTARG
            ;;
        u)
            DEVELOPER_NAME=$OPTARG
            ;;
        p)
            DEVELOPER_PW=$OPTARG
            ;;
        b)
            BRANCH=$OPTARG                                                                                                                          ;;
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

echo "uploadUser="${DEVELOPER_NAME}

#IPA Path
ARCHIVE_PATH="${PUBLISH_DIR}/${PROJECT_NAME}.xcarchive"
IPA_PATH="${PUBLISH_DIR}/${PROJECT_NAME}.ipa"


#groupKey for bundleId
case $BUNDLEID in
    "com.xxx.xxx")
        CODESIGN="iPhone Distribution: aaa bbb (xxxxxxxxxx)"
        PREFIX="milive"
        GROUP_KEY="group.com.xxx.xxx.release"
        CRASHEYE_APPKEY="xxxxxx"
        ;;
    "com.xxxx.xxxx")
        CODESIGN="iPhone Distribution: xxx xxx Co.,Ltd. (xxxxxxxxxx)"
        PREFIX="xxxxx"
        ;;
esac
TEAMNAME=$(echo "$CODESIGN" | sed 's/[^)(]*(\([^)(]*\)[^)(]*)/\1/g')


echo "codesign="${CODESIGN} "termName="${TEAMNAME} "prefix="${PREFIX} "groupKey="${GROUP_KEY}


#update project param
sh ${PROJECT_PATH}/buildShell/updateProject.sh -b $BRANCH -v $VERSION -i $BUNDLEID -g "${GROUP_KEY}"
checkError "update Project param"



#config XcodeProject
ruby ${PROJECT_PATH}/buildShell/configProject.rb "${BUILD_CONFIG}" "${CODESIGN}" "${PROJECT_NAME}" "${PROJECT_PATH}" "${TEAMNAME}" "$BUNDLEID"
git commit -am "config XcodeProject"
git push origin ${BRANCH}

checkError "ruby config project and git push"



#check Publish Path
if [ ! -d $PUBLISH_DIR ]
then
    mkdir -p $PUBLISH_DIR
fi

#reset unlock-keychain
security unlock-keychain -p XXX


#build archive
xcodebuild archive  ONLY_ACTIVE_ARCH=NO \
    -workspace ${PROJECT_NAME}.xcworkspace \
    -scheme ${PROJECT_NAME} \
    -configuration ${BUILD_CONFIG} \
    -archivePath ${ARCHIVE_PATH}

checkError "build archive"


#export ipa file
xcodebuild -exportArchive -archivePath ${ARCHIVE_PATH} \
    -exportPath ${PUBLISH_DIR} \
    -exportOptionsPlist "${EXPORT_OPTIONS_PLIST_PATH}"

checkError "export ipa"




#Backup ArchiveFile
echo "copy archiveFile to " ${RELEASE_HISTORY_DIR}
buildPlist="${PROJECT_PATH}/${PROJECT_NAME}/Info.plist"
buildVersion=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${buildPlist}" 2>/dev/null)
cp -r ${PUBLISH_DIR}  ${RELEASE_HISTORY_DIR}/${PREFIX}_${buildVersion}
echo "Backup archive on " ${RELEASE_HISTORY_DIR}/${PREFIX}_${buildVersion}




#upload binary to AppStore
echo "binary uploading..."
cd "${ALTOOL_PATH}"
#--upload-app && --validate-app
./altool --upload-app -f ${IPA_PATH} \
    -u "${DEVELOPER_NAME}" \
    -p "${DEVELOPER_PW}" \
    -t ios \
    --output-format xml >> ${RESULT_UPLOADING}

checkError "binary uplaod"


#local and crasheye dSYM file
sh ${PROJECT_PATH}/buildShell/dSYM.sh -k $CRASHEYE_APPKEY -j $PROJECT_NAME -p $PUBLISH_DIR -n "build-release_${PREFIX}_${buildVersion}"
checkError "upload dSYM"


echo "build success"
