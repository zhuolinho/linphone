############################################################################
# CMakeLists.txt
# Copyright (C) 2014  Belledonne Communications, Grenoble France
#
############################################################################
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
############################################################################

include(ExternalProject)

set(ep_base "${LINPHONE_BUILDER_WORK_DIR}/${CONFIG_NAME}")
set_property(DIRECTORY PROPERTY EP_BASE ${ep_base})


# Define the architecture. It will be used to generate the URL to get prebuilt dependencies.
if(WIN32)
	set(LINPHONE_BUILDER_ARCHITECTURE "Win32")
elseif(UNIX)
	if(APPLE)
		set(LINPHONE_BUILDER_ARCHITECTURE "OsX64")
	endif()
endif()


if(CMAKE_VERBOSE_MAKEFILE)
	set(AUTOTOOLS_VERBOSE_MAKEFILE 1)
else()
	set(AUTOTOOLS_VERBOSE_MAKEFILE 0)
endif()


# Check for build tools and show an error if one of them is not present
include(cmake/CheckBuildTools.cmake)


set(LINPHONE_BUILDER_EP_VARS)
set(LINPHONE_BUILDER_INCLUDED_BUILDERS)
set(LINPHONE_BUILDER_INCLUDED_BUILDERS_TO_EXCLUDE)
set(LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH_BUILDERS)

macro(linphone_builder_expand_external_project_vars)
	set(LINPHONE_BUILDER_EP_ARGS "")
	set(LINPHONE_BUILDER_EP_VARNAMES "")
	foreach(arg ${LINPHONE_BUILDER_EP_VARS})
		string(REPLACE ":" ";" varname_and_vartype ${arg})
		set(target_info_list ${target_info_list})
		list(GET varname_and_vartype 0 _varname)
		list(GET varname_and_vartype 1 _vartype)
		list(APPEND LINPHONE_BUILDER_EP_ARGS -D${_varname}:${_vartype}=${${_varname}})
		list(APPEND LINPHONE_BUILDER_EP_VARNAMES ${_varname})
	endforeach()
endmacro()

list(APPEND LINPHONE_BUILDER_EP_VARS
	CMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH
	CMAKE_BUILD_TYPE:STRING
	CMAKE_BUILD_WITH_INSTALL_RPATH:BOOL
	CMAKE_BUNDLE_OUTPUT_DIRECTORY:PATH
	CMAKE_C_COMPILER_LAUNCHER:PATH
	CMAKE_C_FLAGS_DEBUG:STRING
	CMAKE_C_FLAGS_MINSIZEREL:STRING
	CMAKE_C_FLAGS_RELEASE:STRING
	CMAKE_C_FLAGS_RELWITHDEBINFO:STRING
	CMAKE_C_FLAGS:STRING
	CMAKE_CXX_COMPILER_LAUNCHER:PATH
	CMAKE_CXX_FLAGS_DEBUG:STRING
	CMAKE_CXX_FLAGS_MINSIZEREL:STRING
	CMAKE_CXX_FLAGS_RELEASE:STRING
	CMAKE_CXX_FLAGS_RELWITHDEBINFO:STRING
	CMAKE_CXX_FLAGS:STRING
	CMAKE_EXE_LINKER_FLAGS_DEBUG:STRING
	CMAKE_EXE_LINKER_FLAGS_MINSIZEREL:STRING
	CMAKE_EXE_LINKER_FLAGS_RELEASE:STRING
	CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO:STRING
	CMAKE_EXE_LINKER_FLAGS:STRING
	CMAKE_EXTRA_GENERATOR:STRING
	CMAKE_GENERATOR_PLATFORM:STRING
	CMAKE_INSTALL_MESSAGE:STRING
	CMAKE_INSTALL_PREFIX:PATH
	CMAKE_INSTALL_RPATH:PATH
	CMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL
	CMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH
	CMAKE_MODULE_LINKER_FLAGS_DEBUG:STRING
	CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL:STRING
	CMAKE_MODULE_LINKER_FLAGS_RELEASE:STRING
	CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO:STRING
	CMAKE_MODULE_LINKER_FLAGS:STRING
	CMAKE_MODULE_PATH:PATH
	CMAKE_NO_BUILD_TYPE:BOOL
	CMAKE_PREFIX_PATH:STRING
	CMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH
	CMAKE_SHARED_LINKER_FLAGS_DEBUG:STRING
	CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL:STRING
	CMAKE_SHARED_LINKER_FLAGS_RELEASE:STRING
	CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO:STRING
	CMAKE_SHARED_LINKER_FLAGS:STRING
	CMAKE_SKIP_RPATH:BOOL
	CMAKE_SKIP_BUILD_RPATH:BOOL
	CMAKE_VERBOSE_MAKEFILE:BOOL
	MSVC_C_ARCHITECTURE_ID:STRING
	MSVC_CXX_ARCHITECTURE_ID:STRING
	MSVC_VERSION:STRING
)
if(CMAKE_CROSSCOMPILING)
	list(APPEND LINPHONE_BUILDER_EP_VARS
		CMAKE_SYSTEM_NAME:STRING
		CMAKE_SYSTEM_VERSION:STRING
	)
endif()
if(APPLE)
	list(APPEND LINPHONE_BUILDER_EP_VARS
		CMAKE_MACOSX_RPATH:BOOL
		CMAKE_OSX_ARCHITECTURES:STRING
		CMAKE_OSX_DEPLOYMENT_TARGET:STRING
	)
