#!/usr/bin/env bash

declare -A sonar_variables
sonar_file=sonar-project.properties

# Sonar dictionaries
sonar_variables=(
  [sonar.projectVersion]=${SONAR_PROJECT_VERSION}
  [sonar.projectName]=${SONAR_PROJECT_NAME}
  [sonar.projectKey]=${SONAR_PROJECT_KEY}
  [sonar.organization]=${SONAR_ORGANIZATION}
  [sonar.javascript.lcov.reportPaths]=${COVERAGE_FILE}
)
if [ -f $sonar_file ]; then
  rm $sonar_file
fi

# Create sonar file
touch $sonar_file

for i in "${!sonar_variables[@]}"; do
  echo "$i=${sonar_variables[$i]}" >> $sonar_file
done
