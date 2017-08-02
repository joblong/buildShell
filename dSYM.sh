#!/bin/bash

APP_KEY=""
PROJECT_NAME="projectName"
PUBLISH_DIR=${PWD}/publish
LOCAL_PARSE_NAME="" 

PARSE_PATH="~/buildLive/LiveHistory"
EXCUSE_RESTART="~/desymbol_zhibo/restart.sh"
CRASHEYE_PATH="~/CrasheyeiOSSymbol_v3.1.0/CrasheyeiOSSymbol_v3.1.0.jar"


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

while getopts "k:j:p:n:" arg
do
    case $arg in
        k)
            APP_KEY=$OPTARG
            ;;
        j)
            PROJECT_NAME=$OPTARG
            ;;
        p)
            PUBLISH_DIR=$OPTARG
            ;;
        n)
            LOCAL_PARSE_NAME=$OPTARG                                                                                                               ;;
        ?)
            echo "unknow option $arg"
            exit 1
            ;;
    esac
done

echo "appKey="$APP_KEY "projectName="$PROJECT_NAME "publish="$PUBLISH_DIR "name="$LOCAL_PARSE_NAME

#parse File dSYM
if [ -n "$LOCAL_PARSE_NAME" ]; then 
    cp -r ${PUBLISH_DIR}  ${PARSE_PATH}/${LOCAL_PARSE_NAME}
    sh ${EXCUSE_RESTART}

    checkError "coyp and restart local parse dSYM"
fi



#upload dSYM To Crasheye
if [ -n "$APP_KEY" ]; then
    java -jar ${CRASHEYE_PATH} -appkey=${APP_KEY} -platform=ios ${PUBLISH_DIR}/${PROJECT_NAME}.xcarchive/dSYMs/${PROJECT_NAME}.app.dSYM

    checkError "upload To Crasheye"
fi

echo "upload dSYM Finished"
