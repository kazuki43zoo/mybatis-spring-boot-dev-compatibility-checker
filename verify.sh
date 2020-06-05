#!/bin/bash

rm -rf target
mkdir target
pushd target || exit

git clone https://github.com/mybatis/spring-boot-starter.git

pushd spring-boot-starter || exit

targetVersions="2.4.0-SNAPSHOT 2.3.1.BUILD-SNAPSHOT 2.2.8.BUILD-SNAPSHOT 2.1.15.BUILD-SNAPSHOT"

for targetVersion in ${targetVersions}; do
  if [[ "${targetVersion}" == 2.1.* ]]; then
    options="-Dspring-boot.version.line=2.1.x"
  fi
  ./mvnw clean verify -Dspring-boot.version=${targetVersion} -Denforcer.skip=true ${options} && ./mybatis-spring-boot-samples/run_fatjars.sh && exitCode=0 || exitCode=$?
  if [ ! "${exitCode}" = 0 ]; then
    failedVersions="${failedVersions}${targetVersion} "
  fi
done

if [ -z "${failedVersions}" ]; then
  echo "Compatibility is OK :)"
  echo "Verified Versions: ${targetVersions}"
  exit 0
else
  echo "Compatibility is NG :("
  echo "Failed Versions: ${failedVersions}"
  exit 1
fi
