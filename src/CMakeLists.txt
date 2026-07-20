# AUTO-07p core engine build (CMake).
#
# Goal (refactor-plan.md W0): reproduce EXACTLY the autotools lib/ layout that
# the Python CLI (runAUTO.py) and cmds/cmds.make depend on at runtime:
#   - one loose object per engine source, deposited in <root>/lib/  (the CLI
#     links `$AUTO_DIR/lib/*.o` wholesale, including main.o = PROGRAM AUTO)
#   - lib/libauto_c.a built from user_c.f90 (linked via -lauto_c for C equations)
#   - user_c.o is NOT left loose in lib/ (it lives only inside libauto_c.a)
#   - fcon.f is NOT built here: it is the standalone PROGRAM AUTCON, compiled
#     on demand by cmds.make. Putting it in lib/*.o would inject a second
#     PROGRAM and break every user-equation link.
# See src/Makefile.in for the authoritative object list this mirrors.

set(LIB_DIR "${CMAKE_SOURCE_DIR}/lib")

# @MPIFILE@ selection: nompi.f90 stub by default, real mpi.f90 with WITH_MPI.
if(WITH_MPI)
  set(AUTO_MPI_SRC mpi.f90)
else()
  set(AUTO_MPI_SRC nompi.f90)
endif()

# Engine sources, grouped by component (mirrors src/Makefile.in; NOT user_c.f90,
# NOT fcon.f). Kept in one OBJECT library so the deposited lib/*.o set is
# identical to autotools; the grouping documents the real components.
set(AUTO_CORE_SOURCES              # continuation/bifurcation engine core
  ae.f90 auto_constants.f90 bvp.f90 equilibrium.f90 f2003.f90 floquet.f90
  homcont.f90 interfaces.f90 io.f90 main.f90 maps.f90 mesh.f90
  optimization.f90 parabolic.f90 periodic.f90 solvebv.f90 support.f90
  timeint.f90 toolboxae.f90 toolboxbv.f90)
set(AUTO_MATH_SOURCES blas.f lapack.f)          # vendored BLAS/LAPACK
set(AUTO_PARALLEL_SOURCES ${AUTO_MPI_SRC})      # MPI stub (nompi) or real mpi
set(AUTO_ENGINE_SOURCES
  ${AUTO_CORE_SOURCES} ${AUTO_MATH_SOURCES} ${AUTO_PARALLEL_SOURCES})

# Shared module dir so auto_c (user_c.f90) can `use` engine modules (support, ...).
set(CMAKE_Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/modules")

# Match the autotools flags (src build used: gfortran -g -fopenmp -O).
set(AUTO_FFLAGS -g -fopenmp -O)

# --- Engine as an OBJECT library -> the loose lib/*.o the CLI globs ----------
add_library(auto_engine OBJECT ${AUTO_ENGINE_SOURCES})
target_include_directories(auto_engine PRIVATE "${CMAKE_SOURCE_DIR}/include")
target_compile_options(auto_engine PRIVATE ${AUTO_FFLAGS})

# Deposit the loose objects into <root>/lib/ (CLI links $AUTO_DIR/lib/*.o).
# OBJECT libraries can't carry POST_BUILD commands, so use a custom target that
# runs after auto_engine. CMake names objects <src>.o (e.g. main.f90.o); the
# *.o glob still matches.
add_custom_target(deposit_engine_objects ALL
  COMMAND "${CMAKE_COMMAND}" -E make_directory "${LIB_DIR}"
  COMMAND "${CMAKE_COMMAND}" -E copy_if_different $<TARGET_OBJECTS:auto_engine> "${LIB_DIR}/"
  COMMAND_EXPAND_LISTS
  COMMENT "Depositing engine objects into lib/ (CLI links lib/*.o)")
add_dependencies(deposit_engine_objects auto_engine)

# --- C-interface archive: lib/libauto_c.a from user_c.f90 -------------------
add_library(auto_c STATIC user_c.f90)
add_dependencies(auto_c auto_engine)          # needs support.mod etc.
target_include_directories(auto_c PRIVATE "${CMAKE_SOURCE_DIR}/include")
target_compile_options(auto_c PRIVATE ${AUTO_FFLAGS})
set_target_properties(auto_c PROPERTIES
  OUTPUT_NAME auto_c
  ARCHIVE_OUTPUT_DIRECTORY "${LIB_DIR}")
