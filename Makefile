GCC_VER=$(shell $(CXX) -dumpversion)
ifeq ($(shell expr $(GCC_VER) \>= 4.2),1)
    ADD_OPT+=-march=native
endif
ifeq ($(shell expr $(GCC_VER) \>= 4.5),1)
    ADD_OPT+=-fexcess-precision=fast
endif
AVX2=$(shell head -27 /proc/cpuinfo 2>/dev/null |awk '/avx2/ {print $$1}')
ifeq ($(AVX2),flags)
	HAS_AVX2=-mavx2
endif
PYTHON?=python3
# ----------------------------------------------------------------
INC_DIR= -I../src -I../xbyak -I./include
CFLAGS += $(INC_DIR) -O3 $(HAS_AVX2) $(ADD_OPT) -DNDEBUG
CFLAGS_WARN=-Wall -Wextra -Wformat=2 -Wcast-qual -Wcast-align -Wwrite-strings -Wfloat-equal -Wpointer-arith
CFLAGS+=$(CFLAGS_WARN)
ifeq ($(NEW),1)
  CFLAGS+=-DFMATH_NEW
endif
# ----------------------------------------------------------------

HEADER= fmath.hpp

TARGET=bench fastexp
all:$(TARGET)

.SUFFIXES: .cpp

bench: bench.o
	$(CXX) -o $@ $<

fastexp: fastexp.o
	$(CXX) -o $@ $<

avx2: avx2.cpp fmath.hpp
	$(CXX) -o $@ $< -O3 -mavx2 -mtune=native -Iinclude

exp_v: exp_v.cpp fmath2.hpp
	$(CXX) -o $@ $< -O3 -Iinclude -I../xbyak $(CFLAGS)
log_v: log_v.cpp fmath2.hpp
	$(CXX) -o $@ $< -O3 -Iinclude -I../xbyak $(CFLAGS)

new_exp_v: exp_v.o fmath.o
	$(CXX) -o $@ exp_v.o fmath.o

fmath.o: fmath.S
	$(CC) -c $< -o $@

fmath.S: gen_fmath.py
	$(PYTHON) gen_fmath.py -m gas > fmath.S

.cpp.o:
	$(CXX) -c $< -o $@ $(CFLAGS)

.c.o:
	$(CXX) -c $< -o $@ $(CFLAGS)

clean:
	$(RM) *.o $(TARGET) exp_v log_v

test: exp_v
	./exp_v

bench.o: bench.cpp $(HEADER)
fastexp.o: fastexp.cpp $(HEADER)

