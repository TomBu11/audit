VERSIONS = NORMAL ACTION1 ACTION1_DATA_SOURCE ACTION1_CUSTOM_ATTRIBUTES

FLAGS_NORMAL=-DINPUT -DOUTPUT -DNORMAL
FLAGS_ACTION1=-DOUTPUT -DACTION1
FLAGS_ACTION1_DATA_SOURCE=-DDATA_SOURCE
FLAGS_ACTION1_CUSTOM_ATTRIBUTES=-DCUSTOM_ATTRIBUTES

RELEASE_VERSION_FILE := VERSION
DEV_BUILD_FILE := DEV_BUILD

DEV_BUILD := $(shell cat $(DEV_BUILD_FILE) 2>/dev/null || echo 0)
RELEASE_VERSION := $(shell cat $(RELEASE_VERSION_FILE) 2>/dev/null || echo "0.0.0")
VERSION ?= v$(RELEASE_VERSION)\#DEV$(DEV_BUILD)

dev: clean
	@echo $$(($(DEV_BUILD)+1)) > $(DEV_BUILD_FILE); \
	VERSION="v$(RELEASE_VERSION)#DEV$$(($(DEV_BUILD)+1))"; \
	echo "Dev build: $$VERSION"; \
	$(MAKE) build VERSION="$$VERSION"

release: clean
	@read -p "Enter new release version (current: v$(RELEASE_VERSION)): " VERSION; \
	echo $$VERSION > $(RELEASE_VERSION_FILE); \
	echo 0 > $(DEV_BUILD_FILE); \
	echo "Release build: v$$VERSION"; \
	$(MAKE) build VERSION="v$$VERSION"

build: $(VERSIONS:%=build/script/audit_%.ps1)
	@echo "\nBuilt as version: $(VERSION)"

version:
	@echo "Dev build: $(VERSION)"
	@echo "Release version: v$(RELEASE_VERSION)"

clean:
	rm -f build/script/audit_*.ps1

build/script/audit_%.ps1: src/audit.ps1.in
	@echo "\n$*"
	gpp \
		-U "//" "" "(" "," ")" "(" ")" "$$" "" \
		-M "//" "\n" " " " " "\n" "(" ")" \
		$(FLAGS_$*) \
		-DVERSION="$(VERSION)" \
		-DDATE="$(shell date +'%Y-%m-%d')" \
		-DTIME="$(shell date +'%H:%M:%S')" \
		src/audit.ps1.in > $@