############################################################################
# config-bb10-arm.cmake
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

include(configs/config-bb10.cmake)

set(DEFAULT_VALUE_ENABLE_VPX ON)

# Global configuration
set(LINPHONE_BUILDER_CFLAGS "${LINPHONE_BUILDER_CFLAGS} -march=armv7-a -mfpu=neon")


# speex
list(APPEND EP_speex_CMAKE_OPTIONS
	"-DENABLE_FLOAT_API=0"
	"-DENABLE_FIXED_POINT=1"
	"-DENABLE_ARMV7_NEON_ASM=1"
)

# opus
list(APPEND EP_opus_CONFIGURE_OPTIONS "--enable-fixed-point")

# vpx
set(EP_vpx_LINKING_TYPE "--enable-static" "--disable-shared" "--enable-pic")