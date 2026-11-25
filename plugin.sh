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

createProject()
{
    local pid=$1
    if [ -z "$pid" ]; then
        echo "parameter missing - call createProject <project id>"
        exit 1
    fi

    local pname="${PLUGIN_PROJECT_NAME:-$pid}"
    local category="${PLUGIN_CATEGORY-${DRONE_REPO_NAME}}"

    if ! redmine-cli project create-if-not-exist "$pname" "$pid"; then
        echo "error: failed to create project ${pid}"
        exit 1
    fi

    if [ -n "$category" ]; then
        if ! redmine-cli issue-category create-if-not-exist "$pid" "$category"; then
            echo "error: failed to create issue category ${category} in project ${pid}"
            exit 1
        fi
    fi
}

createVersion()
{
    local pid=$1
    if [ -z "$pid" ]; then
        echo "parameter missing - call createVersion <project id>"
        exit 1
    fi

    local version="${PLUGIN_RELEASE:-${DRONE_TAG}}"
    if [ -z "$version" ]; then
        echo "error: no version given (set RELEASE or DRONE_TAG)"
        exit 1
    fi

    if ! redmine-cli versions create-if-not-exist "$pid" "$version"; then
        echo "error: failed to create version ${version} in project ${pid}"
        exit 1
    fi

    if ! redmine-cli versions update "$version" --project "$pid" --status closed; then
        echo "error: failed to close version ${version} in project ${pid}"
        exit 1
    fi
}

getCommitRange()
{
    if [ -n "$DRONE_TAG" ]; then
        git fetch -t
        local startTag=$(git describe --tags --abbrev=0 "${DRONE_TAG}^" 2>/dev/null)
        if [ -z "$startTag" ]; then
            startTag=$(git rev-list --max-parents=0 "${DRONE_TAG}" 2>/dev/null)
        fi
        echo "${startTag}..${DRONE_TAG}"
    elif [ -n "$DRONE_COMMIT_BEFORE" ]; then
        echo "${DRONE_COMMIT_BEFORE}..${DRONE_COMMIT}"
    elif [ -n "$DRONE_COMMIT" ]; then
        echo "${DRONE_COMMIT}"
    fi
}

listCommits()
{
    local range=$1
    case "$range" in
        *..*) git rev-list "$range";;
        *)    git rev-list -n 1 "$range";;
    esac
}

extractReferences()
{
    mawk '
    {
        line = tolower($0)
        while (match(line, /(close[sd]?|closing|fix[a-z]*|ref[a-z]*)[ \t:]+#/)) {
            kw = substr(line, RSTART, RLENGTH)
            sub(/[ \t:]+#$/, "", kw)
            if (kw ~ /^close/)      g = "close"
            else if (kw ~ /^fix/)   g = "fix"
            else                    g = "ref"
            rest = substr(line, RSTART + RLENGTH)
            n = 0
            while (substr(rest, n + 1, 1) ~ /^[0-9]$/) n++
            if (n > 0) {
                printf "%s\t%s\n", substr(rest, 1, n), g
                rest = substr(rest, n + 1)
                while (1) {
                    while (rest ~ /^[ \t,&]/) rest = substr(rest, 2)
                    if (rest !~ /^#[0-9]+/) break
                    rest = substr(rest, 2)
                    n = 0
                    while (substr(rest, n + 1, 1) ~ /^[0-9]$/) n++
                    printf "%s\t%s\n", substr(rest, 1, n), g
                    rest = substr(rest, n + 1)
                }
            }
            line = substr(line, RSTART + RLENGTH)
        }
    }'
}

parseCommitRefs()
{
    local sha=$1
    local short subject body url refs

    short=$(git log -1 --format=%h "$sha")
    subject=$(git log -1 --format=%s "$sha")
    body=$(git log -1 --format=%b "$sha")

    url=""
    if [ -n "$DRONE_REPO_LINK" ]; then
        url="${DRONE_REPO_LINK}/commit/${sha}"
    fi

    refs=$(printf '%s\n%s\n' "$subject" "$body" | extractReferences)
    if [ -z "$refs" ]; then
        return 0
    fi

    while IFS=$'\t' read -r id grp; do
        [ -z "$id" ] && continue
        printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$grp" "$short" "$subject" "$url"
    done <<< "$refs"
}

dedupeRefs()
{
    mawk -F'\t' '
    {
        p = ($2 == "close") ? 3 : (($2 == "fix") ? 2 : 1)
        if (!($1 in prio) || p > prio[$1]) {
            if (!($1 in prio)) idx[++n] = $1
            prio[$1] = p
            line[$1] = $0
        }
    }
    END { for (i = 1; i <= n; i++) print line[idx[i]] }
    '
}

updateIssues()
{
    local pid=$1
    if [ -z "$pid" ]; then
        echo "parameter missing - call updateIssues <project id>"
        exit 1
    fi

    local range=$(getCommitRange)
    if [ -z "$range" ]; then
        echo "error: no commit range available (need a tag, DRONE_COMMIT_BEFORE or DRONE_COMMIT)"
        exit 1
    fi

    local commits=$(listCommits "$range")
    if [ -z "$commits" ]; then
        echo "error: no commits found for range ${range}"
        exit 1
    fi

    local refs=$(for sha in $commits; do parseCommitRefs "$sha"; done | dedupeRefs)

    if [ -z "$refs" ]; then
        echo "no issue references found in ${range}"
        return 0
    fi

    local status note failures=0
    while IFS=$'\t' read -r id grp short subject url; do
        [ -z "$id" ] && continue
        case "$grp" in
            close) status="Closed";;
            fix)   status="Fixed";;
            *)     status="";;
        esac

        note="commit ${short} ${subject}"
        if [ -n "$url" ]; then
            note="${note} (${url})"
        fi

        if [ -n "$status" ]; then
            if ! redmine-cli issue update "$id" --status "$status" --note "$note" </dev/null; then
                echo "error: failed to update issue ${id}"
                failures=$((failures + 1))
            fi
        else
            if ! redmine-cli issue update "$id" --note "$note" </dev/null; then
                echo "error: failed to update issue ${id}"
                failures=$((failures + 1))
            fi
        fi
    done <<< "$refs"

    if [ $failures -gt 0 ]; then
        echo "error: ${failures} issue update(s) failed"
        exit 1
    fi
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
    createProject) createProject ${PLUGIN_PROJECT_ID};;
    createVersion) createVersion ${PLUGIN_PROJECT_ID};;
    updateIssues) updateIssues ${PLUGIN_PROJECT_ID};;
    *) echo  "unknown action ${ACTION}";;
esac

