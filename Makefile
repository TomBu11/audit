VERSIONS = NORMAL ACTION1 ACTION1_DATA_SOURCE ACTION1_CUSTOM_ATTRIBUTES

FLAGS_NORMAL=-DINPUT -DOUTPUT -DNORMAL
FLAGS_ACTION1=-DOUTPUT -DACTION1
FLAGS_ACTION1_DATA_SOURCE=-DDATA_SOURCE
FLAGS_ACTION1_CUSTOM_ATTRIBUTES=-DCUSTOM_ATTRIBUTES

RELEASE_VERSION_FILE := VERSION
DEV_BUILD_FILE := DEV_BUILD

VERSION := $(shell cat $(RELEASE_VERSION_FILE) 2>/dev/null || echo "0.0.0")
DEV_BUILD := $(shell cat $(DEV_BUILD_FILE) 2>/dev/null || echo 0)

dev:
	@echo $$(($(DEV_BUILD)+1)) > $(DEV_BUILD_FILE)
	@echo "Dev build: v$(VERSION)#DEV$$(cat $(DEV_BUILD_FILE))"
	$(MAKE) build VERSION="$(VERSION)#DEV$$(cat $(DEV_BUILD_FILE))"

release:
	@read -p "Enter new release version (current: $(VERSION)): " newver; \
	echo $$newver > $(RELEASE_VERSION_FILE); \
	echo 0 > $(DEV_BUILD_FILE); \
	git tag v$$newver; \
	git push --tags; \
	echo "Release build: v$$newver"
	$(MAKE) build VERSION="$$newver"

build: $(VERSIONS:%=build/script/audit_%.ps1)
	@echo "Built as version: v$(VERSION)"

version:
	@echo "Dev build: v$(VERSION)#DEV$(DEV_BUILD)"
	@echo "Release version: v$(VERSION)"

clean:
	rm -f build/script/audit_*.ps1

build/script/audit_%.ps1: src/audit.ps1.in
	@echo "\n$*"
	gpp \
		-U "//" "" "(" "," ")" "(" ")" "$$" "" \
		-M "//" "\n" " " " " "\n" "(" ")" \
		$(FLAGS_$*) \
		-DVERSION="v$(VERSION)" \
		-DDATE="$(shell date +'%Y-%m-%d')" \
		-DTIME="$(shell date +'%H:%M:%S')" \
		src/audit.ps1.in > $@