endif()
if(CMAKE_TOOLCHAIN_FILE)
	list(APPEND LINPHONE_BUILDER_EP_VARS CMAKE_TOOLCHAIN_FILE:PATH)
endif()


function(linphone_builder_get_autotools_configuration)
	if(MSVC)
		set(_generator "MinGW Makefiles")
	else()
		set(_generator "${CMAKE_GENERATOR}")
	endif()
	set(_autotools_command ${CMAKE_COMMAND} -G "${_generator}")
	if(CMAKE_TOOLCHAIN_FILE)
		list(APPEND _autotools_command "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
	endif()
	if(LINPHONE_BUILDER_OSX_ARCHITECTURES)
		list(APPEND _autotools_command "-DLINPHONE_BUILDER_OSX_ARCHITECTURES=${LINPHONE_BUILDER_OSX_ARCHITECTURES}")
	endif()
	list(APPEND _autotools_command "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Autotools/")
	execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/Autotools)
	execute_process(COMMAND ${_autotools_command} WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/Autotools)
	unset(_autotools_command)
	unset(_extra_generator)
	unset(_generator)
	include(${CMAKE_BINARY_DIR}/Autotools/Autotools.cmake)
endfunction()


macro(linphone_builder_create_targets_list)
	set(LINPHONE_BUILDER_TARGETS )
	if(LINPHONE_BUILDER_TARGET STREQUAL "belle-sip")
		list(APPEND LINPHONE_BUILDER_TARGETS "belle-sip")
	elseif(LINPHONE_BUILDER_TARGET STREQUAL "ortp")
		list(APPEND LINPHONE_BUILDER_TARGETS "ortp")
	elseif(LINPHONE_BUILDER_TARGET STREQUAL "ms2")
		list(APPEND LINPHONE_BUILDER_TARGETS "ortp" "ms2")
	elseif(LINPHONE_BUILDER_TARGET STREQUAL "ms2-plugins")
		list(APPEND LINPHONE_BUILDER_TARGETS "ortp" "ms2" "ms2-plugins")
	elseif(LINPHONE_BUILDER_TARGET STREQUAL "linphone")
		list(APPEND LINPHONE_BUILDER_TARGETS "belle-sip" "ortp" "ms2" "ms2-plugins" "linphone")
	elseif(LINPHONE_BUILDER_TARGET STREQUAL "flexisip")
		list(APPEND LINPHONE_BUILDER_TARGETS "ortp" "flexisip")
	elseif(LINPHONE_BUILDER_TARGET STREQUAL "odb")
		list(APPEND LINPHONE_BUILDER_TARGETS "odb" )
	else()
		message(FATAL_ERROR "Invalid LINPHONE_BUILDER_TARGET '${LINPHONE_BUILDER_TARGET}'")
	endif()
endmacro()


macro(linphone_builder_include_builder BUILDER)
	list(FIND LINPHONE_BUILDER_INCLUDED_BUILDERS ${BUILDER} _already_included)
	if(_already_included EQUAL -1)
		message(STATUS "Including builder ${BUILDER}")
		include(${CMAKE_CURRENT_SOURCE_DIR}/builders/${BUILDER}.cmake)
		list(APPEND LINPHONE_BUILDER_INCLUDED_BUILDERS ${BUILDER})
	endif()
	unset(_already_included)
endmacro()


macro(linphone_builder_add_builder_to_target TARGETNAME BUILDER)
	linphone_builder_include_builder(${BUILDER})
	if(LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH AND (LINPHONE_BUILDER_GROUP_EXTERNAL_SOURCE_PATH_BUILDERS OR LINPHONE_BUILDER_BUILD_ONLY_EXTERNAL_SOURCE_PATH))
		foreach(SUBDIR ${EP_${BUILDER}_EXTERNAL_SOURCE_PATHS})
			set(_source_dir "${LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH}/${SUBDIR}")
			if(EXISTS "${_source_dir}")
				#message("    ${TARGETNAME} depends on external source path ${LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH}/${SUBDIR}")
				set(_build_from_external_source_path 1)
				break()
			endif()
		endforeach()
		if(_build_from_external_source_path)
			list(FIND LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH_BUILDERS ${BUILDER} _already_included)
			if(_already_included EQUAL -1)
				message("    external source path builder ${BUILDER}")
				set(EP_${BUILDER}_SOURCE_DIR "${_source_dir}")
				list(APPEND LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH_BUILDERS ${BUILDER})
			endif()
			unset(_already_included)
		elseif(LINPHONE_BUILDER_BUILD_ONLY_EXTERNAL_SOURCE_PATH)
			list(APPEND LINPHONE_BUILDER_INCLUDED_BUILDERS_TO_EXCLUDE ${BUILDER})
		else()
			#message("     ${TARGETNAME} depends on external project EP_${BUILDER}")
			add_dependencies(${TARGETNAME} EP_${BUILDER})
		endif()
		unset(_build_from_external_source_path)
	else()
		#message("    ${TARGETNAME} depends on external project EP_${BUILDER}")
		add_dependencies(${TARGETNAME} EP_${BUILDER})
	endif()
endmacro()


