APP_SIGNING_ID ?= Developer ID Application: Donald McCaughey
TMP ?= $(abspath tmp)

version := 1.8.0
revision := 1
archs := arm64 x86_64


.SECONDEXPANSION :


.PHONY : all
all : tree-$(version).pkg


.PHONY : clean
clean : 
	-rm -f tree-*.pkg
	-rm -rf $(TMP)


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
	date > $@

$(TMP)/dist/tree : $(dist_files)
	cd $(TMP)/dist && $(MAKE) CFLAGS='$(CFLAGS)' LDFLAGS='$(LDFLAGS)'

$(dist_files) : $(TMP)/dist/% : dist/% | $$(dir $$@)
	cp $< $@

$(TMP)/dist \
$(TMP)/install \
$(dist_dirs) :
	mkdir -p $@

# sign executable

$(TMP)/signed.stamp.txt : $(TMP)/install/usr/local/bin/tree | $$(dir $$@)
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$<
	date > $@


##### pkg ##########

$(TMP)/tree.pkg : \
		$(TMP)/install/etc/paths.d/tree.path \
		$(TMP)/install/usr/local/bin/tree \
		$(TMP)/install/usr/local/bin/uninstall-tree \
		$(TMP)/install/usr/local/share/man/man1/tree.1 \
		$(TMP)/signed.stamp.txt
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
		$(TMP)/installed.stamp.txt \
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

tree-$(version).pkg : \
		$(TMP)/tree.pkg \
		$(TMP)/build-report.txt \
		$(TMP)/distribution.xml \
		$(TMP)/resources/background.png \
		$(TMP)/resources/license.html \
		$(TMP)/resources/welcome.html
	productbuild \
		--distribution $(TMP)/distribution.xml \
		--resources $(TMP)/resources \
		--package-path $(TMP) \
		--version v$(version)-r$(revision) \
		--sign 'Donald McCaughey' \
		$@

$(TMP)/build-report.txt : | $$(dir $$@)
	printf 'Build Date: %s\n' "$(date)" > $@
	printf 'Software Version: %s\n' "$(version)" >> $@
	printf 'Architectures: %s\n' "$(arch_list)" >> $@
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'Tag Version: v%s-r%s\n' "$(version)" "$(revision)" >> $@
	printf 'Release Title: tree %s for macOS rev %s\n' "$(version)" "$(revision)" >> $@
	printf 'Description: A signed macOS installer package for `tree` %s.\n' "$(version)" >> $@

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
$(TMP)/resources/license.html : $(TMP)/% : % | $$(dir $$@)
	cp $< $@

$(TMP) \
$(TMP)/resources : 
	mkdir -p $@

