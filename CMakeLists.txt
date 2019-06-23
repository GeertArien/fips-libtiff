#
# project: fips-libtiff
#
cmake_minimum_required(VERSION 2.8)

# include the fips main cmake file
get_filename_component(FIPS_ROOT_DIR "../fips" ABSOLUTE)
include("${FIPS_ROOT_DIR}/cmake/fips.cmake")

fips_setup(PROJECT fips-libtiff)
fips_include_directories(libtiff)
fips_add_subdirectory(libtiff)
fips_finish()


