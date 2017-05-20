/*  Part of Extended Tools for SWI-Prolog

    Author:        Edison Mera Menendez
    E-mail:        efmera@gmail.com
    WWW:           https://github.com/edisonm/xtools
    Copyright (C): 2015, Process Design Center, Breda, The Netherlands.
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:

    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in
       the documentation and/or other materials provided with the
       distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/

:- module(checker,
          [showcheck/1, showcheck/2, checkall/0, checkall/1, checkallc/1,
          check_results/2, check_results/3, report_list/2, full_report/1,
          simple_report/1, available_checker/1]).

:- use_module(library(atomics_atom)).
:- use_module(library(thread)).
:- use_module(library(group_pairs_or_sort)).
:- use_module(library(infer_meta_if_required)).
:- use_module(library(location_utils)).
% This provides extra information to prolog_codewalk but will not be required if
% you use source_codewalk instead:
:- use_module(library(ai_extra_clauses), []).

user:file_search_path(checkers, library(checkers)).

:- multifile
    prepare_results/3,  % Custom preparation method
    check/3.            % Hook to define new analyses

:- public
    prepare_results/3,
    check/3.

prolog:called_by(Goal, _, M, [M:Macro]) :-
    functor(Goal, F, A),
    once(atomics_atom(['__aux_', Name, '/', AN, '_', CF, '+', EN], F)),
    atom_number(AN, N),
    atom_number(EN, E),
    A =:= E + N - 1,
    length(EL, E),
    Goal =.. [F|AL],
    append(EL, TL, AL),
    trim_args(Name, N, C, CF, EL, [C|TL], TT),
    Macro =.. [Name|TT].

% This is a kludge to bypass the fact that maplist/N, N>5 does not exist:
trim_args(maplist, N, C, CF, EL, AL, AT) :-
    N > 5, !,
    length(AT, 5),
    append(AT, AR, AL),
    length(AR, RN),
    length(ER, RN),
    append(ER, EL, CL),
    C =.. [CF|CL].
trim_args(_, _, C, CF, EL, AL, AL) :-
    C =.. [CF|EL].

/*
user:prolog_clause_name(Ref, Name) :-
    nth_clause(M:H, N, Ref), !,
    functor(H, F, A),
    Name = M:F/A-N.
user:prolog_clause_name(Ref, Name) :-
    clause_property(Ref, erased), !,
    clause_property(Ref, predicate(M:PI)),
    Name = erased(M:PI).
user:prolog_clause_name(_, '<meta-call>').
*/

cleanup_db :-
    cleanup_loc_dynamic(_, _, dynamic(_, _, _), _).

showcheck(Checker) :-
    showcheck(Checker, []),
    cleanup_db.

available_checker(Checker) :-
    clause(check(Checker, _, _), _).

showcheck(Checker, OptionL) :-
    check_results(Checker, Results, OptionL),
    full_report(Checker-Results).

full_report(Checker-Pairs) :-
    ( Pairs == []
    ->true
    ; print_message(warning, acheck(Checker)),
      simple_report(Checker-Pairs)
    ).

simple_report(Checker-Pairs) :-
    ( prepare_results(Checker, Pairs, Prepared)
    ->true
    ; Prepared = Pairs
    ),
    group_pairs_or_sort(Prepared, Results),
    maplist(report_analysis_results(Checker), Results).

report_analysis_results(Checker, Type-ResultL) :-
    maplist(report_record_message(Checker, Type), ResultL).

report_record_message(Checker, Type, Result) :-
    print_message(Type, acheck(Checker, Result)).

:- meta_predicate report_list(?,1).
report_list(Pairs, PrintMethod) :-
    keysort(Pairs, Sorted),
    group_pairs_by_key(Sorted, Results),
    maplist(PrintMethod, Results).

check_results(Checker, Result) :-
    check_results(Checker, Result, []).

checkall :-
    checkall([]).

infocheck(Checker, T) :-
    get_time(T),
    print_message(information, format('Running Checker ~w', [Checker])).

donecheck(Checker, T) :-
    get_time(T2),
    DT is T2-T,
    print_message(information, format('Done ~w (~3f s)', [Checker, DT])).

checkall(OptionL) :- checkall(maplist, OptionL).

checkallc(OptionL) :- checkall(concurrent_maplist, OptionL).

:- meta_predicate checkall(2, +).
checkall(Mapper, OptionL) :-
    findall(C, available_checker(C), CL),
    setup_call_cleanup(infer_meta_if_required,
                       call(Mapper, checkeach(OptionL), CL),
                       cleanup_db).

:- public checkeach/2.
checkeach(OptionL, Checker) :-
     infocheck(Checker, T),
     showcheck(Checker, OptionL),
     donecheck(Checker, T).

check_results(Checker, Results, OptionL) :-
    current_prolog_flag(check_database_preds, F),
    setup_call_cleanup(
        set_prolog_flag(check_database_preds, true),
        check(Checker, Results, OptionL),
        set_prolog_flag(check_database_preds, F)).