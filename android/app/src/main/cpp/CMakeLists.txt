cmake_minimum_required(VERSION 3.18.1)
project("ramstore")

add_library(ramstore SHARED
    # JNI bridge would go here if needed
)

find_library(log-lib log)

target_link_libraries(ramstore
    ${log-lib}
)