macro(linphone_builder_apply_flags)
	foreach(BUILD_CONFIG "" "_DEBUG" "_MINSIZEREL" "_RELEASE" "_RELWITHDEBINFO")
		if(LINPHONE_BUILDER_CPPFLAGS)
			set(CMAKE_C_FLAGS${BUILD_CONFIG} "${CMAKE_C_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_CPPFLAGS}")
			set(CMAKE_CXX_FLAGS${BUILD_CONFIG} "${CMAKE_CXX_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_CPPFLAGS}")
			set(AUTOTOOLS_C_FLAGS${BUILD_CONFIG} "${AUTOTOOLS_C_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_CPPFLAGS}")
			set(AUTOTOOLS_CXX_FLAGS${BUILD_CONFIG} "${AUTOTOOLS_CXX_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_CPPFLAGS}")
		endif()
		if(LINPHONE_BUILDER_CFLAGS)
			set(CMAKE_C_FLAGS${BUILD_CONFIG} "${CMAKE_C_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_CFLAGS}")
			set(AUTOTOOLS_C_FLAGS${BUILD_CONFIG} "${AUTOTOOLS_C_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_CFLAGS}")
		endif()
		if(LINPHONE_BUILDER_CXXFLAGS)
			set(CMAKE_CXX_FLAGS${BUILD_CONFIG} "${CMAKE_CXX_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_CXXFLAGS}")
			set(AUTOTOOLS_CXX_FLAGS${BUILD_CONFIG} "{AUTOTOOLS_CXX_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_CXX_FLAGS}")
		endif()
		if(LINPHONE_BUILDER_OBJCFLAGS)
			set(CMAKE_C_FLAGS${BUILD_CONFIG} "${CMAKE_C_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_OBJCFLAGS}")
			set(AUTOTOOLS_OBJC_FLAGS${BUILD_CONFIG} "${AUTOTOOLS_OBJC_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_OBJCFLAGS}")
		endif()
		if(LINPHONE_BUILDER_LDFLAGS)
			# TODO: The two following lines should not be here
			set(CMAKE_C_FLAGS${BUILD_CONFIG} "${CMAKE_C_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_LDFLAGS}")
			set(CMAKE_CXX_FLAGS${BUILD_CONFIG} "${CMAKE_CXX_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_LDFLAGS}")

			set(CMAKE_EXE_LINKER_FLAGS${BUILD_CONFIG} "${CMAKE_EXE_LINKER_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_LDFLAGS}")
			set(CMAKE_MODULE_LINKER_FLAGS${BUILD_CONFIG} "${CMAKE_MODULE_LINKER_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_LDFLAGS}")
			set(CMAKE_SHARED_LINKER_FLAGS${BUILD_CONFIG} "${CMAKE_SHARED_LINKER_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_LDFLAGS}")
			set(AUTOTOOLS_LINKER_FLAGS${BUILD_CONFIG} "${AUTOTOOLS_LINKER_FLAGS${BUILD_CONFIG}} ${LINPHONE_BUILDER_LDFLAGS}")
		endif()
	endforeach()
endmacro()


macro(linphone_builder_apply_cmake_flags_to_autotools_project PROJNAME)
	if(EP_${PROJNAME}_BUILD_METHOD STREQUAL "autotools")
		set(BUILD_TYPES "Debug" "Release" "RelWithDebInfo" "MinSizeRel")
		list(FIND BUILD_TYPES "${CMAKE_BUILD_TYPE}" BUILD_TYPE_FOUND)
		set(BUILD_TYPE_SUFFIX "")
		if(NOT ${BUILD_TYPE_FOUND} EQUAL -1)
			string(TOUPPER "${CMAKE_BUILD_TYPE}" UPPER_BUILD_TYPE)
			set(BUILD_TYPE_SUFFIX "_${UPPER_BUILD_TYPE}")
		endif()
		set(ep_asflags "${AUTOTOOLS_AS_FLAGS${BUILD_TYPE_SUFFIX}}")
		set(ep_cppflags "${AUTOTOOLS_CPP_FLAGS${BUILD_TYPE_SUFFIX}}")
		set(ep_cflags "${AUTOTOOLS_C_FLAGS${BUILD_TYPE_SUFFIX}}")
		set(ep_cxxflags "${AUTOTOOLS_CXX_FLAGS${BUILD_TYPE_SUFFIX}}")
		set(ep_objcflags "${AUTOTOOLS_OBJC_FLAGS${BUILD_TYPE_SUFFIX}}")
		set(ep_ldflags "${AUTOTOOLS_LINKER_FLAGS${BUILD_TYPE_SUFFIX}}")
	endif()
endmacro()


macro(linphone_builder_apply_extra_flags PROJNAME)
	if(EP_${PROJNAME}_BUILD_METHOD STREQUAL "autotools")
		set(ep_asflags "${ep_asflags} ${EP_${PROJNAME}_EXTRA_ASFLAGS}")
		set(ep_cppflags "${ep_cppflags} ${EP_${PROJNAME}_EXTRA_CPPFLAGS}")
		set(ep_cflags "${ep_cflags} ${EP_${PROJNAME}_EXTRA_CFLAGS}")
		set(ep_cxxflags "${ep_cxxflags} ${EP_${PROJNAME}_EXTRA_CXXFLAGS}")
		set(ep_objcflags "${ep_objcflags} ${EP_${PROJNAME}_EXTRA_OBJCFLAGS}")
		set(ep_ldflags "${ep_ldflags} ${EP_${PROJNAME}_EXTRA_LDFLAGS}")
	else()
		foreach(BUILD_CONFIG "" "_DEBUG" "_MINSIZEREL" "_RELEASE" "_RELWITHDEBINFO")
			if(EP_${PROJNAME}_EXTRA_CFLAGS)
				set(CMAKE_C_FLAGS${BUILD_CONFIG} "${CMAKE_C_FLAGS${BUILD_CONFIG}} ${EP_${PROJNAME}_EXTRA_CFLAGS}")
			endif()
			if(EP_${PROJNAME}_EXTRA_CXXFLAGS)
				set(CMAKE_CXX_FLAGS${BUILD_CONFIG} "${CMAKE_CXX_FLAGS${BUILD_CONFIG}} ${EP_${PROJNAME}_EXTRA_CXXFLAGS}")
			endif()
			if(EP_${PROJNAME}_EXTRA_LDFLAGS)
				set(CMAKE_EXE_LINKER_FLAGS${BUILD_CONFIG} "${CMAKE_EXE_LINKER_FLAGS${BUILD_CONFIG}} ${EP_${PROJNAME}_EXTRA_LDFLAGS}")
				set(CMAKE_MODULE_LINKER_FLAGS${BUILD_CONFIG} "${CMAKE_MODULE_LINKER_FLAGS${BUILD_CONFIG}} ${EP_${PROJNAME}_EXTRA_LDFLAGS}")
				set(CMAKE_SHARED_LINKER_FLAGS${BUILD_CONFIG} "${CMAKE_SHARED_LINKER_FLAGS${BUILD_CONFIG}} ${EP_${PROJNAME}_EXTRA_LDFLAGS}")
			endif()
		endforeach()
	endif()
