# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/mnt/Storage/HomeStuff/Documents/anicross/windows/_deps/nuget-src"
  "/mnt/Storage/HomeStuff/Documents/anicross/windows/_deps/nuget-build"
  "/mnt/Storage/HomeStuff/Documents/anicross/windows/_deps/nuget-subbuild/nuget-populate-prefix"
  "/mnt/Storage/HomeStuff/Documents/anicross/windows/_deps/nuget-subbuild/nuget-populate-prefix/tmp"
  "/mnt/Storage/HomeStuff/Documents/anicross/windows/_deps/nuget-subbuild/nuget-populate-prefix/src/nuget-populate-stamp"
  "/mnt/Storage/HomeStuff/Documents/anicross/windows/_deps/nuget-subbuild/nuget-populate-prefix/src"
  "/mnt/Storage/HomeStuff/Documents/anicross/windows/_deps/nuget-subbuild/nuget-populate-prefix/src/nuget-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/mnt/Storage/HomeStuff/Documents/anicross/windows/_deps/nuget-subbuild/nuget-populate-prefix/src/nuget-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/mnt/Storage/HomeStuff/Documents/anicross/windows/_deps/nuget-subbuild/nuget-populate-prefix/src/nuget-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
