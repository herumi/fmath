PYTHON?=python3
INC_DIR= -I../src  -I./include -I./test
CFLAGS += $(INC_DIR) -O2 -DNDEBUG -std=c++20 -mfma
CFLAGS_WARN=-Wall -Wextra -Wformat=2 -Wcast-qual -Wcast-align -Wwrite-strings -Wfloat-equal -Wpointer-arith
CFLAGS+=$(CFLAGS_WARN)
LDFLAGS=-L lib -lfmath
VPATH=test src

SRC=exp_v.cpp log_v.cpp

HEADER= fmath.hpp
LIB=lib/libfmath.a

TARGET=$(LIB)
all:$(TARGET)

.SUFFIXES: .cpp

$(LIB): obj/fmath.o obj/cpu.o
	$(AR) $(ARFLAGS) $@ $^

obj/fmath.o: src/fmath.S
	$(CC) -c $< -o $@

#src/s_xbyak.py:
#	curl https://raw.githubusercontent.com/herumi/s_xbyak/main/s_xbyak.py > $@

src/fmath.S: src/gen_fmath.py src/s_xbyak.py
	$(PYTHON) $< -m gas > $@

src/fmath.asm: src/gen_fmath.py src/s_xbyak.py
	$(PYTHON) $< -m masm > $@

LOG_L?=3
test/table.h: src/gen_fmath.py
	$(PYTHON) $< -t $(LOG_L) > $@

update:
	$(MAKE) src/fmath.S src/fmath.asm

obj/%.o: %.cpp include/fmath.h test/table.h
	$(CXX) -c -o $@ $< $(CFLAGS) -MMD -MP -MF $(@:.o=.d)

obj/cpu.o: cpu.cpp include/fmath.h
	$(CXX) -c -o $@ $< $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -fno-exceptions -fno-rtti -fno-threadsafe-statics #-fvisibility=hidden

bin/%.exe: obj/%.o $(LIB)
	$(CXX) -o $@ $< $(LDFLAGS)

bench: bench.o
	$(CXX) -o $@ $<

fastexp: fastexp.o
	$(CXX) -o $@ $<

avx2: avx2.cpp fmath.hpp
	$(CXX) -o $@ $< -O3 -mavx2 -mtune=native -Iinclude

EXP_UN?=4
exp_unroll_n: obj/exp_v.o
	@$(PYTHON) src/gen_fmath.py -m gas -exp_un $(EXP_UN) > src/fmath$(EXP_UN).S
	@$(CXX) -o bin/exp_v$(EXP_UN).exe obj/exp_v.o src/fmath$(EXP_UN).S $(CFLAGS) -I ../include
	@bin/exp_v$(EXP_UN).exe b
	@bin/exp_v$(EXP_UN).exe b
	@bin/exp_v$(EXP_UN).exe b
	@bin/exp_v$(EXP_UN).exe b
	@bin/exp_v$(EXP_UN).exe b
	@bin/exp_v$(EXP_UN).exe b
	@bin/exp_v$(EXP_UN).exe b
	@bin/exp_v$(EXP_UN).exe b
	@bin/exp_v$(EXP_UN).exe b
	@bin/exp_v$(EXP_UN).exe b

exp_unroll: obj/exp_v.o
	@sh -ec 'for i in 1 2 3 4 5 6 7 8; do echo EXP_UN=$$i; make -s exp_unroll_n EXP_UN=$$i; done'

LOG_MODE?=allreg
LOG_UN?=4
log_unroll_n: obj/log_v.o
	@$(PYTHON) src/gen_fmath.py -m gas -log_un $(LOG_UN) -log_mode $(LOG_MODE) > src/fmath$(LOG_UN).S
	@$(CXX) -o bin/log_v$(LOG_UN).exe obj/log_v.o src/fmath$(LOG_UN).S $(CFLAGS) -I ../include
	@bin/log_v$(LOG_UN).exe b
	@bin/log_v$(LOG_UN).exe b
	@bin/log_v$(LOG_UN).exe b
	@bin/log_v$(LOG_UN).exe b
	@bin/log_v$(LOG_UN).exe b
	@bin/log_v$(LOG_UN).exe b
	@bin/log_v$(LOG_UN).exe b
	@bin/log_v$(LOG_UN).exe b
	@bin/log_v$(LOG_UN).exe b
	@bin/log_v$(LOG_UN).exe b

log_unroll: obj/log_v.o
	@sh -ec 'for i in 1 2 3 4 5; do echo LOG_UN=$$i; make -s log_unroll_n LOG_UN=$$i; done'

clean:
	$(RM) obj/*.o obj/*.d $(TARGET) bin/*.exe src/*.S

test: bin/exp_v.exe bin/log_v.exe
	bin/exp_v.exe
	bin/log_v.exe

bench.o: bench.cpp $(HEADER)
fastexp.o: fastexp.cpp $(HEADER)

.PHONY: test clean

# don't remove these files automatically
.SECONDARY: $(addprefix obj/, $(ALL_SRC:.cpp=.o))
