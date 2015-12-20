TMP ?= $(abspath tmp)

version := 1.7.0
installer_version := 1

.SECONDEXPANSION :


.PHONY : all
all : tree-$(version).pkg


.PHONY : clean
clean : 
	-rm -f tree-$(version).pkg
	-rm -rf $(TMP)


##### dist ##########
src_dist_files := $(shell find dist -type f \! -name .DS_Store)
src_dist_dirs := $(shell find dist -type d)

dist_files := $(patsubst dist/%, $(TMP)/dist/%, $(src_dist_files))
dist_dirs := $(patsubst dist/%, $(TMP)/dist/%, $(src_dist_dirs))


$(TMP)/install/usr/local/bin/tree \
$(TMP)/install/user/local/share/man/man1/tree.1 : $(TMP)/installed.stamp.txt
	@:

$(TMP)/installed.stamp.txt : \
				$(TMP)/dist/tree \
				$(TMP)/dist/doc/tree.1 \
				| $(TMP)/install
	cd $(TMP)/dist && $(MAKE) DESTDIR=$(TMP)/install install
	date > $@

$(TMP)/dist/tree : $(dist_files)
	cd $(TMP)/dist && $(MAKE)

$(dist_files) : $(TMP)/dist/% : dist/% | $$(dir $$@)
	cp $< $@

$(TMP)/dist \
$(TMP)/install \
$(dist_dirs) :
	mkdir -p $@


##### pkg ##########

$(TMP)/tree-$(version).pkg : \
		$(TMP)/install/usr/local/bin/tree \
		$(TMP)/install/usr/local/share/man/man1/tree.1 \
		$(TMP)/install/etc/paths.d/tree.path
	pkgbuild \
		--root $(TMP)/install \
		--identifier com.ablepear.tree \
		--ownership recommended \
		--version $(version) \
		$@

$(TMP)/install/etc/paths.d/tree.path : tree.path | $(TMP)/install/etc/paths.d
	cp $< $@

$(TMP)/install/etc/paths.d :
	mkdir -p $@


##### product ##########

tree-$(version).pkg : \
		$(TMP)/tree-$(version).pkg \
		$(TMP)/distribution.xml \
		$(TMP)/resources/background.png \
		$(TMP)/resources/license.html \
		$(TMP)/resources/welcome.html
	productbuild \
		--distribution $(TMP)/distribution.xml \
		--resources $(TMP)/resources \
		--package-path $(TMP) \
		--version $(installer_version) \
		-sign 'Able Pear Software Incorporated' \
		$@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed -e s/{{version}}/$(version)/g $< > $@

$(TMP)/resources/background.png \
$(TMP)/resources/license.html : $(TMP)/% : % | $(TMP)/resources
	cp $< $@

$(TMP) \
$(TMP)/resources : 
	mkdir -p $@


