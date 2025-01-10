@echo off
python3 src/gen_fmath.py -m masm > src/fmath.asm
ml64 /nologo /Zd /Zi /c /Foobj/fmath.obj src/fmath.asm
cl -I include /std:c++20 /arch:AVX2 /O2 /EHsc /W4 /DNDEBUG /D_CRT_SECURE_NO_WARNINGS /c src/cpu.cpp /Foobj/cpu.obj
lib /nologo /OUT:lib/fmath.lib /nodefaultlib obj/fmath.obj obj/cpu.obj