set(tiff_VERSION_MAJOR 4)
set(tiff_VERSION_MINOR 0)
set(tiff_VERSION_PATCH 10)
set(VERSION "${tiff_VERSION_MAJOR}.${tiff_VERSION_MINOR}.${tiff_VERSION_PATCH}")
set(tiff_VERSION "${VERSION}")

# the other tiff_VERSION_* variables are set automatically
set(tiff_VERSION_ALPHA)

include(CheckCSourceCompiles)
include(CheckIncludeFile)
include(CheckSymbolExists)

macro(current_date var)
    if(UNIX)
        execute_process(COMMAND "date" +"%Y%m%d" OUTPUT_VARIABLE ${var})
    endif()
endmacro()

current_date(RELEASE_DATE)

check_include_file(assert.h    HAVE_ASSERT_H)
check_include_file(dlfcn.h     HAVE_DLFCN_H)
check_include_file(fcntl.h     HAVE_FCNTL_H)
check_include_file(inttypes.h  HAVE_INTTYPES_H)
check_include_file(io.h        HAVE_IO_H)
check_include_file(search.h    HAVE_SEARCH_H)
check_include_file(stdint.h    HAVE_STDINT_H)
check_include_file(string.h    HAVE_STRING_H)
check_include_file(strings.h   HAVE_STRINGS_H)
check_include_file(sys/time.h  HAVE_SYS_TIME_H)
check_include_file(sys/types.h HAVE_SYS_TYPES_H)
check_include_file(unistd.h    HAVE_UNISTD_H)

# Inspired from /usr/share/autoconf/autoconf/c.m4
foreach(inline_keyword "inline" "__inline__" "__inline")
    if(NOT DEFINED C_INLINE)
        set(CMAKE_REQUIRED_DEFINITIONS_SAVE ${CMAKE_REQUIRED_DEFINITIONS})
        set(CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS}
                "-Dinline=${inline_keyword}")
        check_c_source_compiles("
        typedef int foo_t;
        static inline foo_t static_foo() {return 0;}
        foo_t foo(){return 0;}
        int main(int argc, char *argv[]) {return 0;}"
                C_HAS_${inline_keyword})
        set(CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS_SAVE})
        if(C_HAS_${inline_keyword})
            set(C_INLINE TRUE)
            set(INLINE_KEYWORD "${inline_keyword}")
        endif()
    endif()
endforeach()
if(NOT DEFINED C_INLINE)
    set(INLINE_KEYWORD)
endif()

# Check if sys/time.h and time.h allow use together
check_c_source_compiles("
#include <sys/time.h>
#include <time.h>
int main(void){return 0;}"
        TIME_WITH_SYS_TIME)

# Check if struct tm is in sys/time.h
check_c_source_compiles("
#include <sys/types.h>
#include <time.h>

int main(void){
  struct tm tm;
  int *p = &tm.tm_sec;
  return !p;
}"
        TM_IN_SYS_TIME)

# Check type sizes
# NOTE: Could be replaced with C99 <stdint.h>
if (FIPS_EMSCRIPTEN)
    set(SIZEOF_SIGNED_INT 4)
    set(SIZEOF_UNSIGNED_INT 4)
    set(SIZEOF_SIGNED_LONG 4)
    set(SIZEOF_UNSIGNED_LONG 4)
    set(SIZEOF_SIGNED_LONG_LONG 8)
    set(SIZEOF_UNSIGNED_LONG_LONG 8)
    set(SIZEOF_UNSIGNED_CHAR_P 4)
    set(SIZEOF_SIZE_T 4)
    set(SIZEOF_PTRDIFF_T 4)
