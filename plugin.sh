#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#

if [ -z  ${PLUGIN_REDMINE_URL} ]; then
    echo "ERROR: Please set REDMINE_URL"
    exit -1
fi

if [ -z  ${PLUGIN_REDMINE_TOKEN} ]; then
    echo "ERROR: Please set REDMINE_TOKEN"
    exit -1
fi

if [ -z ${PLUGIN_PROJECT_ID} ]; then
    echo "ERROR: Please set PROJECT_ID"
    exit -1
fi

export REDMINE_URL=$PLUGIN_REDMINE_URL
export REDMINE_TOKEN=$PLUGIN_REDMINE_TOKEN

if [  -n ${PLUGIN_UPLOAD_FILES} ]; then

    if [ "${PLUGIN_UPLOAD_FILES}" == "true" ]; then
        for f in  $PLUGIN_FILES; do
            FPATH=$(echo $f | cut -d ':' -f 1)
            NAME=$(echo $f | cut -d ':' -f 2)
            DESC=$(echo $f | cut -d ':' -f 3)
            VERS=$(echo $f | cut -d ':' -f 4)

            redmine-cli project upload -p ${PLUGIN_PROJECT_ID} -f ${NAME} -d ${DESC} -v ${VERS} $FPATH
        done
    fi
fi