endmacro()


macro(linphone_builder_set_ep_directories PROJNAME)
	if(EP_${PROJNAME}_SOURCE_DIR)
		set(ep_source "${EP_${PROJNAME}_SOURCE_DIR}")
	else()
		set(ep_source "${ep_base}/Source/EP_${PROJNAME}")
	endif()
	if(EP_${PROJNAME}_BUILD_IN_SOURCE)
		set(ep_build "${ep_source}")
	else()
		set(ep_build "${ep_base}/Build/${PROJNAME}")
	endif()
endmacro()


macro(linphone_builder_create_autogen_command PROJNAME)
	if(EP_${PROJNAME}_USE_AUTOGEN)
		if(EP_${PROJNAME}_CONFIGURE_OPTIONS_PASSED_TO_AUTOGEN)
			set(ep_autogen_options "")
			foreach(OPTION ${EP_${PROJNAME}_CROSS_COMPILATION_OPTIONS} ${EP_${PROJNAME}_LINKING_TYPE} ${EP_${PROJNAME}_CONFIGURE_OPTIONS})
				set(ep_autogen_options "${ep_autogen_options} \"${OPTION}\"")
			endforeach()
		endif()
		set(ep_autogen_command "\"${ep_source}/autogen.sh\" ${ep_autogen_options}")
	else()
		set(ep_autogen_command "")
	endif()
endmacro()


macro(linphone_builder_create_configure_command PROJNAME)
	if(EP_${PROJNAME}_CONFIGURE_OPTIONS_PASSED_TO_AUTOGEN)
		set(ep_configure_command "")
	else()
		set(ep_configure_options "")
		foreach(OPTION ${EP_${PROJNAME}_CROSS_COMPILATION_OPTIONS} ${EP_${PROJNAME}_LINKING_TYPE} ${EP_${PROJNAME}_CONFIGURE_OPTIONS})
			set(ep_configure_options "${ep_configure_options} \"${OPTION}\"")
		endforeach()
		set(ep_configure_env "${EP_${PROJNAME}_CONFIGURE_ENV}")
		set(ep_configure_command "\"${ep_source}/configure\" ${ep_configure_options}")
	endif()
endmacro()


macro(linphone_builder_create_build_command PROJNAME)
	set(ep_make_options "${EP_${PROJNAME}_MAKE_OPTIONS}")
endmacro()


# this function invokes configure_file() for the project, using the default file if
# the specific file is not defined
function(linphone_builder_configure_file_for_project PROJNAME CMD DEFAULT_CONF_FILE OUTPUT)
	if(NOT EP_${PROJNAME}_${CMD}_COMMAND_SOURCE)
		message(STATUS "Using default file ${DEFAULT_CONF_FILE} for ${CMD} step of ${PROJNAME}")
		configure_file(${DEFAULT_CONF_FILE} ${OUTPUT})
	else()
		message(STATUS "Using specific file ${EP_${PROJNAME}_${CMD}_COMMAND_SOURCE} for ${CMD} step of ${PROJNAME}")
		configure_file(${EP_${PROJNAME}_${CMD}_COMMAND_SOURCE} ${OUTPUT})
	endif()
endfunction()

macro(linphone_builder_filter_out_inexistent_dependencies PROJNAME)
	if(EP_${PROJNAME}_DEPENDENCIES)
		set(_new_deps )
		foreach(_dep ${EP_${PROJNAME}_DEPENDENCIES})
			string(REGEX REPLACE "^EP_" "" _dep2 ${_dep})
			list(FIND LINPHONE_BUILDER_INCLUDED_BUILDERS ${_dep2} _found)
			list(FIND LINPHONE_BUILDER_INCLUDED_BUILDERS_TO_EXCLUDE ${_dep2} _excluded_found)
			list(FIND LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH_BUILDERS ${_dep2} _external_source_path_found)
			if((_found GREATER -1) AND (_excluded_found EQUAL -1) AND ((_external_source_path_found EQUAL -1) OR (NOT EP_${_dep2}_GROUPABLE)))
				list(APPEND _new_deps ${_dep})
			endif()
		endforeach()
		unset(_dep)
		unset(_found)
		unset(_external_source_path_found)
		set(EP_${PROJNAME}_DEPENDENCIES ${_new_deps})
		unset(_new_deps)
	endif()
endmacro()

