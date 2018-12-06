#!/bin/bash

BUILD_DIR=`pwd`/build
OUPUT_DIR=`pwd`/output

if [[ -v PARALLEL_MAKE_JOBS ]]; then
	MAKE="make -j${PARALLEL_MAKE_JOBS}"
else
	MAKE="make"
fi

CXXFLAGS='-Wno-error=parentheses -Wno-error=maybe-uninitialized -Wno-error=address'

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
cmake -DBUILD_STATIC_LIB_ONLY=ON -DCMAKE_BUILD_TYPE=Release -DWITH_FLUID_ONLY=ON -DWITH_SWIG_PY=OFF -DWITH_PYTHON=OFF -DWITH_GPU=OFF -DON_INFER=ON -DFLUID_INFERENCE_INSTALL_DIR="${OUPUT_DIR}" .. && \
${MAKE} && make inference_lib_dist && \
collect_thirdparty_libs "${OUPUT_DIR}/third_party/install" "${OUPUT_DIR}/paddle"
