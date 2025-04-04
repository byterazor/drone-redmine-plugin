#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#

if [ -z  "${PLUGIN_REDMINE_URL}" ]; then
    echo "ERROR: Please set REDMINE_URL"
    exit -1
fi

if [ -z  "${PLUGIN_REDMINE_TOKEN}" ]; then
    echo "ERROR: Please set REDMINE_TOKEN"
    exit -1
fi

export REDMINE_URL=$PLUGIN_REDMINE_URL
export REDMINE_API_TOKEN=$PLUGIN_REDMINE_TOKEN

echo $REDMINE_URL 
echo $REDMINE_API_TOKEN

if [ -z "${PLUGIN_PAGE_PARENT}" ]; then 
    PLUGIN_PAGE_PARENT=""
fi

#
# Upload files to the projects file section
#
if [  -n "${PLUGIN_UPLOAD_FILES}" ]; then
    
    if [ "${PLUGIN_UPLOAD_FILES}" == "true" ]; then

        if [ -z "${PLUGIN_PROJECT_NR}" ]; then
            echo "ERROR: Please set PROJECT_NR (the number not the string identifier)"
            exit -1
        fi


        for f in  $PLUGIN_FILES; do
            FPATH=$(echo $f | cut -d ':' -f 1)
            NAME=$(echo $f | cut -d ':' -f 2)
            DESC=$(echo $f | cut -d ':' -f 3)
            VERS=$(echo $f | cut -d ':' -f 4)

            redmine-cli project upload -p ${PLUGIN_PROJECT_NR} -f ${NAME} -d ${DESC} -v ${VERS} $FPATH
        done
    fi
fi

#
# delete a wiki page
#
if [ -n "${PLUGIN_DELETE_WIKI_PAGE}" ]; then
    if [ "${PLUGIN_DELETE_WIKI_PAGE}" == "true" ]; then
        
        if [ -z "${PLUGIN_PROJECT_ID}" ]; then
            echo "ERROR: Please set PROJECT_ID when deleting a wiki page (the string identifier)"
            exit -1
        fi

        if [ -z "${PLUGIN_PAGE_NAME}" ]; then
            echo "ERROR: Please set PAGE_NAME when deleting wiki page"
            exit -1
        fi

        echo "redmine-cli wiki deletePage -p ${PLUGIN_PROJECT_ID} --page ${PLUGIN_PAGE_NAME}"
        redmine-cli wiki deletePage -p ${PLUGIN_PROJECT_ID} --page ${PLUGIN_PAGE_NAME}
    fi
fi


#
# update a wiki page
#
if [ -n "${PLUGIN_UPDATE_WIKI_PAGE}" ]; then
    if [ "${PLUGIN_UPDATE_WIKI_PAGE}" == "true" ]; then

        if [ -z "${PLUGIN_PROJECT_ID}" ]; then
            echo "ERROR: Please set PROJECT_ID when updating a wiki page (the string identifier)"
            exit -1
        fi

        if [ -z "${PLUGIN_PAGE_NAME}" ]; then
            echo "ERROR: Please set PAGE_NAME when updating wiki page"
            exit -1
        fi

        CMD="redmine-cli wiki updatePage -p ${PLUGIN_PROJECT_ID} --page ${PLUGIN_PAGE_NAME} --parent \"${PLUGIN_PAGE_PARENT}\" "

        if [ -n "${PLUGIN_PAGE_CONTENT}" ]; then
            CMD="$CMD -c \'${PLUGIN_PAGE_CONTENT}\'"
        elif [ -n "${PLUGIN_PAGE_FILE}" ]; then
            CMD="$CMD -f ${PLUGIN_PAGE_FILE}"
        fi

        if [ -n "${PLUGIN_PAGE_ATTACHEMENTS}" ]; then
            for a in ${PLUGIN_PAGE_ATTACHEMENTS}; do
                CMD="$CMD -a \"$a\""
            done
        fi
        echo $CMD 

        $CMD
    fi
fi