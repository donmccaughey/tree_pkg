APP_SIGNING_ID ?= Developer ID Application: Donald McCaughey
INSTALLER_SIGNING_ID ?= Developer ID Installer: Donald McCaughey
NOTARIZATION_KEYCHAIN_PROFILE ?= Donald McCaughey
TMP ?= $(abspath tmp)

version := 2.0.1
revision := 1
archs := arm64 x86_64

rev := $(if $(patsubst 1,,$(revision)),-r$(revision),)
ver := $(version)$(rev)


.SECONDEXPANSION :


.PHONY : signed-package
signed-package : $(TMP)/tree-$(ver)-unnotarized.pkg


.PHONY : notarize
notarize : tree-$(ver).pkg


.PHONY : clean
clean : 
	-rm -f tree-*.pkg
	-rm -rf $(TMP)


.PHONY : check
check :
	test "$(shell lipo -archs $(TMP)/install/usr/local/bin/tree)" = "x86_64 arm64"
	test "$(shell ./tools/dylibs --no-sys-libs --count $(TMP)/install/usr/local/bin/tree) dylibs" = "0 dylibs"
	codesign --verify --strict $(TMP)/install/usr/local/bin/tree
	pkgutil --check-signature tree-$(ver).pkg
	spctl --assess --type install tree-$(ver).pkg
	xcrun stapler validate tree-$(ver).pkg


##### compilation flags ##########

arch_flags = $(patsubst %,-arch %,$(archs))

CFLAGS += $(arch_flags)
LDFLAGS += $(arch_flags)


##### dist ##########

src_dist_files := $(shell find dist -type f \! -name .DS_Store)
src_dist_dirs := $(shell find dist -type d)

dist_files := $(patsubst dist/%, $(TMP)/dist/%, $(src_dist_files))
dist_dirs := $(patsubst dist/%, $(TMP)/dist/%, $(src_dist_dirs))

$(TMP)/install/usr/local/bin/tree \
$(TMP)/install/usr/local/share/man/man1/tree.1 : $(TMP)/installed.stamp.txt
	@:

$(TMP)/installed.stamp.txt : \
				$(TMP)/dist/tree \
				$(TMP)/dist/doc/tree.1 \
				| $(TMP)/install
	cd $(TMP)/dist && $(MAKE) DESTDIR=$(TMP)/install install
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$(TMP)/install/usr/local/bin/tree
	date > $@

$(TMP)/dist/tree : $(dist_files)
	cd $(TMP)/dist && $(MAKE) CFLAGS='$(CFLAGS)' LDFLAGS='$(LDFLAGS)'

$(dist_files) : $(TMP)/dist/% : dist/% | $$(dir $$@)
	cp $< $@

$(TMP)/dist \
$(TMP)/install \
$(dist_dirs) :
	mkdir -p $@


##### pkg ##########

$(TMP)/tree.pkg : $(TMP)/install/usr/local/bin/uninstall-tree
	pkgbuild \
		--root $(TMP)/install \
		--identifier cc.donm.pkg.tree \
		--ownership recommended \
		--version $(version) \
		$@

$(TMP)/install/etc/paths.d/tree.path : tree.path | $$(dir $$@)
	cp $< $@

$(TMP)/install/usr/local/bin/uninstall-tree : \
		uninstall-tree \
		$(TMP)/install/etc/paths.d/tree.path \
		$(TMP)/install/usr/local/bin/tree \
		$(TMP)/install/usr/local/share/man/man1/tree.1 \
		| $$(dir $$@)
	cp $< $@
	cd $(TMP)/install && find . -type f \! -name .DS_Store | sort >> $@
	sed -e 's/^\./rm -f /g' -i '' $@
	chmod a+x $@

$(TMP)/install/etc/paths.d \
$(TMP)/install/usr/local/bin :
	mkdir -p $@


##### product ##########

arch_list := $(shell printf '%s' "$(archs)" | sed "s/ / and /g")
date := $(shell date '+%Y-%m-%d')
macos:=$(shell \
	system_profiler -detailLevel mini SPSoftwareDataType \
	| grep 'System Version:' \
	| awk -F ' ' '{print $$4}' \
	)
xcode:=$(shell \
	system_profiler -detailLevel mini SPDeveloperToolsDataType \
	| grep 'Version:' \
	| awk -F ' ' '{print $$2}' \
	)

$(TMP)/tree-$(ver)-unnotarized.pkg : \
		$(TMP)/tree.pkg \
		$(TMP)/build-report.txt \
		$(TMP)/distribution.xml \
		$(TMP)/resources/background.png \
		$(TMP)/resources/background-darkAqua.png \
		$(TMP)/resources/license.html \
		$(TMP)/resources/welcome.html
	productbuild \
		--distribution $(TMP)/distribution.xml \
		--resources $(TMP)/resources \
		--package-path $(TMP) \
		--version v$(version)-r$(revision) \
		--sign '$(INSTALLER_SIGNING_ID)' \
		$@

$(TMP)/build-report.txt : | $$(dir $$@)
	printf 'Build Date: %s\n' "$(date)" > $@
	printf 'Software Version: %s\n' "$(version)" >> $@
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'Architectures: %s\n' "$(arch_list)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'APP_SIGNING_ID: %s\n' "$(APP_SIGNING_ID)" >> $@
	printf 'INSTALLER_SIGNING_ID: %s\n' "$(INSTALLER_SIGNING_ID)" >> $@
	printf 'NOTARIZATION_KEYCHAIN_PROFILE: %s\n' "$(NOTARIZATION_KEYCHAIN_PROFILE)" >> $@
	printf 'TMP directory: %s\n' "$(TMP)" >> $@
	printf 'CFLAGS: %s\n' "$(CFLAGS)" >> $@
	printf 'LDFLAGS: %s\n' "$(LDFLAGS)" >> $@
	printf 'Tag: v%s-r%s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Title: tree %s for macOS rev %s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Message: A signed and notarized universal installer package for `tree` %s.\n' "$(version)" >> $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed \
		-e 's/{{arch_list}}/$(arch_list)/g' \
		-e 's/{{date}}/$(date)/g' \
		-e 's/{{macos}}/$(macos)/g' \
		-e 's/{{revision}}/$(revision)/g' \
		-e 's/{{version}}/$(version)/g' \
		-e 's/{{xcode}}/$(xcode)/g' \
		$< > $@

$(TMP)/resources/background.png \
$(TMP)/resources/background-darkAqua.png \
$(TMP)/resources/license.html : $(TMP)/% : % | $$(dir $$@)
	cp $< $@

$(TMP) \
$(TMP)/resources : 
	mkdir -p $@


##### notarization #####

$(TMP)/submit-log.json : $(TMP)/tree-$(ver)-unnotarized.pkg | $$(dir $$@)
	xcrun notarytool submit $< \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		--output-format json \
		--wait \
		> $@

$(TMP)/submission-id.txt : $(TMP)/submit-log.json | $$(dir $$@)
	jq --raw-output '.id' < $< > $@

$(TMP)/notarization-log.json : $(TMP)/submission-id.txt | $$(dir $$@)
	xcrun notarytool log "$$(<$<)" \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		$@

$(TMP)/notarized.stamp.txt : $(TMP)/notarization-log.json | $$(dir $$@)
	test "$$(jq --raw-output '.status' < $<)" = "Accepted"
	date > $@

tree-$(ver).pkg : $(TMP)/tree-$(ver)-unnotarized.pkg $(TMP)/notarized.stamp.txt
	cp $< $@
	xcrun stapler staple $@

