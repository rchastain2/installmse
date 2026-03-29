
ifndef MSEGUI
MSEGUI := mseide-msegui
endif

ifeq ($(OS),Windows_NT)
OS := windows
else
OS := linux
endif

UNITS := units

PC := fpc
PFLAGS := -Mobjfpc -Sh
PFLAGS += -Fu$(MSEGUI)/lib/common/*
PFLAGS += -Fu$(MSEGUI)/lib/common/kernel/$(OS)
PFLAGS += -FU$(UNITS)

ifdef RELEASE
PFLAGS += -dRELEASE
endif

PROGRAM := installmse

default: $(PROGRAM)

%: %.pas $(MSEGUI) $(UNITS)
	@$(PC) $(PFLAGS) $<

$(MSEGUI):
	$(error Directory not found: $(MSEGUI))

$(UNITS):
	$(error Directory not found: $(UNITS))

clean:
	@rm -fv *.bak *.bak? *.cmd *.desktop *.sh *.sta

distclean: clean
	@rm -fv $(UNITS)/*.o $(UNITS)/*.ppu
	@rm -fv $(PROGRAM) $(PROGRAM).dbg $(PROGRAM).exe
