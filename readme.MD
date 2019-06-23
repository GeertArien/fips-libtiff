# fips-libtiff

fipsified libtiff (https://gitlab.com/libtiff/libtiff)

fips build system: https://github.com/floooh/fips

## External Codecs

All external codecs are currently disabled, except for zlib.

#### Zlib

Enable the fips option `TIFF_ZLIB`

It's the responsibility of the importing project to include the headers
and link against the zlib library (https://github.com/GeertArien/fips-zlib).

## Cross Compilation

The libtiff cmake file uses the cmake function `check_type_size` to dynamically determine the
size of builtin data types. This however can cause problems during cross compilation. 
For emscripten builds this was circumvented by defining the sizes statically.
IOS and android builds are not yet tested and might be broken.

Alternative solutions:
* Using C99 `<stdint.h>` (requires making changes to the libtiff configuration script)
* Manually populate CMake `TryRunResults.cmake` files
* Setting the `CMAKE_CROSSCOMPILING_EMULATOR` variable