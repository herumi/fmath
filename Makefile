PYTHON?=python3
INC_DIR= -I../src  -I./include -I./test
CFLAGS += $(INC_DIR) -O2 -DNDEBUG
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
	$(CXX) -c -o $@ $< $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -std=c++20 -mfma

obj/cpu.o: cpu.cpp include/fmath.h
	$(CXX) -c -o $@ $< $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -fno-exceptions -fno-rtti -fno-threadsafe-statics #-fvisibility=hidden

bin/%.exe: obj/%.o $(LIB)
	$(CXX) -o $@ $< $(LDFLAGS)

clean:
	$(RM) obj/*.o obj/*.d $(TARGET) bin/*.exe src/*.S

test: bin/exp_v.exe bin/log_v.exe
	bin/exp_v.exe
	bin/log_v.exe

.PHONY: test clean

# don't remove these files automatically
.SECONDARY: $(addprefix obj/, $(ALL_SRC:.cpp=.o))
