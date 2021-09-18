cmake_minimum_required(VERSION 3.12.4)

project(AGE)

add_executable($(PROJECT_NAME) main.cpp)

add_subdirectory(MyCode)

target_include_directories($(PROJECT_NAME) PUBLUC MyCode)
target_include_directories($(PROJECT_NAME) PRIVATE MyCode)
target_include_directories($(PROJECT_NAME) MyCode)
