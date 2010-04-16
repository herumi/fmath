# ----------------------------------------------------------------
INC_DIR= -I../src -I../xbyak
CFLAGS += $(INC_DIR) -O3 -fomit-frame-pointer -D_FILE_OFFSET_BITS=64 -DNDEBUG -fno-operator-names -msse2 -mfpmath=sse -ffast-math -march=core2
CFLAGS_WARN=-Wall -Wextra -Wformat=2 -Wcast-qual -Wcast-align -Wwrite-strings -Wfloat-equal -Wpointer-arith
CFLAGS+=$(CFLAGS_WARN)
LD=g++
# ----------------------------------------------------------------

HEADER= fmath.hpp

TARGET=bench
all:$(TARGET)

.SUFFIXES: .cpp

bench: bench.o
	$(LD) -o $@ bench.o

.cpp.o:
	$(CXX) -c $< -o $@ $(CFLAGS)

.c.o:
	$(CXX) -c $< -o $@ $(CFLAGS)

clean:
	$(RM) *.o $(TARGET)

bench.o: bench.cpp $(HEADER)

