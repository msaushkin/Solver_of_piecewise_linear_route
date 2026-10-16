cmake_minimum_required(VERSION 3.16)

project(solver
    VERSION 0.1.0
    DESCRIPTION "Solver piecewise linear route (SFML)"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Пользователь может указать SFML_DIR, если SFML собран/установлен в другом месте.
find_package(SFML 2.5 COMPONENTS graphics window system QUIET)

if(SFML_FOUND)
    message(STATUS "SFML found: ${SFML_LIBRARIES}")
else()
    message(FATAL_ERROR "SFML 2.5 not found. Set SFML_DIR to the SFML install prefix.")
endif()

add_executable(solver
    source/main.cpp
    source/app.h
    source/tools.h
)

target_include_directories(solver PRIVATE source)

# SFML 2.5 статический конфиг экспортирует импортируемые таргеты.
# Привязываемся к таргету sfml-graphics (он тянет window/system и зависимости).
if(TARGET sfml-graphics)
    target_link_libraries(solver PRIVATE sfml-graphics)
else()
    target_link_libraries(solver PRIVATE ${SFML_LIBRARIES})
endif()

# SFML 2.5 статическая сборка на Linux связывается только с libOpenGL.
# На современных дистрибутивах (glvnd: Ubuntu 22.04+) функции GLX лежат в отдельной libGLX.
# --as-needed по умолчанию в Ubuntu отбрасывает libGLX, если она идёт до статического
# архива SFML, поэтому отключаем его для этого таргета.
if(UNIX)
    find_package(OpenGL QUIET)
    if(TARGET OpenGL::GLX)
        target_link_libraries(solver PRIVATE OpenGL::GLX)
    else()
        find_library(GLX_LIBRARY NAMES GLX)
        if(GLX_LIBRARY)
            target_link_libraries(solver PRIVATE ${GLX_LIBRARY})
        endif()
    endif()
    set_property(TARGET solver APPEND_STRING PROPERTY LINK_FLAGS " -Wl,--no-as-needed")
endif()

# Копируем шрифты и иконку рядом с исполняемым файлом при сборке.
# Ресурсы могут лежать в source/ или resources/.
file(GLOB FONTS
    "${CMAKE_SOURCE_DIR}/source/*.ttf"
    "${CMAKE_SOURCE_DIR}/resources/*.ttf")
file(GLOB ICONS
    "${CMAKE_SOURCE_DIR}/resources/*.png"
    "${CMAKE_SOURCE_DIR}/resources/*.ico")
set(RESOURCES ${FONTS} ${ICONS})
if(RESOURCES)
    add_custom_command(TARGET solver POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${RESOURCES} $<TARGET_FILE_DIR:solver>
        COMMENT "Copying resources next to solver")
endif()