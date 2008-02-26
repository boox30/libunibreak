# Windows/Cygwin support
ifdef windir
    WINDOWS := 1
    CYGWIN  := 0
else
    ifdef WINDIR
        WINDOWS := 1
        CYGWIN  := 1
    else
        WINDOWS := 0
    endif
endif
ifeq ($(WINDOWS),1)
    EXEEXT := .exe
    DLLEXT := .dll
    DEVNUL := nul
    ifeq ($(CYGWIN),1)
        PATHSEP := /
    else
        PATHSEP := $(strip \ )
    endif
else
    EXEEXT :=
    DLLEXT := .so
    DEVNUL := /dev/null
    PATHSEP := /
endif

CFG ?= Debug
ifeq ($(CFG),Debug)
    all: debug
else
    all: release
endif

DEBUG   := DebugDir
RELEASE := ReleaseDir

$(DEBUG)/%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(DBGFLAGS) $(TARGET_ARCH) -c -o $@ $<

$(RELEASE)/%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(RELFLAGS) $(TARGET_ARCH) -c -o $@ $<

$(DEBUG)/%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(DBGFLAGS) $(TARGET_ARCH) -c -o $@ $<

$(RELEASE)/%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(RELFLAGS) $(TARGET_ARCH) -c -o $@ $<

$(DEBUG)/%.dep: %.c
	$(CC) -MM -MT $(patsubst %.dep,%.o,$@) $(CFLAGS) $(CPPFLAGS) $(DBGFLAGS) $(TARGET_ARCH) -o $@ $<

$(RELEASE)/%.dep: %.c
	$(CC) -MM -MT $(patsubst %.dep,%.o,$@) $(CFLAGS) $(CPPFLAGS) $(RELFLAGS) $(TARGET_ARCH) -o $@ $<

$(DEBUG)/%.dep: %.cpp
	$(CXX) -MM -MT $(patsubst %.dep,%.o,$@) $(CXXFLAGS) $(CPPFLAGS) $(DBGFLAGS) $(TARGET_ARCH) -o $@ $<

$(RELEASE)/%.dep: %.cpp
	$(CXX) -MM -MT $(patsubst %.dep,%.o,$@) $(CXXFLAGS) $(CPPFLAGS) $(RELFLAGS) $(TARGET_ARCH) -o $@ $<

CC  = gcc
CXX = g++
AR  = ar
LD  = $(CXX) $(CXXFLAGS) $(TARGET_ARCH)

INCLUDE  = -I. $(patsubst %,-I%,$(VPATH))
CFLAGS   = -W -Wall -fmessage-length=0 $(INCLUDE)
CXXFLAGS = $(CFLAGS)
DBGFLAGS = -D_DEBUG -g
RELFLAGS = -DNDEBUG -O2
CPPFLAGS =

HFILES   = $(wildcard $(patsubst -I%,%/*.h,$(INCLUDE)))
OBJFILES = $(CFILES:.c=.o) $(CXXFILES:.cpp=.o)

DEBUG_OBJS   = $(patsubst %.o,$(DEBUG)/%.o,$(OBJFILES))
RELEASE_OBJS = $(patsubst %.o,$(RELEASE)/%.o,$(OBJFILES))

DEBUG_DEPS   = $(patsubst %.o,%.dep,$(DEBUG_OBJS))
RELEASE_DEPS = $(patsubst %.o,%.dep,$(RELEASE_OBJS))

CFILES   := linebreak.c
CXXFILES :=

LIBS :=

TARGET         = liblinebreak.a
DEBUG_TARGET   = $(patsubst %,$(DEBUG)/%,$(TARGET))
RELEASE_TARGET = $(patsubst %,$(RELEASE)/%,$(TARGET))

debug:   $(DEBUG) $(DEBUG_TARGET)

release: $(RELEASE) $(RELEASE_TARGET)



$(DEBUG):
	mkdir $(DEBUG)

$(RELEASE):
	mkdir $(RELEASE)

$(DEBUG_TARGET): $(DEBUG_DEPS) $(DEBUG_OBJS)
	$(AR) -r $(DEBUG_TARGET) $(DEBUG_OBJS)

$(RELEASE_TARGET): $(RELEASE_DEPS) $(RELEASE_OBJS)
	$(AR) -r $(RELEASE_TARGET) $(RELEASE_OBJS)

linebreakdata: filter_dup$(EXEEXT) LineBreak.txt
	sed -n -f LineBreak1.sed LineBreak.txt > tmp.txt
	sed -f LineBreak2.sed tmp.txt | .$(PATHSEP)filter_dup > tmp.c
	head -2 LineBreak.txt > tmp.txt
	cat linebreakdata1.tmpl tmp.txt linebreakdata2.tmpl tmp.c linebreakdata3.tmpl > linebreakdata.c
	$(RM) tmp.txt tmp.c

filter_dup$(EXEEXT): filter_dup.c
	gcc -O2 -o filter_dup$(EXEEXT) $<

LineBreak.txt:
	wget http://unicode.org/Public/UNIDATA/LineBreak.txt

.PHONY: all debug release clean distclean linebreakdata

clean:
	$(RM) $(DEBUG)/*.o $(DEBUG)/*.dep $(DEBUG_TARGET) *.exe tags
	$(RM) $(RELEASE)/*.o $(RELEASE)/*.dep $(RELEASE_TARGET)

distclean: clean
	$(RM) $(DEBUG)/* $(RELEASE)/* LineBreak.txt
	-rmdir $(DEBUG) 2> $(DEVNUL)
	-rmdir $(RELEASE) 2> $(DEVNUL)

-include $(wildcard $(DEBUG)/*.dep) $(wildcard $(RELEASE)/*.dep)