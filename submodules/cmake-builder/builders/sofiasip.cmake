############################################################################
# sofiasip.cmake
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

set(EP_sofiasip_GIT_REPOSITORY "git://git.linphone.org/sofia-sip.git" CACHE STRING "sofiasip repository URL")
set(EP_sofiasip_GIT_TAG_LATEST "bc" CACHE STRING "sofiasip tag to use when compiling latest version")
set(EP_sofiasip_GIT_TAG "ec5145ddde0a0452999b08df4e3c61f3ff5f6730" CACHE STRING "sofiasip tag to use")
set(EP_sofiasip_EXTERNAL_SOURCE_PATHS "externals/sofia-sip")
#set(EP_sofiasip_CMAKE_OPTIONS )
#set(EP_sofiasip_LINKING_TYPE "-DENABLE_STATIC=0")

set(EP_sofiasip_DEPENDENCIES )
set(EP_sofiasip_LINKING_TYPE "--disable-static" "--enable-shared")
set(EP_sofiasip_BUILD_METHOD "autotools")
set(EP_sofiasip_USE_AUTOGEN True)
set(EP_sofiasio_BUILD_IN_SOURCE True)
set(EP_sofiasip_CONFIGURE_OPTIONS )
set(EP_sofiasip_CROSS_COMPILATION_OPTIONS
	"--prefix=${CMAKE_INSTALL_PREFIX}"
	"--host=${LINPHONE_BUILDER_HOST}"
)

# RPM 
set(EP_sofiasip_SPEC_FILE "packages/sofia-sip-*.spec")
set(EP_sofiasip_RPMBUILD_NAME "sofia-sip")