else()
    include(CheckTypeSize)
    check_type_size("signed int" SIZEOF_SIGNED_INT)
    check_type_size("unsigned int" SIZEOF_UNSIGNED_INT)
    check_type_size("signed long" SIZEOF_SIGNED_LONG)
    check_type_size("unsigned long" SIZEOF_UNSIGNED_LONG)
    check_type_size("signed long long" SIZEOF_SIGNED_LONG_LONG)
    check_type_size("unsigned long long" SIZEOF_UNSIGNED_LONG_LONG)
    check_type_size("unsigned char *" SIZEOF_UNSIGNED_CHAR_P)

    set(CMAKE_EXTRA_INCLUDE_FILES_SAVE ${CMAKE_EXTRA_INCLUDE_FILES})
    set(CMAKE_EXTRA_INCLUDE_FILES ${CMAKE_EXTRA_INCLUDE_FILES} "stddef.h")
    check_type_size("size_t" SIZEOF_SIZE_T)
    check_type_size("ptrdiff_t" SIZEOF_PTRDIFF_T)
    set(CMAKE_EXTRA_INCLUDE_FILES ${CMAKE_EXTRA_INCLUDE_FILES_SAVE})
endif()

set(TIFF_INT8_T "signed char")
set(TIFF_UINT8_T "unsigned char")

set(TIFF_INT16_T "signed short")
set(TIFF_UINT16_T "unsigned short")

if(SIZEOF_SIGNED_INT EQUAL 4)
    set(TIFF_INT32_T "signed int")
    set(TIFF_INT32_FORMAT "%d")
elseif(SIZEOF_SIGNED_LONG EQUAL 4)
    set(TIFF_INT32_T "signed long")
    set(TIFF_INT32_FORMAT "%ld")
endif()

if(SIZEOF_UNSIGNED_INT EQUAL 4)
    set(TIFF_UINT32_T "unsigned int")
    set(TIFF_UINT32_FORMAT "%u")
elseif(SIZEOF_UNSIGNED_LONG EQUAL 4)
    set(TIFF_UINT32_T "unsigned long")
    set(TIFF_UINT32_FORMAT "%lu")
endif()

if(SIZEOF_SIGNED_LONG EQUAL 8)
    set(TIFF_INT64_T "signed long")
    set(TIFF_INT64_FORMAT "%ld")
elseif(SIZEOF_SIGNED_LONG_LONG EQUAL 8)
    set(TIFF_INT64_T "signed long long")
    if (MINGW)
        set(TIFF_INT64_FORMAT "%I64d")
    else()
        set(TIFF_INT64_FORMAT "%lld")
    endif()
endif()

if(SIZEOF_UNSIGNED_LONG EQUAL 8)
    set(TIFF_UINT64_T "unsigned long")
    set(TIFF_UINT64_FORMAT "%lu")
elseif(SIZEOF_UNSIGNED_LONG_LONG EQUAL 8)
    set(TIFF_UINT64_T "unsigned long long")
    if (MINGW)
        set(TIFF_UINT64_FORMAT "%I64u")
    else()
        set(TIFF_UINT64_FORMAT "%llu")
    endif()
endif()

if(SIZEOF_UNSIGNED_INT EQUAL SIZEOF_SIZE_T)
    set(TIFF_SIZE_T "unsigned int")
    set(TIFF_SIZE_FORMAT "%u")
elseif(SIZEOF_UNSIGNED_LONG EQUAL SIZEOF_SIZE_T)
    set(TIFF_SIZE_T "unsigned long")
    set(TIFF_SIZE_FORMAT "%lu")
elseif(SIZEOF_UNSIGNED_LONG_LONG EQUAL SIZEOF_SIZE_T)
    set(TIFF_SIZE_T "unsigned long long")
    if (MINGW)
        set(TIFF_SIZE_FORMAT "%I64u")
    else()
        set(TIFF_SIZE_FORMAT "%llu")
    endif()
endif()

if(SIZEOF_SIGNED_INT EQUAL SIZEOF_UNSIGNED_CHAR_P)
    set(TIFF_SSIZE_T "signed int")
    set(TIFF_SSIZE_FORMAT "%d")