function(linphone_builder_add_external_project PROJNAME)
	if(LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH)
		foreach(SUBDIR ${EP_${PROJNAME}_EXTERNAL_SOURCE_PATHS})
			if(NOT EP_${PROJNAME}_SOURCE_DIR)
				if(EXISTS "${LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH}/${SUBDIR}")
					set(EP_${PROJNAME}_SOURCE_DIR "${LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH}/${SUBDIR}")
				endif()
			endif()
		endforeach()
	endif()

	linphone_builder_set_ep_directories(${PROJNAME})
	if(NOT EP_${PROJNAME}_DO_NOT_USE_CMAKE_FLAGS)
		linphone_builder_apply_cmake_flags_to_autotools_project(${PROJNAME})
	endif()
	linphone_builder_apply_extra_flags(${PROJNAME})
	linphone_builder_expand_external_project_vars()

	if(EP_${PROJNAME}_BUILD_METHOD STREQUAL "prebuilt")
		message("Using prebuilt ${PROJNAME}")
		set(BUILD_COMMANDS
			CONFIGURE_COMMAND ${CMAKE_COMMAND} -E echo ""
			BUILD_COMMAND ${CMAKE_COMMAND} -E echo ""
			INSTALL_COMMAND ${CMAKE_COMMAND} -DSOURCE_DIR=<SOURCE_DIR> -DINSTALL_DIR=${CMAKE_INSTALL_PREFIX} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/install_prebuilt.cmake
		)
	elseif(EP_${PROJNAME}_BUILD_METHOD STREQUAL "custom")
		if(WIN32)
			set(ep_redirect_to_file "2>&1 >> \"${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}.log\"")
		endif()
		configure_file(${EP_${PROJNAME}_CONFIGURE_COMMAND_SOURCE} ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_configure.sh)
		configure_file(${EP_${PROJNAME}_BUILD_COMMAND_SOURCE} ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_build.sh)
		configure_file(${EP_${PROJNAME}_INSTALL_COMMAND_SOURCE} ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_install.sh)
		if(WIN32)
			set(SCRIPT_EXTENSION bat)
			set(MSVC_PROJNAME ${PROJNAME})
			configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mingw_configure.bat.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_configure.bat)
			configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mingw_build.bat.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_build.bat)
			configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mingw_install.bat.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_install.bat)
		else()
			set(SCRIPT_EXTENSION sh)
		endif()
		set(BUILD_COMMANDS
			CONFIGURE_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_configure.${SCRIPT_EXTENSION}
			BUILD_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_build.${SCRIPT_EXTENSION}
			INSTALL_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_install.${SCRIPT_EXTENSION}
		)
	elseif(EP_${PROJNAME}_BUILD_METHOD STREQUAL "autotools")
		linphone_builder_create_autogen_command(${PROJNAME})
		linphone_builder_create_configure_command(${PROJNAME})
		linphone_builder_create_build_command(${PROJNAME})
		if(EP_${PROJNAME}_CONFIG_H_FILE)
			set(ep_config_h_file ${EP_${PROJNAME}_CONFIG_H_FILE})
		else()
			set(ep_config_h_file config.h)
		endif()
		if(EP_${PROJNAME}_INSTALL_TARGET)
			set(ep_install_target "${EP_${PROJNAME}_INSTALL_TARGET}")
		else()
			set(ep_install_target "install")
		endif()

		if(WIN32)
			set(ep_redirect_to_file "2>&1 >> \"${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}.log\"")
			set(SCRIPT_EXTENSION bat)
			set(MSVC_PROJNAME ${PROJNAME})
			configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mingw_configure.bat.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_configure.bat)
			configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mingw_build.bat.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_build.bat)
			configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mingw_install.bat.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_install.bat)
			# Build in source with MinGW as build out-of-source does not work
			set(ep_build "${ep_source}")
			if(ep_autogen_command)
				set(ep_autogen_redirect_to_file ${ep_redirect_to_file})
			endif()
			if(ep_configure_command)
				set(ep_configure_redirect_to_file ${ep_redirect_to_file})
			endif()
		else()
			set(SCRIPT_EXTENSION sh)
		endif()

		if(EP_${PROJNAME}_PKG_CONFIG)
			set(LINPHONE_BUILDER_PKG_CONFIG "${EP_${PROJNAME}_PKG_CONFIG}")
		else()
			set(LINPHONE_BUILDER_PKG_CONFIG "${PKG_CONFIG_PROGRAM}")
		endif()

		configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/configure.sh.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_configure.sh)
		configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/build.sh.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_build.sh)
		configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/install.sh.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_install.sh)

		set(BUILD_COMMANDS
			CONFIGURE_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_configure.${SCRIPT_EXTENSION}
			BUILD_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_build.${SCRIPT_EXTENSION}
			INSTALL_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_install.${SCRIPT_EXTENSION}
		)
	elseif(EP_${PROJNAME}_BUILD_METHOD STREQUAL "rpm")

		if(WIN32)
			message(SEND_ERROR "rpm build not supported on WIN32")
		endif()

		linphone_builder_create_autogen_command(${PROJNAME})
		linphone_builder_create_configure_command(${PROJNAME})

		if(EP_${PROJNAME}_CONFIG_H_FILE)
			set(ep_config_h_file ${EP_${PROJNAME}_CONFIG_H_FILE})
		else()
			set(ep_config_h_file config.h)
		endif()

		if(EP_${PROJNAME}_INSTALL_TARGET)
			set(ep_install_target "${EP_${PROJNAME}_INSTALL_TARGET}")
		else()
			set(ep_install_target "install")
		endif()

		if(EP_${PROJNAME}_SPEC_FILE)
			set(LINPHONE_BUILDER_SPEC_FILE "${EP_${PROJNAME}_SPEC_FILE}")
		else()
			message(SEND_ERROR "rpm build requires EP_${PROJNAME}_SPEC_FILE to be defined")
		endif()

		# a distinctive name of the generated RPM. It is used to find the rpms to install
		# in the install step. Defaults to $PROJNAME but could be something else
		if(EP_${PROJNAME}_RPMBUILD_NAME)
			set(LINPHONE_BUILDER_RPMBUILD_NAME "${EP_${PROJNAME}_RPMBUILD_NAME}")
		else()
			set(LINPHONE_BUILDER_RPMBUILD_NAME "${PROJNAME}")
		endif()

		# a distinctive name of the generated RPM. It is used to find the rpms to install
		# in the install step. Defaults to $PROJNAME but could be something else
		if(EP_${PROJNAME}_RPMBUILD_OPTIONS)
			set(LINPHONE_BUILDER_RPMBUILD_OPTIONS "${EP_${PROJNAME}_RPMBUILD_OPTIONS}")
		endif()

		set(LINPHONE_BUILDER_SPEC_PREFIX "${EP_${PROJNAME}_SPEC_PREXIX}")

		if(EP_${PROJNAME}_PKG_CONFIG)
			set(LINPHONE_BUILDER_PKG_CONFIG "${EP_${PROJNAME}_PKG_CONFIG}")
		else()
			set(LINPHONE_BUILDER_PKG_CONFIG "${PKG_CONFIG_PROGRAM}")
		endif()

		if(EP_${PROJNAME}_CONFIGURE_EXTRA_CMD)
			set(LINPHONE_BUILDER_CONFIGURE_EXTRA_CMD "${EP_${PROJNAME}_CONFIGURE_EXTRA_CMD}")
		endif()

		# allow to have special command steps
		linphone_builder_configure_file_for_project(${PROJNAME} CONFIGURE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/configure.rpm.sh.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_configure_rpm.sh)
		linphone_builder_configure_file_for_project(${PROJNAME} BUILD ${CMAKE_CURRENT_SOURCE_DIR}/cmake/build.rpm.sh.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_build_rpm.sh)
		linphone_builder_configure_file_for_project(${PROJNAME} INSTALL ${CMAKE_CURRENT_SOURCE_DIR}/cmake/install.rpm.sh.cmake ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_install_rpm.sh)

		set(BUILD_COMMANDS
			CONFIGURE_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_configure_rpm.sh
			BUILD_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_build_rpm.sh
			INSTALL_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/EP_${PROJNAME}_install_rpm.sh
		)
	else()
		# Use CMake build method
		set(BUILD_COMMANDS
			CMAKE_ARGS ${EP_${PROJNAME}_CMAKE_OPTIONS} ${EP_${PROJNAME}_LINKING_TYPE}
			CMAKE_CACHE_ARGS ${LINPHONE_BUILDER_EP_ARGS}
		)
	endif()

	if(LINPHONE_BUILDER_LATEST AND EP_${PROJNAME}_GIT_TAG_LATEST)
		set(DOWNLOAD_SOURCE GIT_REPOSITORY ${EP_${PROJNAME}_GIT_REPOSITORY} GIT_TAG ${EP_${PROJNAME}_GIT_TAG_LATEST})
	elseif(EP_${PROJNAME}_SOURCE_DIR)
		set(DOWNLOAD_SOURCE SOURCE_DIR "${EP_${PROJNAME}_SOURCE_DIR}")
	elseif(EP_${PROJNAME}_URL)
		set(DOWNLOAD_SOURCE URL ${EP_${PROJNAME}_URL})
		if(EP_${PROJNAME}_URL_HASH)
			list(APPEND DOWNLOAD_SOURCE URL_HASH ${EP_${PROJNAME}_URL_HASH})
		endif()
	else()
		set(DOWNLOAD_SOURCE GIT_REPOSITORY ${EP_${PROJNAME}_GIT_REPOSITORY} GIT_TAG ${EP_${PROJNAME}_GIT_TAG})
	endif()

	linphone_builder_filter_out_inexistent_dependencies(${PROJNAME})

	ExternalProject_Add(EP_${PROJNAME}
		DEPENDS ${EP_${PROJNAME}_DEPENDENCIES}
		BINARY_DIR "${ep_build}"
		${DOWNLOAD_SOURCE}
		PATCH_COMMAND ${EP_${PROJNAME}_PATCH_COMMAND}
		CMAKE_GENERATOR ${CMAKE_GENERATOR}
		${BUILD_COMMANDS}
	)

	if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/builders/${PROJNAME}/postinstall.cmake)
		ExternalProject_Add_Step(EP_${PROJNAME} postinstall
			COMMAND ${CMAKE_COMMAND} -DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE} -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR} -DINSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -P ${CMAKE_CURRENT_SOURCE_DIR}/builders/${PROJNAME}/postinstall.cmake
			COMMENT "Performing post-installation for 'EP_${PROJNAME}'"
			DEPENDEES install
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		)
	endif()
	if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/builders/${PROJNAME}/postconfig.cmake)
		ExternalProject_Add_Step(EP_${PROJNAME} postconfig
			COMMAND ${CMAKE_COMMAND} -DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE} -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR} -DINSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -P ${CMAKE_CURRENT_SOURCE_DIR}/builders/${PROJNAME}/postinstall.cmake
			COMMENT "Performing post-configuration for 'EP_${PROJNAME}'"
			DEPENDEES install
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		)
	endif()

	if(EP_${PROJNAME}_GROUPED_SOURCE_DIRS OR EP_${PROJNAME}_SOURCE_DIR)
		if(EP_${PROJNAME}_GROUPED_SOURCE_DIRS)
			set(_source_dirs ${EP_${PROJNAME}_GROUPED_SOURCE_DIRS})
		else()
			set(_source_dirs ${EP_${PROJNAME}_SOURCE_DIR})
		endif()
		ExternalProject_Add_Step(EP_${PROJNAME} check_changes
			COMMENT "Checking for source code changes for 'EP_${PROJNAME}'"
			DEPENDEES update patch
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			ALWAYS 1
		)
		_ep_get_step_stampfile(EP_${PROJNAME} check_changes _stamp_file) # Private API of ExternalProject module
		add_custom_command(OUTPUT "${ep_build}/check_changes.txt"
			COMMAND ${CMAKE_COMMAND} -DSOURCE_DIRS=${_source_dirs} -DBINARY_DIR=${ep_build} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_changes.cmake
			DEPENDS ${_stamp_file}
		)
		# TODO: ExternalProject_Add_StepDependencies is available only from CMake 3.2
		#ExternalProject_Add_StepDependencies(EP_${PROJNAME} configure "${ep_build}/check_changes.txt")
		_ep_get_step_stampfile(EP_${PROJNAME} configure _stamp_file) # Private API of ExternalProject module
		add_custom_command(APPEND
			OUTPUT ${_stamp_file}
			DEPENDS "${ep_build}/check_changes.txt"
		)
		unset(_source_dirs)
		unset(_stamp_file)
	endif()

