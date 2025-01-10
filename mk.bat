@echo off
set SRC=%1
set EXE=%SRC:.cpp=.exe%
set EXE=%EXE:.c=.exe%
set EXE=%EXE:test\=bin\%
echo CCC %EXE%
set OPT=/nologo /EHsc -I include -I test /W4 /Oy /O2 /arch:AVX2 /std:c++20 /DNDEBUG /DNOMINMAX lib/fmath.lib
cl %OPT% %SRC% /Fe:%EXE%