elseif(SIZEOF_SIGNED_LONG EQUAL SIZEOF_UNSIGNED_CHAR_P)
    set(TIFF_SSIZE_T "signed long")
    set(TIFF_SSIZE_FORMAT "%ld")
elseif(SIZEOF_SIGNED_LONG_LONG EQUAL SIZEOF_UNSIGNED_CHAR_P)
    set(TIFF_SSIZE_T "signed long long")
    if (MINGW)
        set(TIFF_SSIZE_FORMAT "%I64d")
    else()
        set(TIFF_SSIZE_FORMAT "%lld")
    endif()
endif()

if(NOT SIZEOF_PTRDIFF_T)
    set(TIFF_PTRDIFF_T "${TIFF_SSIZE_T}")
    set(TIFF_PTRDIFF_FORMAT "${SSIZE_FORMAT}")
else()
    set(TIFF_PTRDIFF_T "ptrdiff_t")
    set(TIFF_PTRDIFF_FORMAT "%ld")
endif()

check_symbol_exists(mmap "sys/mman.h" HAVE_MMAP)
check_symbol_exists(setmode "unistd.h" HAVE_SETMODE)
check_symbol_exists(snprintf "stdio.h" HAVE_SNPRINTF)
check_symbol_exists(strcasecmp "strings.h" HAVE_STRCASECMP)
check_symbol_exists(strtol "stdlib.h" HAVE_STRTOL)
check_symbol_exists(strtoll "stdlib.h" HAVE_STRTOLL)
check_symbol_exists(strtoul "stdlib.h" HAVE_STRTOUL)
check_symbol_exists(strtoull "stdlib.h" HAVE_STRTOULL)
check_symbol_exists(getopt "unistd.h" HAVE_GETOPT)
check_symbol_exists(lfind "search.h" HAVE_LFIND)

if(NOT HAVE_SNPRINTF)
    add_definitions(-DNEED_LIBPORT)
endif()

# CPU bit order
set(HOST_FILLORDER FILLORDER_MSB2LSB)
if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "i.*86.*" OR
        CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "amd64.*" OR
        CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "x86_64.*")
    set(HOST_FILLORDER FILLORDER_LSB2MSB)
endif()

# CPU endianness
include(TestBigEndian)
test_big_endian(HOST_BIG_ENDIAN)

# IEEE floating point
set(HAVE_IEEEFP 1)

# Large file support
if (UNIX OR MINGW)
    # This might not catch every possibility catered for by
    # AC_SYS_LARGEFILE.
    add_definitions(-D_FILE_OFFSET_BITS=64)
    set(FILE_OFFSET_BITS 64)
endif()


# Options to enable and disable internal codecs

option(TIFF_CCITT "support for CCITT Group 3 & 4 algorithms" ON)
set(CCITT_SUPPORT ${TIFF_CCITT})

option(TIFF_PACKBITS "support for Macintosh PackBits algorithm" ON)
set(PACKBITS_SUPPORT ${TIFF_PACKBITS})

option(TIFF_LZW "support for LZW algorithm" ON)
set(LZW_SUPPORT ${TIFF_LZW})

option(TIFF_THUNDER "support for ThunderScan 4-bit RLE algorithm" ON)
set(THUNDER_SUPPORT ${TIFF_THUNDER})

option(TIFF_NEXT "support for NeXT 2-bit RLE algorithm" ON)
set(NEXT_SUPPORT ${TIFF_NEXT})

option(TIFF_LOGLUV "support for LogLuv high dynamic range algorithm" ON)
set(LOGLUV_SUPPORT ${TIFF_LOGLUV})

# Option for Microsoft Document Imaging
option(TIFF_MDI "support for Microsoft Document Imaging" ON)
set(MDI_SUPPORT ${TIFF_MDI})

# libm dynamic
option(TIFF_MATH_SHARED "Use shared library for math" OFF)
set(M_LIBRARY_FOUND FALSE)
if(TIFF_MATH_SHARED)
    find_library(M_LIBRARY m)
    if(M_LIBRARY)
        set(M_LIBRARY_FOUND TRUE)
    endif()