endfunction()

macro(linphone_builder_add_grouped_external_source_path_project PROJNAME FILENAME)
	linphone_builder_filter_out_inexistent_dependencies(${PROJNAME})
	file(APPEND "${FILENAME}" "add_subdirectory(\"${EP_${PROJNAME}_SOURCE_DIR}\" \"${LINPHONE_BUILDER_WORK_DIR}/Build/${PROJNAME}\")\n")
	list(APPEND EP_linphone_builder_LINKING_TYPES "${EP_${PROJNAME}_LINKING_TYPE}")
	list(APPEND EP_linphone_builder_CMAKE_OPTIONS "${EP_${PROJNAME}_CMAKE_OPTIONS}")
	list(APPEND EP_linphone_builder_EXTRA_CFLAGS "${EP_${PROJNAME}_EXTRA_CFLAGS}")
	list(APPEND EP_linphone_builder_EXTRA_CPPFLAGS "${EP_${PROJNAME}_EXTRA_CPPFLAGS}")
	list(APPEND EP_linphone_builder_EXTRA_CXXFLAGS "${EP_${PROJNAME}_EXTRA_CXXFLAGS}")
	list(APPEND EP_linphone_builder_EXTRA_LDFLAGS "${EP_${PROJNAME}_EXTRA_LDFLAGS}")
	list(APPEND EP_linphone_builder_EXTRA_OBJCFLAGS "${EP_${PROJNAME}_EXTRA_OBJCFLAGS}")
	list(APPEND EP_linphone_builder_ADDITIONAL_CMAKE_OPTIONS "-DEP_${PROJNAME}_INCLUDE_DIR=${EP_${PROJNAME}_SOURCE_DIR}/include")
	list(APPEND EP_linphone_builder_ADDITIONAL_CMAKE_OPTIONS "-DEP_${PROJNAME}_CONFIG_DIR=${LINPHONE_BUILDER_WORK_DIR}/Build/${PROJNAME}")
	if(EP_${PROJNAME}_DEPENDENCIES)
		list(APPEND EP_linphone_builder_DEPENDENCIES ${EP_${PROJNAME}_DEPENDENCIES})
	endif()
