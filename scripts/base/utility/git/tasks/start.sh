#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Tools - Git - Backup
# ----------------------------------------------------------------------------------------------------------------------

find_project_root() {
    local PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [[ "${PROJECT_DIR}" != "/" ]]; do
        if [[ -d "${PROJECT_DIR}/.git" ]] || [[ -f "${PROJECT_DIR}/.env.app" ]]; then
            echo "${PROJECT_DIR}"
            return 0
        fi
        PROJECT_DIR="$(dirname "${PROJECT_DIR}")"
    done
    return 1
}

PROJECT_PATH=$(find_project_root)
PROJECT_NAME=$(basename "$(realpath "${PROJECT_PATH}")")
cd "${PROJECT_PATH}" || exit

# ----------------------------------------------------------------------------------------------------------------------
# Abstract
# ----------------------------------------------------------------------------------------------------------------------

if [ -f "${PROJECT_PATH}/scripts/base/_abstract.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_abstract.sh"
else
  echo "Please check a file : ./scripts/base/_abstract.sh" && exit
fi

# >>>> Environment

setEnvironment() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ENV ] ${PLATFORM_TYPE} - ${PLATFORM_PROCESSOR}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  PS3="Menu: "
  select num in "dev" "exit"; do
    case "$REPLY" in
    1)
      # >>>> Dev Environment
      ENVIRONMENT_NAME="dev"
      break
      ;;
    2)
      echo "exit()"
      setEnd
      ;;
    *)
      echo "[ ERROR ] Unknown Command"
      setEnd
      ;;
    esac
  done

  echo
  echo "- PROJECT ENV : ${ENVIRONMENT_NAME}"
  echo
}

# >>>> Platform

setPlatform() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME^^} ] ${PLATFORM_TYPE} - Platform"
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "- PLATFORM OS : ${PLATFORM_TYPE}"
  echo
}

# >>>> Project

setProject() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME^^} ] ${PLATFORM_TYPE} - Project"
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "- PROJECT NAME : ${PROJECT_NAME}"
  echo
}

# >>>> Utility

setUtility() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Utility"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  TODAY=$(date "+%Y-%m-%d")
  DEFAULT_BRANCH=$(git config --get init.defaultBranch)
  RELEASES_VERSION=$(date +%Y.%m.%d)
  BRANCH_TEMP="temp"

  echo ">>>> Git - Project"
  echo

  if [ ! -d .git ]; then
    echo "❌ ERROR: There is no .git directory."
    exit 1
  fi

  # --------------------------------------------------------------------------------------------------------------------
  # Branch - Fetch
  # --------------------------------------------------------------------------------------------------------------------

  echo "🔍 Step 1 : Fetching from remote..."
  echo

  git fetch origin --prune
  echo

  # --------------------------------------------------------------------------------------------------------------------
  # Branch - Pull
  # --------------------------------------------------------------------------------------------------------------------

  echo "🔄 Step 2 : Updating ${DEFAULT_BRANCH}..."
  echo

  git checkout "${DEFAULT_BRANCH}"
  git pull origin "${DEFAULT_BRANCH}"
  echo

  if git rev-parse --verify "origin/${BRANCH_TEMP}" >/dev/null 2>&1; then
    echo "🔀 Step 3: Merging previous work (origin/${BRANCH_TEMP}) into ${DEFAULT_BRANCH}..."
    echo

    if git merge "origin/${BRANCH_TEMP}" --no-edit; then
      echo "✅ Merge Success"
      git push origin "${DEFAULT_BRANCH}"
      echo

      echo "🗑️ Deleting processed ${BRANCH_TEMP} branch..."
      git branch -D "${BRANCH_TEMP}" 2>/dev/null
      git push origin --delete "${BRANCH_TEMP}"
      echo
    else
      echo "⚠️ ERROR: Conflict detected! Please resolve conflicts manually and run push.sh later."
      exit 1
    fi
  else
    echo "ℹ️ Step 3: No remote '${BRANCH_TEMP}' found. Skipping merge."
    echo
  fi

  # --------------------------------------------------------------------------------------------------------------------
  # Branch - Temp
  # --------------------------------------------------------------------------------------------------------------------

  echo "🚀 Step 4: Creating a fresh '${BRANCH_TEMP}' branch for today..."
  echo

  git checkout -b "${BRANCH_TEMP}"
  echo

  echo "✨ Step 5: Ready to work on [ ${BRANCH_TEMP} ]"
  echo

  # --------------------------------------------------------------------------------------------------------------------
  # Logs
  # --------------------------------------------------------------------------------------------------------------------

  echo "ℹ️ Logs"
  echo

  git log -5 --graph --date=short --pretty=format:'%C(auto)%h %Cgreen(%ad)%Creset %s %C(bold blue)<%an>%Creset%C(auto)%d%Creset'
  echo
}


# ----------------------------------------------------------------------------------------------------------------------
# START
# ----------------------------------------------------------------------------------------------------------------------

setStart

# ----------------------------------------------------------------------------------------------------------------------
# Abstract
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Environment
setEnvironment

# >>>> Platform
setPlatform

# >>>> Project
setProject

# >>>> Utility
setUtility

# ----------------------------------------------------------------------------------------------------------------------
# END
# ----------------------------------------------------------------------------------------------------------------------

setEnd