endif()

# ZLIB
option(TIFF_ZLIB "use zlib (required for Deflate compression)" OFF)
set(ZLIB_FOUND FALSE)
if (TIFF_ZLIB)
    # workaround for correctly setting ZLIB_INCLUDE_DIR, which is required for file generation scripts
    get_property(ZLIB_INCLUDE_DIRS DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
    list(FILTER ZLIB_INCLUDE_DIRS INCLUDE REGEX "(.*)zlib(.*)")
    if (ZLIB_INCLUDE_DIRS)
        set(ZLIB_INCLUDE_DIR ${ZLIB_INCLUDE_DIRS})
        set(ZLIB_FOUND TRUE)
    endif()
endif()
set(ZLIB_SUPPORT FALSE)
if(ZLIB_FOUND)
    set(ZLIB_SUPPORT TRUE)
endif()

# Option for Pixar log-format algorithm
option(TIFF_PIXARLOG "support for Pixar log-format algorithm (requires Zlib)" OFF)
set(PIXARLOG_SUPPORT FALSE)
if (ZLIB_SUPPORT)
    if(TIFF_PIXARLOG)
        set(PIXARLOG_SUPPORT TRUE)
    endif()
endif()

# JPEG
set(TIFF_JPEG OFF)
#option(TIFF_JPEG "use libjpeg (required for JPEG compression)" ON)
#if (TIFF_JPEG)
#  find_package(JPEG)
#endif()
set(JPEG_SUPPORT FALSE)
set(JPEG_FOUND FALSE)
#if(JPEG_FOUND)
#  set(JPEG_SUPPORT TRUE)
#endif()

set(TIFF_OLD_JPEG OFF)
#option(TIFF_OLD_JPEG "support for Old JPEG compression (read-only)" ON)
set(OJPEG_SUPPORT FALSE)
#if (JPEG_SUPPORT)
#  if (TIFF_OLD_JPEG)
#    set(OJPEG_SUPPORT TRUE)
#  endif()
#endif()

# JBIG-KIT
set(TIFF_JBIG OFF)
#option(TIFF_JBIG "use ISO JBIG compression (requires JBIT-KIT library)" ON)
#if (TIFF_JBIG)
#  set(JBIG_FOUND 0)
#  find_path(JBIG_INCLUDE_DIR jbig.h)
#  set(JBIG_NAMES ${JBIG_NAMES} jbig libjbig)
#  find_library(JBIG_LIBRARY NAMES ${JBIG_NAMES})
#  if (JBIG_INCLUDE_DIR AND JBIG_LIBRARY)
#    set(JBIG_FOUND 1)
#    set(JBIG_LIBRARIES ${JBIG_LIBRARY})
#  endif()
#endif()
set(JBIG_SUPPORT FALSE)
set(JBIG_FOUND FALSE)
#if(JBIG_FOUND)
#  set(JBIG_FOUND TRUE)
#  set(JBIG_SUPPORT 1)
#endif()

#set(CMAKE_REQUIRED_INCLUDES_SAVE ${CMAKE_REQUIRED_INCLUDES})
#set(CMAKE_REQUIRED_INCLUDES ${CMAKE_REQUIRED_INCLUDES} ${JBIG_INCLUDE_DIR})
#check_symbol_exists(jbg_newlen "jbig.h" HAVE_JBG_NEWLEN)
#set(CMAKE_REQUIRED_INCLUDES ${CMAKE_REQUIRED_INCLUDES_SAVE})

# liblzma2
set(TIFF_LZMA OFF)
#option(TIFF_LZMA "use liblzma (required for LZMA2 compression)" ON)
#if (TIFF_LZMA)
#  find_package(LibLZMA)
#endif()
set(LZMA_SUPPORT FALSE)
set(LIBLZMA_FOUND FALSE)
#if(LIBLZMA_FOUND)
#  set(LZMA_SUPPORT 1)
#endif()

# libzstd
set(TIFF_ZSTD OFF)
#option(TIFF_ZSTD "use libzstd (required for ZSTD compression)" ON)
#if (TIFF_ZSTD)
#  find_path(ZSTD_INCLUDE_DIR zstd.h)
#  find_library(ZSTD_LIBRARY NAMES zstd)
#  if (ZSTD_INCLUDE_DIR AND ZSTD_LIBRARY)
#    check_library_exists ("${ZSTD_LIBRARY}" ZSTD_decompressStream "" ZSTD_RECENT_ENOUGH)
#    if (ZSTD_RECENT_ENOUGH)
#      set(ZSTD_FOUND TRUE)
#      set(ZSTD_LIBRARIES ${ZSTD_LIBRARY})
#      message(STATUS "Found ZSTD library: ${ZSTD_LIBRARY}")
#    else ()
#      message(WARNING "Found ZSTD library, but not recent enough. Use zstd >= 1.0")
#    endif ()
#  endif ()
#endif()
set(ZSTD_SUPPORT FALSE)
set(ZSTD_FOUND FALSE)
#if(ZSTD_FOUND)
#  set(ZSTD_SUPPORT 1)
#endif()

# libwebp
set(TIFF_WEBP OFF)
#option(TIFF_WEBP "use libwebp (required for WEBP compression)" ON)
#if (TIFF_WEBP)
#  find_path(WEBP_INCLUDE_DIR /webp/decode.h)
#  find_library(WEBP_LIBRARY NAMES webp)
#endif()
set(WEBP_SUPPORT FALSE)
set(WEBP_FOUND FALSE)
#if (WEBP_INCLUDE_DIR AND WEBP_LIBRARY)
#  set(WEBP_SUPPORT 1)
#  set(WEBP_FOUND TRUE)
#  set(WEBP_LIBRARIES ${WEBP_LIBRARY})
#  message(STATUS "Found WEBP library: ${WEBP_LIBRARY}")
#endif()

# 8/12-bit jpeg mode
set(TIFF_JPEG12 OFF)
#option(TIFF_JPEG12 "enable libjpeg 8/12-bit dual mode (requires separate
#12-bit libjpeg build)" ON)
#set(JPEG12_INCLUDE_DIR JPEG12_INCLUDE_DIR-NOTFOUND CACHE PATH "Include directory for 12-bit libjpeg")
#set(JPEG12_LIBRARY JPEG12_LIBRARY-NOTFOUND CACHE FILEPATH "12-bit libjpeg library")
set(JPEG12_FOUND FALSE)
#if (JPEG12_INCLUDE_DIR AND JPEG12_LIBRARY)
#  set(JPEG12_LIBRARIES ${JPEG12_LIBRARY})
#  set(JPEG12_FOUND TRUE)
#endif()
#if (JPEG12_FOUND)
#  set(JPEG_DUAL_MODE_8_12 1)
#  set(LIBJPEG_12_PATH "${JPEG12_INCLUDE_DIR}/jpeglib.h")
#endif()

# C++ support
option(TIFF_CXX "Enable C++ stream API building (requires C++ compiler)" ON)
set(CXX_SUPPORT FALSE)
if (TIFF_CXX)
    set(CXX_SUPPORT TRUE)
endif()

# OpenGL and GLUT
#find_package(OpenGL)
#find_package(GLUT)
set(HAVE_OPENGL FALSE)
#if(OPENGL_FOUND AND OPENGL_GLU_FOUND AND GLUT_FOUND)
#  set(HAVE_OPENGL TRUE)
#endif()
# Purely to satisfy the generated headers:
#check_include_file(GL/gl.h HAVE_GL_GL_H)
#check_include_file(GL/glu.h HAVE_GL_GLU_H)
#check_include_file(GL/glut.h HAVE_GL_GLUT_H)
#check_include_file(GLUT/glut.h HAVE_GLUT_GLUT_H)
#check_include_file(OpenGL/gl.h HAVE_OPENGL_GL_H)
#check_include_file(OpenGL/glu.h HAVE_OPENGL_GLU_H)

# Win32 IO
set(win32_io FALSE)
if(WIN32)
    set(win32_io TRUE)
endif()

set(USE_WIN32_FILEIO ${win32_io})


# Orthogonal features

# Strip chopping
option(TIFF_STRIP_CHOPPING "strip chopping (whether or not to convert single-strip uncompressed images to mutiple strips of specified size to reduce memory usage)" ON)
set(TIFF_DEFAULT_STRIP_SIZE 8192 CACHE STRING "default size of the strip in bytes (when strip chopping is enabled)")

set(STRIPCHOP_DEFAULT)
if(TIFF_STRIP_CHOPPING)
    set(STRIPCHOP_DEFAULT TRUE)
    if(TIFF_DEFAULT_STRIP_SIZE)
        set(STRIP_SIZE_DEFAULT "${TIFF_DEFAULT_STRIP_SIZE}")
    endif()
endif()

# Defer loading of strip/tile offsets
option(TIFF_DEFER_STRILE_LOAD "enable deferred strip/tile offset/size loading (also available at runtime with the 'D' flag of TIFFOpen())" OFF)
set(DEFER_STRILE_LOAD ${TIFF_DEFER_STRILE_LOAD})

# CHUNKY_STRIP_READ_SUPPORT
option(TIFF_CHUNKY_STRIP_READ "enable reading large strips in chunks for TIFFReadScanline() (experimental)" OFF)
set(CHUNKY_STRIP_READ_SUPPORT ${TIFF_CHUNKY_STRIP_READ})

# SUBIFD support
set(SUBIFD_SUPPORT 1)

# Default handling of ASSOCALPHA support.
option(TIFF_EXTRASAMPLE_AS_ALPHA "the RGBA interface will treat a fourth sample with no EXTRASAMPLE_ value as being ASSOCALPHA. Many packages produce RGBA files but don't mark the alpha properly" ON)
if(TIFF_EXTRASAMPLE_AS_ALPHA)
    set(DEFAULT_EXTRASAMPLE_AS_ALPHA 1)
endif()

# Default handling of YCbCr subsampling support.
# See Bug 168 in Bugzilla, and JPEGFixupTestSubsampling() for details.
option(TIFF_CHECK_YCBCR_SUBSAMPLING "enable picking up YCbCr subsampling info from the JPEG data stream to support files lacking the tag" ON)
if (TIFF_CHECK_YCBCR_SUBSAMPLING)
    set(CHECK_JPEG_YCBCR_SUBSAMPLING 1)
endif()

# Includes used by libtiff (and tests)
if(ZLIB_INCLUDE_DIRS)
    list(APPEND TIFF_INCLUDES ${ZLIB_INCLUDE_DIRS})
endif()
if(JPEG_INCLUDE_DIR)
    list(APPEND TIFF_INCLUDES ${JPEG_INCLUDE_DIR})
endif()
if(JPEG12_INCLUDE_DIR)
    list(APPEND TIFF_INCLUDES ${JPEG12_INCLUDE_DIR})
endif()
if(JBIG_INCLUDE_DIR)
    list(APPEND TIFF_INCLUDES ${JBIG_INCLUDE_DIR})
endif()
if(LIBLZMA_INCLUDE_DIRS)
    list(APPEND TIFF_INCLUDES ${LIBLZMA_INCLUDE_DIRS})
endif()
if(ZSTD_INCLUDE_DIR)
    list(APPEND TIFF_INCLUDES ${ZSTD_INCLUDE_DIR})
endif()
if(WEBP_INCLUDE_DIR)
    list(APPEND TIFF_INCLUDES ${WEBP_INCLUDE_DIR})
endif()

# Libraries required by libtiff
set(TIFF_LIBRARY_DEPS)
if(TIFF_MATH_SHARED AND M_LIBRARY)
    list(APPEND TIFF_LIBRARY_DEPS ${M_LIBRARY})
endif()
if(ZLIB_LIBRARIES)
    list(APPEND TIFF_LIBRARY_DEPS ${ZLIB_LIBRARIES})
endif()
if(JPEG_LIBRARIES)
    list(APPEND TIFF_LIBRARY_DEPS ${JPEG_LIBRARIES})
endif()
if(JPEG12_LIBRARIES)
    list(APPEND TIFF_LIBRARY_DEPS ${JPEG12_LIBRARIES})
endif()
if(JBIG_LIBRARIES)
    list(APPEND TIFF_LIBRARY_DEPS ${JBIG_LIBRARIES})
endif()
if(LIBLZMA_LIBRARIES)
    list(APPEND TIFF_LIBRARY_DEPS ${LIBLZMA_LIBRARIES})
endif()
if(ZSTD_LIBRARIES)
    list(APPEND TIFF_LIBRARY_DEPS ${ZSTD_LIBRARIES})
endif()
if(WEBP_LIBRARIES)
    list(APPEND TIFF_LIBRARY_DEPS ${WEBP_LIBRARIES})
endif()

if(FIPS_CMAKE_VERBOSE)
message(STATUS "")
message(STATUS "  libtiff build configuration:")
message(STATUS "")
message(STATUS "  Enable linker symbol versioning:    ${HAVE_LD_VERSION_SCRIPT}")
message(STATUS "  Support Microsoft Document Imaging: ${mdi}")
message(STATUS "  Use win32 IO:                       ${USE_WIN32_FILEIO}")
message(STATUS "")
message(STATUS " Support for internal codecs:")
message(STATUS "  CCITT Group 3 & 4 algorithms:       ${TIFF_CCITT}")
message(STATUS "  Macintosh PackBits algorithm:       ${TIFF_PACKBITS}")
message(STATUS "  LZW algorithm:                      ${TIFF_LZW}")
message(STATUS "  ThunderScan 4-bit RLE algorithm:    ${TIFF_THUNDER}")
message(STATUS "  NeXT 2-bit RLE algorithm:           ${TIFF_NEXT}")
message(STATUS "  LogLuv high dynamic range encoding: ${TIFF_LOGLUV}")
message(STATUS "")
message(STATUS " Support for external codecs:")
message(STATUS "  Use shared math library:            ${TIFF_MATH_SHARED} (requested) ${M_LIBRARY_FOUND} (availability)")
message(STATUS "  ZLIB support:                       ${TIFF_ZLIB} (requested) ${ZLIB_FOUND} (availability)")
message(STATUS "  Pixar log-format algorithm:         ${TIFF_PIXARLOG} (requested) ${PIXARLOG_SUPPORT} (availability)")
message(STATUS "  JPEG support:                       ${TIFF_JPEG} (requested) ${JPEG_FOUND} (availability)")
message(STATUS "  Old JPEG support:                   ${TIFF_OLD_JPEG} (requested) ${JPEG_FOUND} (availability)")
message(STATUS "  JPEG 8/12 bit dual mode:            ${TIFF_JPEG12} (requested) ${JPEG12_FOUND} (availability)")
message(STATUS "  ISO JBIG support:                   ${TIFF_JBIG} (requested) ${JBIG_FOUND} (availability)")
message(STATUS "  LZMA2 support:                      ${TIFF_LZMA} (requested) ${LIBLZMA_FOUND} (availability)")
message(STATUS "  ZSTD support:                       ${TIFF_ZSTD} (requested) ${ZSTD_FOUND} (availability)")
message(STATUS "  WEBP support:                       ${TIFF_WEBP} (requested) ${WEBP_FOUND} (availability)")
message(STATUS "")
message(STATUS "  C++ support:                        ${TIFF_CXX} (requested) ${CXX_SUPPORT} (availability)")
message(STATUS "")
message(STATUS "  OpenGL support:                     ${HAVE_OPENGL}")
message(STATUS "")
endif()