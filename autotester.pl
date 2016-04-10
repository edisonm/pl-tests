:- module(autotester, [cover_tests/0]).

:- [assertions/tests/'assertions.plt'].
:- [assertions/tests/foreign/'foreign.plt'].
:- [refactor/tests/'gcb.plt'].
:- [refactor/tests/'refactor.plt'].
:- [rtchecks/tests/'rtchecks.plt'].
:- [xlibrary/tests/i18n/'i18n_2.plt'].
:- [xlibrary/tests/i18n/'i18n.plt'].
:- [xtools/tests/'assrt_meta.plt'].
:- [xtools/tests/'ctchecks.plt'].
:- [library(gcover)].
:- [library(ws_cover)].

cover_tests :-
    working_directory(W,W),
    gcover(run_tests, [file(directory_file_path(W,_))]).
