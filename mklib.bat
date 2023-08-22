@echo off
python3 src/gen_fmath.py -m masm > src/fmath.asm
ml64 /nologo /Zd /Zi /c /Foobj/fmath.obj src/fmath.asm
lib /nologo /OUT:lib/fmath.lib /nodefaultlib obj/fmath.obj