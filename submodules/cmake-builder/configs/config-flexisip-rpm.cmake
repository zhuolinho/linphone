############################################################################
# config-flexisip-rpm.cmake
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

include(GNUInstallDirs)
include(${CMAKE_SOURCE_DIR}/cmake/FindLinuxPlatform.cmake)

# Check if we have everything to compile correctly

FUNCTION(CHECK_PROGRAM progname)
	find_program(${progname}_PROGRAM
		NAMES ${progname}
	)
	if(NOT ${progname}_PROGRAM)
		message(FATAL_ERROR "Could not find the ${progname} program, which is needed for RPMBuild")
	else()
		message(STATUS "Found ${progname} : ${${progname}_PROGRAM}.")
	endif()
ENDFUNCTION()

FUNCTION(CHECK_LIBRARY libname)
	find_library(${libname}_LIBRARY
		NAMES ${libname}
		PATHS /usr/lib/mysql/
	)
	if(NOT ${libname}_LIBRARY)
		message(FATAL_ERROR "Could not find the ${libname} library, which is needed for RPMBuild of flexisip")
	else()
		message(STATUS "Found ${libname} : ${${libname}_LIBRARY}.")
	endif()
ENDFUNCTION()

# Doxygen can be found through CMake
find_package(Doxygen REQUIRED)

# the rest will be checked manually
FOREACH(PROGNAME rpmbuild bison)
	CHECK_PROGRAM(${PROGNAME})
ENDFOREACH()


set(FLEXISIP_LIBDEPS ssl mysqlclient_r mysqlclient)
if(PLATFORM STREQUAL "Debian")
	list(APPEND FLEXISIP_LIBDEPS hiredis)
endif()

FOREACH(LIBNAME ${FLEXISIP_LIBDEPS})
	CHECK_LIBRARY(${LIBNAME})
ENDFOREACH()


# Define default values for the flexisip builder options
set(DEFAULT_VALUE_ENABLE_ODBC ON)
set(DEFAULT_VALUE_ENABLE_PUSHNOTIFICATION ON)
set(DEFAULT_VALUE_ENABLE_REDIS ON)

set(DEFAULT_VALUE_CMAKE_LINKING_TYPE "-DENABLE_STATIC=NO")


# Global configuration
set(LINPHONE_BUILDER_HOST "")

set(RPM_INSTALL_PREFIX "/opt/belledonne-communications")

# Adjust PKG_CONFIG_PATH to include install directory
if(UNIX)
	set(LINPHONE_BUILDER_PKG_CONFIG_PATH "${RPM_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/pkgconfig/:${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/pkgconfig/:$ENV{PKG_CONFIG_PATH}:/usr/${CMAKE_INSTALL_LIBDIR}/pkgconfig/:/usr/${CMAKE_INSTALL_LIBDIR}/x86_64-linux-gnu/pkgconfig/:/usr/share/pkgconfig/:/usr/local/${CMAKE_INSTALL_LIBDIR}/pkgconfig/:/opt/local/${CMAKE_INSTALL_LIBDIR}/pkgconfig/")
	message(STATUS "PKG CONFIG PATH: ${LINPHONE_BUILDER_PKG_CONFIG_PATH}")
	message(STATUS "LIBDIR: ${LIBDIR}")
else() # Windows
	set(LINPHONE_BUILDER_PKG_CONFIG_PATH "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig/")
endif()

# needed *before* the include
set(EP_ortp_FORCE_AUTOTOOLS True)
#required to use autotools
set(EP_bellesip_USE_AUTOGEN True)


# Include builders
include(builders/CMakeLists.txt)

set(EP_bellesip_LINKING_TYPE "--enable-static")

set(EP_ortp_BUILD_METHOD     "rpm")
set(EP_bellesip_BUILD_METHOD     "rpm")
set(EP_sofiasip_BUILD_METHOD "rpm")
set(EP_flexisip_BUILD_METHOD "rpm")
set(EP_odb_BUILD_METHOD      "custom")

set(EP_ortp_SPEC_PREFIX     "${RPM_INSTALL_PREFIX}")
set(EP_bellesip_SPEC_PREFIX     "${RPM_INSTALL_PREFIX}")
set(EP_sofiasip_SPEC_PREFIX "${RPM_INSTALL_PREFIX}")
set(EP_flexisip_SPEC_PREFIX "${RPM_INSTALL_PREFIX}")

