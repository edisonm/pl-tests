#!/bin/bash

set -e

PACKS="assertions rtchecks refactor xlibrary xtools"

forallpacks () {
    for pack in $PACKS; do
	echo "Note: On pack $pack"
	( cd $pack ; $* )
    done
}

if [ "$#" == "2" ] ; then
    to_load=`find . -name $2.plt`
    extra_opt=" -g assertz(package(xtools)) -g assertz(package(`echo $to_load|sed -e 's:\/: :g'|awk '{print $2}'`)),[plsdirs,library(assertions),library(checkers)]"
    run_tests="run_tests($2)"
elif [ "$#" == "3" ] ; then
    to_load=`find . -name $2.plt`
    extra_opt=" -g assertz(package(xtools)) -g assertz(package(`echo $to_load|sed -e 's:\/: :g'|awk '{print $2}'`)),[plsdirs,library(assertions),library(checkers)]"
    run_tests="run_tests($2:$3)"
else
    to_load="autotester.pl"
    run_tests="run_tests"
fi

case $1 in
    patches)
	forallpacks git format-patch origin
	find . -name "*.patch"|tar -cvzf patches.tgz -T -
	find . -name "*.patch" -delete
	;;
    push)
        git push
        for i in `git subrepo status -q` ; do
            git subrepo push $i
        done
        git push
        ;;
    pull)
        git pull
        for i in `git subrepo status -q` ; do
            git subrepo pull $i
        done
        ;;
    tests)
	swipl -tty $extra_opt -g "['$to_load'],time($run_tests)" -t halt
	;;
    testrtc)
	swipl -tty $extra_opt -g "['$to_load'],time(trace_rtc($run_tests))" -t halt
	;;
    cover)
        swipl -tty $extra_opt \
              -g "['$to_load'],[library(gcover_unit),library(ws_cover)],browse_server(5000),time((cov_${run_tests},cache_file_lines)),www_open_url('http://localhost:5000')"
	;;
    check)
	if [ "$#" == "2" ] ; then
	    swipl -tty -q -s loadall.pl -g "time(showcheck($2,[dir(pltool(prolog))]))"
	else
	    swipl -tty -q -s loadall.pl -g 'time(checkall([dir(pltool(prolog))]))'
	fi
	;;
    checkload)
        if [ "$#" == "2" ] ; then
            swipl -tty -q -s plsconfig.pl -g "assertz(package($2)),[checkload],halt"
        else
            for i in `find . -name pack.pl`; do
                pack=`basename ${i%/pack.pl}`
                echo "checking stand alone load of $pack"
                swipl -q -s plsconfig.pl -g "assertz(package($pack)),[checkload],halt"
            done
        fi
        ;;
    doc)
        swipl -s plsdoc.pl
        ;;
    checkh)
        swipl -q -s loadall.pl -g "forall(available_checker(C),(write('% '),write(C),write(':'),print_message(information, acheck(C)))),halt." 2>&1 |sed -e s:'^% '::g
        ;;
    checkc)
	if [ "$#" == "2" ] ; then
	    swipl -q -s loadall.pl -g "showcheck($2,[dir(pltool(prolog))])"
	else
	    swipl -q -s loadall.pl -g 'checkallc([dir(pltool(prolog))])'
	fi
	;;
    loadall)
	swipl -q -s loadall.pl
	;;
    build)
	echo -e "qsave_program(plsteroids,[]).\nhalt.\n" | \
	    swipl -q -s loadall.pl
	;;
    *)
	forallpacks $*
	;;
esac
