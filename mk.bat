@echo off
set OPT=/EHsc -I include -I test /W4 /Oy /O2 /arch:AVX2 /DNDEBUG /DNOMINMAX lib/fmath.lib
cl %OPT% %1%
