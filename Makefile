VERSIONS = NORMAL ACTION1 ACTION1_DATA_SOURCE ACTION1_CUSTOM_ATTRIBUTES

FLAGS_NORMAL=-DINPUT -DOUTPUT -DNORMAL
FLAGS_ACTION1=-DOUTPUT -DACTION1
FLAGS_ACTION1_DATA_SOURCE=-DDATA_SOURCE
FLAGS_ACTION1_CUSTOM_ATTRIBUTES=-DCUSTOM_ATTRIBUTES

all: $(VERSIONS:%=build/script/audit_%.ps1)

clean:
	rm -f build/script/audit_*.ps1

build/script/audit_%.ps1: src/audit.ps1.in
	@echo "\n$*"
	gpp \
		-U "//" "" "(" "," ")" "(" ")" "$$" "" \
		-M "//" "\n" " " " " "\n" "(" ")" \
		$(FLAGS_$*) \
		src/audit.ps1.in > $@
