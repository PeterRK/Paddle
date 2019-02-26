#!/bin/bash

BUILD_DIR=`pwd`/build
OUPUT_DIR=`pwd`/output

if [[ -v PARALLEL_MAKE_JOBS ]]; then
	MAKE_ARGS="-j${PARALLEL_MAKE_JOBS}"
else
	MAKE_ARGS=""
fi

CXXFLAGS='-DNO_PRETTY_LOG -Wno-error=parentheses -Wno-error=maybe-uninitialized -Wno-error=address'

GNUC_VERSION_MSG=`echo "" | c++ -x c++ -E -dM - | grep __GNUC__`
if [[ "${GNUC_VERSION_MSG}" != '' ]]; then
	if [[ ${GNUC_VERSION_MSG:17} -gt 5 ]]; then
		CXXFLAGS="${CXXFLAGS} -Wno-error=implicit-fallthrough -Wno-error=format-truncation -Wno-error=ignored-attributes -Wno-error=cast-function-type -Wno-error=int-in-bool-context"
	fi
fi

export CXXFLAGS

function create_empty_dir() {
	if [[ -e "${1}" ]]; then
		rm -rf "${1}"
	fi
	mkdir "${1}"
}

function collect_thirdparty_libs() {
	if ! cd "${1}"; then
		exit 1
	fi
	for libdir in `ls`; do
		cp -r ${libdir}/* "${2}/"
	done
}

create_empty_dir "${BUILD_DIR}" && \
create_empty_dir "${OUPUT_DIR}" && \
cd "${BUILD_DIR}" && \
cmake -DBUILD_STATIC_LIB_ONLY=ON -DWITH_MKLDNN=ON -DON_INFER=ON -DCMAKE_BUILD_TYPE=Release -DFLUID_INFERENCE_INSTALL_DIR="${OUPUT_DIR}" .. && \
make ${MAKE_ARGS} && make inference_lib_dist && \
collect_thirdparty_libs "${OUPUT_DIR}/third_party/install" "${OUPUT_DIR}/paddle"
