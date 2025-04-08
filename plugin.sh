#!/bin/bash
set -x 



ACTION=${PLUGIN_ACTION}

gitNrTags()
{
    nr=$(git tag | wc -l)

    return $nr
}

doesPageExist()
{
    local page=$1
    local pid=$2 

    if [ -z "$page" -o -z "$pid" ]; then
        echo "parameter missing - call $0 <page> <project id>"
        exit 1
    fi


    redmine-cli wiki getPage -p ${pid} --page ${page} >/dev/null

    if  [ $? -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

deleteWikiPage()
{
    local page=$1
    local pid=$2 

    if [ -z "$page" -o -z "$pid" ]; then
        echo "parameter missing - call deleteWikiPage <page> <project id>"
        exit 1
    fi 
    redmine-cli wiki deletePage -p ${pid} --page ${page}

}

getGitCommits()
{
    local release=$1

    git fetch -t
    local startTag=$(git describe --tags --abbrev=0 ${release}^)
    
    if [ -z "$startTag" ]; then
        startTag=$(git rev-list --max-parents=0 HEAD)
    fi

    git log --pretty=oneline ${startTag}...${release} | egrep "(feat|fix)" | awk '{$1 = "";  print "- "$0;}'

}

updateWikiPage()
{
    local page=$1
    local pid=$2 
    local content=$3
    local parent=$4
    local artifacts=$5

    if [ -z "$page" -o -z "$pid" ]; then
        echo "parameter missing - call $0 <page> <project id>"
        exit 1
    fi

    NEW=$(echo ${page} | sed 's/\./_/g')
    page=$NEW

    NEW=$(echo ${parent} | sed 's/\./_/g')
    parent=$NEW

    CMDP=""    
    if [ -n "${parent}" ]; then
        doesPageExist $parent $pid
        if [ $? == 0  ]; then
            echo "error: parent page ${parent} does not exist. not updating ${page}"
            return
        fi
        
        CMDP=" --parent ${parent}"
    fi

    CMDA=""
    if [ -n "${artifacts}" ]; then
        for a in $artifacts; do
            CMDA="$CMDA -a $a ";
        done
    fi

    redmine-cli wiki updatePage -p $pid --page $page -c "${content}" ${CMDP} ${CMDA}
}

updateArtifacts()
{
    local page=$1
    local parent=$2
    local pid=$3
    local subname=$4
    local title=$5
    shift 5
    local artifacts=$@

    
    echo "### $title" > artifacts.md
    for a in $artifacts; do
        echo "- attachment:${a}" >> artifacts.md
    done

    content=$(cat artifacts.md)

    deleteWikiPage $page $pid
    updateWikiPage $page $pid "$content" $parent $artifacts

}

createBranches()
{
    local pid=$1

    doesPageExist "branches" $pid
    if [ $? == 0 ]; then
        content="### Branches
                
{{child_pages(branches)}}"
        updateWikiPage "branches" $pid "$content" "" ""
    fi

}

createReleases()
{
    local pid=$1

    doesPageExist "releases" $pid
    if [ $? == 0 ]; then
        content="### Releases
                
{{child_pages(releases)}}"
        updateWikiPage "releases" $pid "$content" "" ""
    fi

}

updateBranchArtifacts()
{
    local branch=$1
    local pid=$2
    local artefact_group=$3
    local artifacts=$4

    createBranches $pid
    doesPageExist $branch $pid

    if [ $? == 0 ]; then
        redmine-cli wiki updatePage -p ${pid} --page ${branch} --parent "branches" -c "empty"
    fi

    updateArtifacts "branch_artifacts_${branch}_${artefact_group}" ${branch} ${pid} ${artefact_group} "Artifacts for ${artefact_group}" $artifacts
}

updateReleaseArtifacts()
{
    local release=$1
    local pid=$2
    local artefact_group=$3
    local artifacts=$4

    createReleases $pid
    doesPageExist $release $pid

    if [ $? == 0 ]; then
        redmine-cli wiki updatePage -p ${pid} --page ${release} --parent "releases" -c "empty"
    fi

    updateArtifacts "release_artifacts_${release}_${artefact_group}" ${release} ${pid} ${artefact_group} "Artifacts for ${artefact_group}" $artifacts
}


badge()
{
    local name=$1
    local value=$2
    local color=$3
    local desc=$4

    echo -n "![${desc}](https://img.shields.io/badge/${name}-${value}-${color})"
}

updateBranchStatus()
{
    local branch=$1
    local pid=$2
    local status=$3

    color=red
    if [ "$status" == "success" ]; then
        color=green
    fi

    createBranches $pid
    echo "### Build Status for Branch ${branch}" > status.md
    badge branch ${branch} blue "Branch Badge" >> status.md
    badge CI--CD enabled green "CI-CD enabled" >> status.md
    badge build $status $color "Build Status" >> status.md
    echo >> status.md
    echo >> status.md
    echo -n "**Last Build:** " >> status.md
    date >> status.md
    echo >> status.md
    echo >> status.md
    echo "#### Artifacts" >> status.md
    echo "{{child_pages()}}" >> status.md

    content=$(cat status.md) 
    updateWikiPage $branch $pid "$content" "branches"

}

updateReleaseStatus()
{
    local release=$1
    local pid=$2

    createReleases $pid

    echo "### Release ${release}" > status.md
    echo >> status.md
    echo "{{toc}}" >> status.md
    echo >> status.md
    badge release ${release} blue "Release Badge" >> status.md
    echo >> status.md
    echo >> status.md
    echo -n "**Release Date:** " >> status.md
    date >> status.md
    echo >> status.md
    echo >> status.md
    echo "#### Included Commits" >> status.md
    getGitCommits $release >> status.md
    echo "#### Artifacts" >> status.md
    echo "{{child_pages()}}" >> status.md

    content=$(cat status.md) 
    updateWikiPage $release $pid "$content" "releases" ""

}

#
# main  program
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


case ${ACTION} in
    updateBranchStatus) updateBranchStatus ${PLUGIN_BRANCH} ${PLUGIN_PROJECT_ID} ${PLUGIN_BUILD_STATUS};;
    updateBranchStatusStages) updateBranchStatusStages ${PLUGIN_BRANCH} ${PLUGIN_PROJECT_ID} ;;
    updateReleaseStatus) updateReleaseStatus ${PLUGIN_RELEASE} ${PLUGIN_PROJECT_ID} ;;
    updateBranchArtifacts) updateBranchArtifacts ${PLUGIN_BRANCH} ${PLUGIN_PROJECT_ID} "${PLUGIN_ARTEFACT_GROUP}" "${PLUGIN_ARTIFACTS}" ;;
    updateReleaseArtifacts) updateReleaseArtifacts ${PLUGIN_RELEASE} ${PLUGIN_PROJECT_ID} "${PLUGIN_ARTEFACT_GROUP}" "${PLUGIN_ARTIFACTS}";; 
    *) echo  "unknown action ${ACTION}";;
esac