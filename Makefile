# PACKS=assertions rtchecks refactor xlibrary xtools
SHELL=/bin/bash
MAKEFLAGS += --silent --no-print-directory
# JOBS?=$(shell nproc)

PLSTEROIDS=target/bin/plsteroids

CONCURRENT=. bin/concurrent ; concurrent_silent=1 ; run_pull

bid:
	cd idfpml/prolog/idfpml/LIBRARY ; \
	  $(MAKE) CC=gcc CALL_BY_REF=1 GLOBAL_RND=1 GLOBAL_FLAGS=1 UNCHANGED_BINARY_FLAGS=0

build: bid
	$(MAKE) $(PLSTEROIDS)

compile:
	for i in `find . -name pack.pl`; do \
	    pack=`basename $${i%/pack.pl}` ; \
	    find $${pack}/prolog -type d -exec mkdir -p target/lib/{} \; ; \
	    find $${pack}/prolog -type f -name "*.pl" -exec ln -sf `pwd`/{} target/lib/{} \; ; \
	done
	swipl -q -s qcompile.pl -t halt

bidclean:
	cd idfpml/prolog/idfpml/LIBRARY ; $(MAKE) clean

plclean:
	$(RM) -rf target assertions/tests/foreign/*{.o,.so,_so.pl,_impl.h,_intf.c,_intf.h} \
		idfpml/prolog/*{.o,.so,_so.pl,_impl.h,_intf.c,_intf.h,_auto.*}
	mkdir -p target/bin

clean: bidclean plclean

$(PLSTEROIDS):
	mkdir -p `dirname $@`
	echo -e "infer_meta:infer_meta_if_required.\nqsave_program('$@',[]).\nhalt.\n" | swipl -q -s loadall.pl

patches:
	forallpacks git format-patch origin
	find . -name "*.patch"|tar -cvzf patches.tgz -T -
	find . -name "*.patch" -delete

push:
	git push
	for i in `git subrepo status -q` ; do \
	  git subrepo push $${i} ; \
	done
	git push

pull:
	git pull
	for i in `git subrepo status -q` ; do \
	  git subrepo pull $${i} ; \
	done

noop:

%.plt: noop
	$(CONCURRENT) bin/run_utest '$@'

%.plr: noop
	$(CONCURRENT) bin/run_rtest '$@'


%.utest:
	$(MAKE) `find $* -name "*.plt"`

%.rtest:
	$(MAKE) $(shell for i in `find $* -name '*.plt'`; do echo $${i%.*}.plr; done)

CHECKERS=$(shell for i in `find . -name "check_*.pl"`; do echo `basename $${i%.*}`|sed -e s:check_::g ; done)

utests: $(shell find * -name "*.plt")
	true

rtests: $(shell for i in `find $* -name '*.plt'`; do echo $${i%.*}.plr; done)
	true

stests: $(addsuffix .stest,$(CHECKERS))
	true

%.stest: noop
	$(CONCURRENT) bin/run_stest '$@'

bin/benchtests.txt:
	for test in $(addsuffix .stest,$(CHECKERS)) $(shell find * -name "*.plt") ; do \
	  echo `if [ -f target/$$test.stderr ] ; then tail -n1 target/$$test.stderr | awk '{print $$2}' | sed -e s:','::g ; else echo 0 ; fi` $$test ; \
	  done | sort -n -r | awk '{print $$2}' > $@

dumpbench:
	for test in $(addsuffix .stest,$(CHECKERS)) $(shell find * -name "*.plt") ; do \
	  echo `if [ -f target/$$test.stderr ] ; then tail -n1 target/$$test.stderr | awk '{print $$2}' | sed -e s:','::g ; else echo 0 ; fi` $$test ; \
	  done | sort -n -r

tests: bin/benchtests.txt
	$(MAKE) `cat $<`
	$(MAKE) bin/benchtests.txt -B

get_plsteroids:
	echo $(PLSTEROIDS)

doc:
	swipl -s plsdoc.pl

packstrees:
	swipl -q -s ./plsteroids -g "[collect_deps,library(packs_trees),library(show_tree)],packs_trees(A),show_trees(A),halt"

%.modulestree:
	swipl -q -s ./plsteroids -g "[collect_deps,library(modules_trees),library(show_tree)],modules_trees([$*],A),show_trees(A),halt"

%.modrevstree:
	swipl -q -s ./plsteroids -g "[collect_deps,library(modules_trees),library(show_tree)],modrevs_trees([$*],A),show_trees(A),halt"
