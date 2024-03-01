#!/usr/bin/env bash

set -euo pipefail

githubBaseUrl="https://github.com/itsferdiardiansa/Pinpin"
workspaceName=""
pkgJson=""
previousVersion=""
latestVersion=""
tagVersion=""
tagMessage=""
pullRequestBody=""
pullRequestUrl=""

declare -A commands=(
  [type]="" 
  [workspace]=""
  [path]=""
)

updateVersion() {
  dirPath="${commands[workspace]}/${commands[path]}"

  sed -i "s/\"version\": \".*\"/\"version\": \"$latestVersion\"/" ${pkgJson}

  git add ${dirPath}
  git commit -m "chore(deps): release ${tagVersion}"
}

createTagMessage() {
  tagMessage="
[Release] Bump version to ${tagVersion}. 
Change was created by the github actions and automation script.
  "
}

createTag() {
  createTagMessage

  echo "Create tag on ${workspaceName} workspace."
  
  if [ -z "${COMMIT_TAG}" ]; then
    git tag ${tagVersion} ${COMMIT_TAG} -m "${tagMessage}"
  else
    git tag ${tagVersion} -m "${tagMessage}"
  fi
}

createPullRequestTemplate() {
  echo "
This pull request contains the following updates:

| Packages/Apps  | Update |  Change  |
|----------------|--------|----------|
| [${workspaceName}](${githubBaseUrl}/tree/main/packages/utils)  |  ${commands[type]}   |  \`${previousVersion}\` to \`${latestVersion}\` |

---

# **Release Notes**
<!-- Describe changes --->
## **[${tagVersion}](${githubBaseUrl}/releases/tag/${tagVersion})**

- ...

---

This pull request has been generated by **Github Actions.**
  " >  PULL_REQUEST_TEMPLATE.md
}

createPullRequest() {
  git fetch

  if [ -z "$REF" ]; then
    git checkout -b release/${tagVersion} origin/${REF}
  else
    git checkout -b release/${tagVersion}
  fi

  updateVersion  
  createTag
  createPullRequestTemplate

  git push origin ${tagVersion}
  git push origin release/${tagVersion} -f

  pullRequestUrl=$(gh pr create -B main -t "release: ${tagVersion}" --body-file ./PULL_REQUEST_TEMPLATE.md)
}

createRelease() {
  compareVersion="${workspaceName}-${previousVersion}...${workspaceName}-${latestVersion}"

  note_template="[Pull Requests](${pullRequestUrl}) | [Compare](${githubBaseUrl}/compare/${compareVersion})"
  gh release create "${tagVersion}" -p --title "${tagVersion}" -n "${note_template//BASE_REVISION/$BASE_REVISION}"
}

genereteVersion() {
  pkgJson="${commands[workspace]}/${commands[path]}/package.json"
  latestVersion=$(jq -r .version ${pkgJson})
  previousVersion="${latestVersion}"
  workspaceName=$(jq -r .name ${pkgJson})

  if [ -z "$latestVersion" ]; then
    latestVersion="0.0.0"
  fi

  if [ "${commands[type]}" = "patch" ]; then
    latestVersion="$(echo "$latestVersion" | awk -F. '{$NF++; print $1"."$2"."$NF}')"
  elif [ "${commands[type]}" = "minor" ]; then
    latestVersion="$(echo "$latestVersion" | awk -F. '{$2++; $3=0; print $1"."$2"."$3}')"
  elif [ "${commands[type]}" = "major" ]; then
    latestVersion="$(echo "$latestVersion" | awk -F. '{$1++; $2=0; $3=0; print $1"."$2"."$3}')"
  else
    printf "\nError: invalid VERSION_TYPE arg passed, must be 'patch', 'minor' or 'major'\n\n"
    exit 1
  fi

  tagVersion="${workspaceName}-${latestVersion}"

  echo "Successfully generated the latest version of ${workspaceName} to => ${latestVersion}"
}

populateArguments() {
  for cmd in "$@";
  do
    cmd="${cmd:2}"
    IFS="=" read -a formattedValue <<< "${cmd//, ,}"
    declare -p formattedValue

    type="${formattedValue[0]}"
    value="${formattedValue[1]}"

    commands[${type}]=${value}
  done
}

run() {
  echo "Running release tasks..."

  populateArguments "$@"
  genereteVersion

  # Execute git commands
  createPullRequest

  createRelease
}

run "$@"