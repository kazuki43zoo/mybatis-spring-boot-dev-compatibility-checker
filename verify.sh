#!/bin/bash

function getLatestMaintenanceVersion() {
  local targetMinorVersion=$1
  local maintenanceVersions=""
  local majorVersion=${targetMinorVersion%.*}
  local minorVersion=${targetMinorVersion#*.}
  while read -r line; do
    if [[ "${line}" == *BUILD* ]]; then
      local maintenanceVersion=${line#<a*>${targetMinorVersion}.} && maintenanceVersion=${maintenanceVersion%.*}
      local prefix=".BUILD"
    else
      local maintenanceVersion=${line#<a*>${targetMinorVersion}.} && maintenanceVersion=${maintenanceVersion%%-*}
    fi
    maintenanceVersions="${maintenanceVersions}${maintenanceVersion}"$'\n'
  done<<END
    $(curl -s "https://repo.spring.io/snapshot/org/springframework/boot/spring-boot/" | grep "SNAPSHOT" | grep -E ">${majorVersion}\.${minorVersion}\.[0-9]*")
END
  echo "${targetMinorVersion}.$(echo "${maintenanceVersions}" | sort -n | tail -n 1)${prefix}-SNAPSHOT"
}

TARGET_MINOR_VERSIONS=${1}

for targetMinorVersion in ${TARGET_MINOR_VERSIONS}; do
  snapshotVersions="${snapshotVersions}$(getLatestMaintenanceVersion "${targetMinorVersion}")"$'\n'
done

echo "=================================="
echo "     Target Snapshot Versions"
echo "=================================="
echo "${snapshotVersions}"

rm -rf target
mkdir target
pushd target || exit

git clone https://github.com/mybatis/spring-boot-starter.git

pushd spring-boot-starter || exit

for targetSnapshotVersion in ${snapshotVersions}; do
  if [[ "${targetSnapshotVersion}" == 2.*.* ]]; then
    git checkout 2.3.x
  else
    git checkout master
  fi
  verifiedVersions="${verifiedVersions}${targetSnapshotVersion} "
  options="-Djacoco.plugin=0.8.11"
  ./mvnw clean verify -Dspring-boot.version=${targetSnapshotVersion} -Denforcer.skip=true ${options} && ./mybatis-spring-boot-samples/run_fatjars.sh && exitCode=0 || exitCode=$?
  if [ "${exitCode}" = "0" ]; then
    successedVersions="${successedVersions}${targetSnapshotVersion} "
  else
    failedVersions="${failedVersions}${targetSnapshotVersion} "
  fi
done

if [ -z "${failedVersions}" ]; then
  echo "Compatibility is OK :)"
  echo "Verified Versions: ${verifiedVersions}"
  exit 0
else
  echo "Compatibility is NG :("
  if [ ! "${successedVersions}" = "" ]; then
    echo "Successed Versions: ${successedVersions}"
  fi
  echo "Failed Versions: ${failedVersions}"
  exit 1
fi