endmacro()

function(linphone_builder_add_external_projects)
	foreach(BUILDER ${LINPHONE_BUILDER_INCLUDED_BUILDERS})
		list(FIND LINPHONE_BUILDER_INCLUDED_BUILDERS_TO_EXCLUDE ${BUILDER} _excluded_found)
		list(FIND LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH_BUILDERS ${BUILDER} _external_source_path_found)
		if((_excluded_found EQUAL -1) AND ((_external_source_path_found EQUAL -1) OR (NOT LINPHONE_BUILDER_GROUP_EXTERNAL_SOURCE_PATH_BUILDERS) OR (NOT EP_${BUILDER}_GROUPABLE)))
			linphone_builder_add_external_project(${BUILDER})
		endif()
	endforeach()
endfunction()

macro(detect_conflicting_cmake_options)
	if(EP_linphone_builder_CMAKE_OPTIONS)
		list(REMOVE_DUPLICATES EP_linphone_builder_CMAKE_OPTIONS)
		set(_new_options )
		foreach(_option ${EP_linphone_builder_CMAKE_OPTIONS})
			string(REGEX MATCH "^-D(.+)=(.*)$" _match "${_option}")
			if(_match)
				set(_new_option "-D${CMAKE_MATCH_1}=")
				if(CMAKE_MATCH_2)
					set(_new_option "${_new_option}ON")
					set(_conflicting_option "${_new_option}OFF")
				else()
					set(_new_option "${_new_option}OFF")
					set(_conflicting_option "${_new_option}ON")
				endif()
				list(FIND _new_options "${_new_option}" _found)
				list(FIND _new_options "${_conflicting_option}" _conflict_found)
				if(_found EQUAL -1)
					list(APPEND _new_options "${_new_option}")
				endif()
				if(_conflict_found GREATER -1)
					message(FATAL_ERROR "Conflicting options ${_new_option} and ${_conflicting_option}")
				endif()
			endif()
		endforeach()
		if(_new_options)
			set(EP_linphone_builder_CMAKE_OPTIONS ${_new_options})
		endif()
	endif()