set(EP_flexisip_CONFIGURE_OPTIONS "--disable-transcoder" "--enable-redis" "--enable-libodb=no" "--enable-libodb-mysql=no")


set(EP_ortp_RPMBUILD_OPTIONS      "--with bc --without srtp")
set(EP_unixodbc_RPMBUILD_OPTIONS  "--with bc")
set(EP_myodbc_RPMBUILD_OPTIONS    "--with bc")
set(EP_sofiasip_RPMBUILD_OPTIONS  "--with bc --without glib")
set(EP_hiredis_RPMBUILD_OPTIONS   "--with bc" )
set(EP_flexisip_RPMBUILD_OPTIONS  "--with bc --without transcoder --without boostlog --with push")
set(EP_bellesip_RPMBUILD_OPTIONS  "--with bc ")

if (ENABLE_PRESENCE)
	set(EP_flexisip_RPMBUILD_OPTIONS "${EP_flexisip_RPMBUILD_OPTIONS} --with presence")
	list(APPEND EP_flexisip_CONFIGURE_OPTIONS "--enable-presence")
endif()

if(ENABLE_BC_ODBC)
	set(EP_unixodbc_BUILD_METHOD       "rpm")
	set(EP_myodbc_BUILD_METHOD         "rpm")
	set(EP_unixodbc_SPEC_PREFIX        "${RPM_INSTALL_PREFIX}")
	set(EP_myodbc_SPEC_PREFIX          "${RPM_INSTALL_PREFIX}")
	set(EP_myodbc_CONFIGURE_OPTIONS    "--with-unixODBC=${RPM_INSTALL_PREFIX}")
	set(EP_flexisip_RPMBUILD_OPTIONS   "${EP_flexisip_RPMBUILD_OPTIONS} --with bcodbc")
	list(APPEND EP_flexisip_CONFIGURE_OPTIONS "--with-odbc=${RPM_INSTALL_PREFIX}")
endif()

set(LINPHONE_BUILDER_RPMBUILD_PACKAGE_PREFIX "bc-")

# prepare the RPMBUILD options that we need to pass

set(RPMBUILD_OPTIONS "--define '_mandir %{_prefix}'")

if(PLATFORM STREQUAL "Debian")
	# dependencies cannot be checked by rpmbuild in debian
	set(RPMBUILD_OPTIONS "${RPMBUILD_OPTIONS} --nodeps")

	# dist is not defined in debian for rpmbuild..
	set(RPMBUILD_OPTIONS "${RPMBUILD_OPTIONS} --define 'dist .deb'")

	# debian has multi-arch lib dir instead of lib and lib64
	set(RPMBUILD_OPTIONS "${RPMBUILD_OPTIONS} --define '_libdir %{_prefix}/${CMAKE_INSTALL_LIBDIR}'")

	# some debians are using dash as shell, which doesn't support "export -n", so we override and use bash
	set(RPMBUILD_OPTIONS "${RPMBUILD_OPTIONS} --define '_buildshell /bin/bash'")

	# boost is to be found from debian's multiarch lib dirs
	find_package(Boost REQUIRED COMPONENTS system)
	list(APPEND EP_flexisip_CONFIGURE_OPTIONS "--with-boost-libdir=${Boost_LIBRARY_DIRS}")
	set(EP_flexisip_RPMBUILD_OPTIONS "${EP_flexisip_RPMBUILD_OPTIONS} --define 'boostlibdir ${Boost_LIBRARY_DIRS}'")

	# redis for debian 7 will be installed in the prefix, but we have to pass it through a special flag to the RPM build, since there
	# is no pkgconfig
	list(APPEND EP_flexisip_DEPENDENCIES EP_hiredis)
	list(APPEND EP_flexisip_CONFIGURE_OPTIONS "--with-redis=${CMAKE_INSTALL_PREFIX}")
	set(EP_flexisip_RPMBUILD_OPTIONS "${EP_flexisip_RPMBUILD_OPTIONS} --define 'hiredisdir ${RPM_INSTALL_PREFIX}'")	

	CHECK_PROGRAM(alien)
	CHECK_PROGRAM(fakeroot)
endif()

set(LINPHONE_BUILDER_RPMBUILD_GLOBAL_OPTION ${RPMBUILD_OPTIONS})
