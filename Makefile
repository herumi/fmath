GCC_VER=$(shell gcc -dumpversion)
ifeq ($(shell expr $(GCC_VER) \>= 4.2),1)
    ADD_OPT+=-mtune=native
endif
ifeq ($(shell expr $(GCC_VER) \>= 4.5),1)
    ADD_OPT+=-fexcess-precision=fast
endif
# ----------------------------------------------------------------
INC_DIR= -I../src -I../xbyak
# -ffast-math option may generate bad code for fmath::expd
CFLAGS += $(INC_DIR) -O3 -fomit-frame-pointer -D_FILE_OFFSET_BITS=64 -DNDEBUG -fno-operator-names -msse2 -mfpmath=sse $(ADD_OPT)
CFLAGS_WARN=-Wall -Wextra -Wformat=2 -Wcast-qual -Wcast-align -Wwrite-strings -Wfloat-equal -Wpointer-arith
CFLAGS+=$(CFLAGS_WARN)
LD=g++
# ----------------------------------------------------------------

HEADER= fmath.hpp

TARGET=bench fastexp
all:$(TARGET)

.SUFFIXES: .cpp

bench: bench.o
	$(LD) -o $@ $<

fastexp: fastexp.o
	$(LD) -o $@ $<

.cpp.o:
	$(CXX) -c $< -o $@ $(CFLAGS)

.c.o:
	$(CXX) -c $< -o $@ $(CFLAGS)

clean:
	$(RM) *.o $(TARGET)

bench.o: bench.cpp $(HEADER)