endmacro()

function(linphone_builder_add_grouped_external_source_path_projects)
	set(_grouped_builders)
	if(LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH_BUILDERS)
		foreach (_builder ${LINPHONE_BUILDER_EXTERNAL_SOURCE_PATH_BUILDERS})
			if(EP_${_builder}_GROUPABLE)
				list(APPEND _grouped_builders ${_builder})
			endif()
		endforeach()
	endif()
	if(LINPHONE_BUILDER_GROUP_EXTERNAL_SOURCE_PATH_BUILDERS AND _grouped_builders)
		make_directory("${LINPHONE_BUILDER_WORK_DIR}/Source/EP_linphone_builder")
		set(_linphone_builder_file "${LINPHONE_BUILDER_WORK_DIR}/Source/EP_linphone_builder/CMakeLists.txt")
		file(WRITE "${_linphone_builder_file}" "cmake_minimum_required(VERSION 3.0)\n")
		file(APPEND "${_linphone_builder_file}" "project(EP_linphone_builder)\n")
		file(APPEND "${_linphone_builder_file}" "option(LINPHONE_BUILDER_GROUP_EXTERNAL_SOURCE_PATH_BUILDERS \"Group external source path builders.\" ON)\n")
		set(EP_linphone_builder_CMAKE_OPTIONS )
		set(EP_linphone_builder_LINKING_TYPES )
		set(EP_linphone_builder_EXTRA_CFLAGS )
		set(EP_linphone_builder_EXTRA_CPPFLAGS )
		set(EP_linphone_builder_EXTRA_CXXFLAGS )
		set(EP_linphone_builder_EXTRA_LDFLAGS )
		set(EP_linphone_builder_EXTRA_OBJCFLAGS )
		set(EP_linphone_builder_DEPENDENCIES )
		set(EP_linphone_builder_GROUPED_SOURCE_DIRS )
		foreach(BUILDER ${_grouped_builders})
			list(APPEND EP_linphone_builder_GROUPED_SOURCE_DIRS ${EP_${BUILDER}_SOURCE_DIR})
			linphone_builder_add_grouped_external_source_path_project(${BUILDER} "${_linphone_builder_file}")
		endforeach()
		list(REMOVE_DUPLICATES EP_linphone_builder_LINKING_TYPES)
		list(LENGTH EP_linphone_builder_LINKING_TYPES _conflicting_linking_types)
		if(_conflicting_linking_types GREATER 1)
			message(FATAL_ERROR "Conflicing linking types in grouped external source path projects: ${EP_linphone_builder_LINKING_TYPES}")
		else()
			set(EP_linphone_builder_LINKING_TYPE ${EP_linphone_builder_LINKING_TYPES})
		endif()
		detect_conflicting_cmake_options()
		if(EP_linphone_builder_EXTRA_CFLAGS)
			list(REMOVE_DUPLICATES EP_linphone_builder_EXTRA_CFLAGS)
		endif()
		if(EP_linphone_builder_EXTRA_CPPFLAGS)
			list(REMOVE_DUPLICATES EP_linphone_builder_EXTRA_CPPFLAGS)
		endif()
		if(EP_linphone_builder_EXTRA_CXXFLAGS)
			list(REMOVE_DUPLICATES EP_linphone_builder_EXTRA_CXXFLAGS)
		endif()
		if(EP_linphone_builder_EXTRA_LDFLAGS)
			list(REMOVE_DUPLICATES EP_linphone_builder_EXTRA_LDFLAGS)
		endif()
		if(EP_linphone_builder_EXTRA_OBJCFLAGS)
			list(REMOVE_DUPLICATES EP_linphone_builder_EXTRA_OBJCFLAGS)
		endif()
		if(EP_linphone_builder_DEPENDENCIES)
			list(REMOVE_DUPLICATES EP_linphone_builder_DEPENDENCIES)
		endif()
		list(APPEND EP_linphone_builder_CMAKE_OPTIONS ${EP_linphone_builder_ADDITIONAL_CMAKE_OPTIONS})
		linphone_builder_add_external_project("linphone_builder")
		add_dependencies(TARGET_linphone_builder EP_linphone_builder)
		unset(_conflicting_linking_types)
		unset(_linphone_builder_file)
		unset(_grouped_builders)
	endif()
endfunction()

function(linphone_builder_add_projects)
	linphone_builder_add_external_projects()
	linphone_builder_add_grouped_external_source_path_projects()
endfunction()

macro(linphone_builder_add_dummy_libraries_generation)
	if(LINPHONE_BUILDER_DUMMY_LIBRARIES)
		linphone_builder_apply_flags()
		linphone_builder_set_ep_directories(dummy_libraries)
		linphone_builder_expand_external_project_vars()
		ExternalProject_Add(EP_dummy_libraries
			DEPENDS TARGET_linphone_builder
			TMP_DIR "${ep_tmp}"
			BINARY_DIR "${ep_build}"
			SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/cmake/dummy_libraries"
			DOWNLOAD_COMMAND ""
			CMAKE_GENERATOR ${CMAKE_GENERATOR}
			CMAKE_ARGS ${LINPHONE_BUILDER_EP_ARGS} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DLINPHONE_BUILDER_DUMMY_LIBRARIES=${LINPHONE_BUILDER_DUMMY_LIBRARIES}
		)
	endif()
endmacro()
