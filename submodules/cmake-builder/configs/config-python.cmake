############################################################################
# config-python.cmake
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

# Define default values for the linphone builder options
set(DEFAULT_VALUE_ENABLE_FFMPEG ON)
set(DEFAULT_VALUE_ENABLE_GPL_THIRD_PARTIES ON)
set(DEFAULT_VALUE_ENABLE_GSM ON)
set(DEFAULT_VALUE_ENABLE_MKV ON)
set(DEFAULT_VALUE_ENABLE_OPUS ON)
set(DEFAULT_VALUE_ENABLE_SPEEX ON)
set(DEFAULT_VALUE_ENABLE_SRTP ON)
set(DEFAULT_VALUE_ENABLE_VIDEO ON)
set(DEFAULT_VALUE_ENABLE_VPX ON)
set(DEFAULT_VALUE_ENABLE_WASAPI ON)
set(DEFAULT_VALUE_ENABLE_ZRTP ON)

set(DEFAULT_VALUE_CMAKE_LINKING_TYPE "-DENABLE_STATIC=YES")


find_package(Doxygen REQUIRED)
find_package(PythonInterp REQUIRED)


# Global configuration
set(LINPHONE_BUILDER_PKG_CONFIG_LIBDIR ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig)	# Restrict pkg-config to search in the install directory

if (UNIX)
	if(APPLE)
		if(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
			execute_process(COMMAND "${PYTHON_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/configs/python/mac_getplatform.py"
				OUTPUT_VARIABLE MAC_PLATFORM
				OUTPUT_STRIP_TRAILING_WHITESPACE
			)
			list(GET MAC_PLATFORM 0 CMAKE_OSX_DEPLOYMENT_TARGET)
		endif()
		set(CMAKE_OSX_ARCHITECTURES "x86_64")

		set(LINPHONE_BUILDER_CPPFLAGS "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET} -arch ${CMAKE_OSX_ARCHITECTURES}")
		set(LINPHONE_BUILDER_OBJCFLAGS "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET} -arch ${CMAKE_OSX_ARCHITECTURES}")
		set(LINPHONE_BUILDER_LDFLAGS "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET} -arch ${CMAKE_OSX_ARCHITECTURES}")
	else()
		set(LINPHONE_BUILDER_LDFLAGS "-Wl,-Bsymbolic -fPIC")
	endif()
endif()
if(WIN32)
	set(LINPHONE_BUILDER_CPPFLAGS "-D_WIN32_WINNT=0x0501 -D_ALLOW_KEYWORD_MACROS")
endif()


# Include builders
include(builders/CMakeLists.txt)


# ffmpeg
set(EP_ffmpeg_LINKING_TYPE "--disable-static" "--enable-shared")

# linphone
list(APPEND EP_linphone_CMAKE_OPTIONS
	"-DENABLE_RELATIVE_PREFIX=YES"
	"-DENABLE_CONSOLE_UI=NO"
	"-DENABLE_GTK_UI=NO"
	"-DENABLE_NOTIFY=NO"
	"-DENABLE_TOOLS=NO"
	"-DENABLE_TUTORIALS=NO"
	"-DENABLE_UNIT_TESTS=NO"
	"-DENABLE_UPNP=NO"
	"-DENABLE_NLS=NO"
)

# ms2
list(APPEND EP_ms2_CMAKE_OPTIONS
	"-DENABLE_RELATIVE_PREFIX=YES"
	"-DENABLE_UNIT_TESTS=NO"
	"-DENABLE_TOOLS=NO"
	"-DENABLE_PCAP=NO"
)
if(UNIX AND NOT APPLE)
	list(APPEND EP_ms2_CMAKE_OPTIONS
		"-DENABLE_ALSA=YES"
		"-DENABLE_PULSEAUDIO=NO"
		"-DENABLE_OSS=NO"
		"-DENABLE_GLX=NO"
		"-DENABLE_X11=YES"
		"-DENABLE_XV=YES"
	)
endif()

# polarssl
set(EP_polarssl_LINKING_TYPE "-DUSE_SHARED_POLARSSL_LIBRARY=NO")

# v4l
set(EP_v4l_LINKING_TYPE "--enable-static" "--disable-shared" "--with-pic")

# vpx
set(EP_vpx_LINKING_TYPE "--enable-static" "--disable-shared" "--enable-pic")


# Python module
if(NOT PACKAGE_NAME)
	set(PACKAGE_NAME "linphone")
endif()
linphone_builder_apply_flags()
linphone_builder_set_ep_directories(pylinphone)
linphone_builder_expand_external_project_vars()
ExternalProject_Add(TARGET_pylinphone
	DEPENDS TARGET_linphone_builder
	TMP_DIR ${ep_tmp}
	BINARY_DIR ${ep_build}
	DOWNLOAD_COMMAND ""
	PATCH_COMMAND "${CMAKE_COMMAND}" "-E" "copy_directory" "${CMAKE_CURRENT_LIST_DIR}/python" "<SOURCE_DIR>"
		"COMMAND" "${CMAKE_COMMAND}" "-E" "copy" "${CMAKE_CURRENT_LIST_DIR}/../cmake/FindXML2.cmake" "<SOURCE_DIR>"
	CMAKE_GENERATOR ${CMAKE_GENERATOR}
	CMAKE_ARGS ${LINPHONE_BUILDER_EP_ARGS} -DPACKAGE_NAME=${PACKAGE_NAME} -DLINPHONE_SOURCE_DIR=${EP_linphone_SOURCE_DIR} -DENABLE_FFMPEG:BOOL=${ENABLE_FFMPEG} -DENABLE_OPENH264:BOOL=${ENABLE_OPENH264} -DENABLE_WASAPI:BOOL=${ENABLE_WASAPI}
)
