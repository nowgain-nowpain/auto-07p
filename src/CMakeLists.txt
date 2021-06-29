
cmake_minimum_required (VERSION 3.6)
project (Auto C CXX Fortran)

#enable_language (Fortran)

# make sure that the default is a RELEASE
if (NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE RELEASE CACHE STRING
      "Choose the type of build, options are: None Debug Release."
      FORCE)
endif (NOT CMAKE_BUILD_TYPE)

# default installation
get_filename_component (default_prefix ".." ABSOLUTE)
set (CMAKE_INSTALL_PREFIX ${default_prefix} CACHE STRING
      "Choose the installation directory; by default it installs in the Auto directory."
      FORCE)

# FFLAGS depend on the compiler
get_filename_component (Fortran_COMPILER_NAME ${CMAKE_Fortran_COMPILER} NAME)

if (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  # gfortran
  set (CMAKE_Fortran_FLAGS_RELEASE "-funroll-all-loops -fno-f2c -O3")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-fno-f2c -O0 -g")
elseif (Fortran_COMPILER_NAME MATCHES "ifort.*")
  # ifort (untested)
  set (CMAKE_Fortran_FLAGS_RELEASE "-f77rtl -O3")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-f77rtl -O0 -g")
elseif (Fortran_COMPILER_NAME MATCHES "g77")
  # g77
  set (CMAKE_Fortran_FLAGS_RELEASE "-funroll-all-loops -fno-f2c -O3 -m32")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-fno-f2c -O0 -g -m32")
else (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  message ("CMAKE_Fortran_COMPILER full path: " ${CMAKE_Fortran_COMPILER})
  message ("Fortran compiler: " ${Fortran_COMPILER_NAME})
  message ("No optimized Fortran compiler flags are known, we just try -O2...")
  set (CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-O0 -g")
endif (Fortran_COMPILER_NAME MATCHES "gfortran.*")


# build executables
#set (NMPROGRAMS "diagstd" "diagrtb" "proj_modes_bin" "pdbmat")
#set (EXECUTABLES "Auto.exe" ${NMPROGRAMS})
#set (SCRIPTS "gen_pert.sh" "pert_multi_mode.sh")

set (AUTO_FSRC_FILES
  blas.f  
  fcon.f
  lapack.f
  ae.f90
  auto_constants.f90
  bvp.f90
  compat.f90
  equilibrium.f90
  f2003.f90
  floquet.f90
  homcont.f90
  interfaces.f90
  io.f90
  main.f90
  maps.f90
  mesh.f90
  optimization.f90
  parabolic.f90
  periodic.f90
  solvebv.f90
  support.f90
  timeint.f90
  toolboxae.f90
  toolboxbv.f90
  unix.f90
  nompi.f90
)

#  mpi.f90

set (AUTO_CSRC_FILES
  user_c.c 
  ../include/auto_f2c.h 
  ../include/config.h
)

set (AUTO_HEADER_FILES
  ../include
#  ../include/auto.h
)


# This is what run() does:
#AUTO> run()
#gcc -O -DPTHREADS -O -I/home/amavisitors/redrod/src/auto/2000/include -c ab.c
#gcc -O ab.o -o ab.exe /home/amavisitors/redrod/src/auto/2000/lib/*.o
#-lpthread -L/home/amavisitors/redrod/src/auto/2000/lib -lauto_f2c -lm
#

# create the auto_c library so that user can link to it.
add_library(auto_f
   ${AUTO_FSRC_FILES}
)
target_include_directories(auto_f
  PUBLIC
    ${AUTO_HEADER_FILES}
)

add_library(auto_c
   ${AUTO_CSRC_FILES}
)

target_include_directories(auto_c
  PUBLIC
    ${AUTO_HEADER_FILES}
)

target_link_libraries(auto_c
  PUBLIC
    ${auto_f}
)

#foreach (p ${NMPROGRAMS})
#  add_executable (${p} "${p}.f")
#endforeach (p)

# install executables and scripts
#install (TARGETS ${EXECUTABLES}
#         RUNTIME DESTINATION "bin")
#install (PROGRAMS ${SCRIPTS}
#         DESTINATION "bin")

