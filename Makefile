
ifndef MSEGUI
MSEGUI := mseide-msegui
endif

ifeq ($(OS),Windows_NT)
OS := windows
else
OS := linux
endif

PC := fpc
PFLAGS := -Mobjfpc -Sh
PFLAGS += -Fu$(MSEGUI)/lib/common/*
PFLAGS += -Fu$(MSEGUI)/lib/common/kernel/$(OS)
PFLAGS += -CX -Xs -XX
ifdef RELEASE
PFLAGS += -dRELEASE
endif

#PROGRAM := $(notdir $(CURDIR))
PROGRAM := installmse

MAKEFLAGS += --no-print-directory

default: $(PROGRAM)

%: %.pas
	@$(PC) $(PFLAGS) $<

clean:
	@rm -fv *.bak *.bak? *.desktop *.o *.ppu *.sh *.sta

distclean: clean
	@rm -fv $(PROGRAM) $(PROGRAM).dbg $(PROGRAM).exe

test: $(PROGRAM)
	./$< --dir=/home/roland/Applications 2> $@.debug | tee $@.log
