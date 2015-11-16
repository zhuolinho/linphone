############################################################################
# CMakeLists.txt
# Copyright (C) 2015  Belledonne Communications, Grenoble France
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

set(LIBS
	${MEDIASTREAMER2_LIBRARIES}
	${X264_LIBRARIES}
)

set(SOURCE_FILES msx264.c)

if(ENABLE_STATIC)
	add_library(msx264 STATIC ${SOURCE_FILES})
else()
	add_library(msx264 SHARED ${SOURCE_FILES})
	set_target_properties(msx264 PROPERTIES VERSION 0)
	if(MSVC)
		if(CMAKE_BUILD_TYPE STREQUAL "Debug")
			install(FILES ${CMAKE_CURRENT_BINARY_DIR}/Debug/libmsx264.pdb
				DESTINATION bin
				PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
			)
		endif()
		set_target_properties(msx264 PROPERTIES PREFIX "lib")
	endif()
endif()
set_target_properties(msx264 PROPERTIES LINKER_LANGUAGE CXX LINK_FLAGS "${LINK_FLAGS}")
target_link_libraries(msx264 ${LIBS})

install(TARGETS msx264
	RUNTIME DESTINATION lib/mediastreamer/plugins
	LIBRARY DESTINATION lib/mediastreamer/plugins
	ARCHIVE DESTINATION lib/mediastreamer/plugins
	PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)
