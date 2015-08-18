cmake_minimum_required(VERSION 2.8)
cmake_policy(SET CMP0015 NEW)
# let cmake autolink dependencies on windows
cmake_policy(SET CMP0020 NEW)
# this policy was introduced in cmake 3.0
# remove if, once 3.0 will be used on unix
if (${CMAKE_MAJOR_VERSION} GREATER 2)
	cmake_policy(SET CMP0043 OLD)
endif()

project(mix)

set(CMAKE_AUTOMOC ON)
set(BUILD_DIR_NAME "build" CACHE STRING "The name of the build directory in cpp-ethereum")
set(CPPETHEREUM_BUILD "${CMAKE_CURRENT_SOURCE_DIR}/../cpp-ethereum/${BUILD_DIR_NAME}")
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cpp-ethereum-cmake)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(GUI 1)
set(JSONRPC 1)
set(ETH_HAVE_WEBENGINE TRUE)
add_definitions(-DETH_TRUE)
include(EthDependencies)
include(EthExecutableHelper)
include(EthCompilerSettings)

aux_source_directory("./src" SRC_LIST)
message("SRC_LIST: ${SRC_LIST}")

include_directories(BEFORE ${JSONCPP_INCLUDE_DIRS})
include_directories(${Boost_INCLUDE_DIRS})
include_directories(BEFORE ..)
include_directories(src)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../cpp-ethereum)
include_directories(${CPPETHEREUM_BUILD})

set(CMAKE_LIBRARY_PATH ${CPPETHEREUM_BUILD} ${CMAKE_LIBRARY_PATH})


if (("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang") AND NOT (CMAKE_CXX_COMPILER_VERSION VERSION_LESS "3.6") AND NOT APPLE)
	# Supress warnings for qt headers for clang+ccache
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-inconsistent-missing-override")
endif ()

#TODO: remove once qt 5.5.1 is out
if (APPLE)
    qt5_add_resources(UI_RESOURCES osx.qrc)
endif()

find_package(Eth)
find_package(Qt5Core)
find_package (Qt5WebEngine)
if (APPLE AND (NOT "${Qt5Core_VERSION_STRING}" VERSION_LESS "5.5"))
# TODO: remove indirect dependencies once macdeployqt is fixed
	find_package (Qt5WebEngineCore)
	find_package (Qt5DBus)
	find_package (Qt5PrintSupport)
endif()
qt5_add_resources(UI_RESOURCES res.qrc qml.qrc)
qt5_add_resources(UI_RESOURCES web.qrc)

file(GLOB HEADERS "src/*.h")

set(EXECUTABLE mix)

if (CMAKE_BUILD_TYPE MATCHES Debug)
	add_definitions(-DQT_QML_DEBUG)
endif()

# eth_add_executable is defined in cmake/EthExecutableHelper.cmake
eth_add_executable(${EXECUTABLE} 
	ICON mix
	UI_RESOURCES ${UI_RESOURCES}
)

set(LIBRARIES "${ETH_CORE_LIBRARIES};${ETH_SOLIDITY_LIBRARY};${JSON_RPC_CPP_SERVER_LIBRARIES};${JSONCPP_LIBRARIES};${Boost_SYSTEM_LIBRARIES};${Boost_THREAD_LIBRARIES};${Boost_RANDOM_LIBRARIES};${CRYPTOPP_LIBRARIES};Qt5::Core;Qt5::Gui;Qt5::Widgets;Qt5::Network;Qt5::Quick;Qt5::Qml")
message("LIBS: ${LIBRARIES}")
if (${ETH_HAVE_WEBENGINE})
	add_definitions(-DETH_HAVE_WEBENGINE)
	list(APPEND LIBRARIES "Qt5::WebEngine")
endif()
if (APPLE AND (NOT "${Qt5Core_VERSION_STRING}" VERSION_LESS "5.5"))
	list(APPEND LIBRARIES "Qt5::WebEngineCore")
	list(APPEND LIBRARIES "Qt5::DBus")
	list(APPEND LIBRARIES "Qt5::PrintSupport")
endif()
if (UNIX)
    target_link_libraries(${EXECUTABLE} pthread)
endif()

target_link_libraries(${EXECUTABLE} ${LIBRARIES})

# eth_install_executable is defined in cmake/EthExecutableHelper.cmake
eth_install_executable(${EXECUTABLE}
	QMLDIR ${CMAKE_CURRENT_SOURCE_DIR}/qml
)

#add qml asnd stdc files to project tree in Qt creator
file(GLOB_RECURSE QMLFILES "qml/*.*")
file(GLOB_RECURSE TESTFILES "test/qml/*.*")
file(GLOB_RECURSE SOLFILES "stdc/*.*")
add_custom_target(mix_qml SOURCES ${QMLFILES} ${SOLFILES} ${TESTFILES})

#test target
find_package(Qt5QuickTest REQUIRED)
find_package(Qt5Test REQUIRED)
set(TEST_EXECUTABLE mix_test)
list(APPEND LIBRARIES "Qt5::QuickTest")
list(APPEND LIBRARIES "Qt5::Test")
list(REMOVE_ITEM SRC_LIST "src/main.cpp")
aux_source_directory(test SRC_LIST)
file(GLOB HEADERS "test/*.h")
add_executable(${TEST_EXECUTABLE} ${UI_RESOURCES} ${SRC_LIST} ${HEADERS})
target_link_libraries(${TEST_EXECUTABLE} ${LIBRARIES})
set_target_properties(${TEST_EXECUTABLE} PROPERTIES EXCLUDE_FROM_ALL 1 EXCLUDE_FROM_DEFAULT_BUILD 1)



