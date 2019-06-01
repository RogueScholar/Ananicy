#!/usr/bin/env bash

# If there is a failure in a pipeline, return the error status of the
# first failed process rather than the last command in the sequence
set -o pipefail

# Find the absolute path to the script
typeset -r SCRIPT_DIR="$(dirname "$(realpath -q "${BASH_SOURCE[0]}")")"

# Information about the git repository and build directory saved to variables
PACKAGE_DIR="${SCRIPT_DIR}/tmp"
PACKAGE_NAME="ananicy"
PACKAGE_ARCH="all"
DEBIAN_VER="$(grep -P -m 1 -o '\d*\.\d*-\d*' debian/changelog)~local1"
BUILD_ARCH="$(dpkg --print-architecture)"

# Echo wrappers
INFO() {
  echo -e "\\e[37;46mINFO:\\e[0m $*"
}
WARN() {
  echo -e "\\e[30;43mWARN:\\e[0m $*"
}
ERRO() {
  echo -e "\\e[37;41mERROR:\\e[0m $*"
  exit 1
}

debian_package() {
  # Make the script's folder the working dir, in case invoked from elsewhere
  cd "${SCRIPT_DIR}" || exit 1
  
  # Delete the build directory if it exists and create it anew and empty
  rm -rf "${PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  
  # Find and declare the data transfer agent we'll use
  if [ -x "$(command -v curl)" ]; then
    typeset -r TRANSFER_AGENT=curl
  elif [ -x "$(command -v wget)" ]; then
    typeset -r TRANSFER_AGENT=wget
  else
    echo -e '\e[37;41mERROR:\e[0m Neither curl nor wget was available to perform HTTP requests; please install one and try again.'
    exit 1
  fi

  # Download the name of the latest tagged release from GitHub
  echo "Fetching https://github.com/Nefelim4ag/Ananicy/releases/latest..."

  if [[ ${TRANSFER_AGENT} == "curl" ]]; then
    RESPONSE=$(curl -s -L -w 'HTTPSTATUS:%{http_code}' -H 'Accept: application/json' "https://github.com/Nefelim4ag/Ananicy/releases/latest")
    PACKAGE_VER=$(echo "${RESPONSE}" | sed -e 's/HTTPSTATUS\:.*//g' | tr -s '\n' ' ' | sed 's/.*"tag_name":"//' | sed 's/".*//')
    HTTP_CODE=$(echo "${RESPONSE}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
  elif [[ ${TRANSFER_AGENT} == "wget" ]]; then
    TEMP="$(mktemp)"
    RESPONSE=$(wget -q --header='Accept: application/json' -O - --server-response "https://github.com/Nefelim4ag/Ananicy/releases/latest" 2>"${TEMP}")
    PACKAGE_VER=$(echo "${RESPONSE}" | tr -s '\n' ' ' | sed 's/.*"tag_name":"//' | sed 's/".*//')
    HTTP_CODE=$(awk '/^  HTTP/{print $2}' <"${TEMP}" | tail -1)
    rm "${TEMP}"
  fi

  # Print the tagged version, or if we came up empty, give the user something to start troubleshooting with
  if [ "${HTTP_CODE}" != 200 ]; then
    echo -e "\\e[37;41mERROR:\\e[0m Request to GitHub for latest release data failed with code ${HTTP_CODE}."
    exit 1
  else
    echo -e "\\e[37;42mOK:\\e[0m Latest Release Tag = ${PACKAGE_VER}"
  fi

  # Just hand over the tarball and nobody gets hurt, ya see?
  echo "Downloading https://github.com/Nefelim4ag/Ananicy/archive/${PACKAGE_VER}.tar.gz..."

  if [[ ${TRANSFER_AGENT} == "curl" ]]; then
    HTTP_CODE=$(curl -# --retry 3 -w '%{http_code}' -L "https://github.com/Nefelim4ag/Ananicy/archive/${PACKAGE_VER}.tar.gz" \
      -o "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz")
  elif [[ ${TRANSFER_AGENT} == "wget" ]]; then
    HTTP_CODE=$(wget -qc -t 3 --show-progress -O "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz" \
      --server-response "https://github.com/Nefelim4ag/Ananicy/archive/${PACKAGE_VER}.tar.gz" 2>&1 |
      awk '/^  HTTP/{print $2}' | tail -1)
  fi

  # Print the result of the tarball retrieval attempt
  if [ "${HTTP_CODE}" != 200 ]; then
    echo "Request to GitHub for latest release file failed with code ${HTTP_CODE}."
    exit 1
  else
    echo -e '\e[37;42mOK:\e[0m Successfully downloaded the latest Ananicy package from GitHub.'
  fi

  # Unpack the tarball in the build directory
  echo "Unpacking the release archive..."
  tar -xzf "${PACKAGE_DIR}"/${PACKAGE_NAME}_"${PACKAGE_VER}".orig.tar.gz -C "${PACKAGE_DIR}"

  # Copy our Debian packaging files into the same directory as the unpacked source code
  cp -R debian/ "${PACKAGE_DIR}"/${PACKAGE_NAME}-"${PACKAGE_VER}"/

  # Make that source+packaging directory the new working directory, error out if it's not accessible
  cd "${PACKAGE_DIR}"/${PACKAGE_NAME}-"${PACKAGE_VER}" || exit 1

  # Append non-destructive "~local1" suffix to version number to indicate a local build
  perl -i -pe "s/$(grep -P -m 1 -o '\d*\.\d*-\d*' debian/changelog)/$&~local1/" debian/changelog

  # Replace the generic distribution string "unstable" with the distribution code-name of the build system
  sed -i "1s/unstable/$(lsb_release -cs)/" debian/changelog

  # Warn user of potentially lengthy process ahead
  echo "Building package ${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb, please be patient..."

  # Call debuild to oversee the build process and produce an output string for the user based on its exit code
  if debuild -b -us -uc; then
    echo -e '\t\e[32;40mSUCCESS:\e[0m I have good news!'
    echo -e "\\t\\t${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb was successfully built in ${PACKAGE_DIR}!"
    exit 0
  else
    echo -e '\t\e[33;40mERROR:\e[0m I have bad news... :-('
    echo -e '\t\tThe build process was unable to complete successfully.'
    exit 1
  fi
}

archlinux_package() {
  INFO "Use command 'yay -S ananicy-git' to install"
}

case $1 in
  deb) debian_package
  ;;
  arch) archlinux_package
  ;;
  *) echo "$0 <deb|arch>"
  ;;
esac
