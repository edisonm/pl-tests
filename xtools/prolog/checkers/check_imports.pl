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

:- module(check_imports, []).

:- use_module(checkers(checker)).
:- use_module(library(apply)).
:- use_module(library(clambda)).
:- use_module(library(expansion_module)).
:- use_module(library(implementation_module)).
:- use_module(library(extra_codewalk)).
:- use_module(library(extra_location)).
:- use_module(library(from_utils)).
:- use_module(library(location_utils)).

:- multifile
    prolog:message//1.

prolog:message(acheck(imports)) -->
    ['--------------',nl,
     'Unused Imports',nl,
     '--------------',nl,
     'The predicates or modules below has been imported, however they', nl,
     'are never used in the importing module, or they do not implement', nl,
     'new clauses for multifile predicates.  Note that modules that', nl,
     'export operators, or that do not export any predicate are not', nl,
     'reported.', nl,
     'You can silent the warnings by declaring use_module/2 with an',nl,
     'empty import list. If they have desirable side effects and still', nl,
     'needs to be imported, you can refactorize your program so that', nl,
     'such side effects are not required anymore.', nl, nl].
prolog:message(acheck(imports, c(Class, Type, Name)-LocElemL)) -->
    ['~w ~w have unused ~w:'-[Class, Name, Type], nl],
    foldl(unused_import(Type), LocElemL).

unused_import(Type, Loc/Elem) -->
    Loc,
    ['unused ~w ~w'-[Type, Elem], nl].

:- dynamic
    used_import/1,
    used_usemod/2.

checker:check(imports, Result, OptionL) :-
    check_imports(OptionL, Result).

check_imports(OptionL, Pairs) :-
    exwalkc_imports(M, FromChk, OptionL),
    collect_imports(M, FromChk, Pairs, Tail),
    collect_usemods(M, FromChk, Tail, []),
    cleanup_imports.

exwalkc_imports(M, FromChk, OptionL) :-
    extra_walk_code([source(false),
                     walkextras([declaration, asrparts([body, head])]),
                     on_etrace(collect_imports_wc)|OptionL], M, FromChk).

:- public collect_imports_wc/3.
collect_imports_wc(M:Goal, Caller, From) :-
    record_location_meta(M:Goal, _, From, all_call_refs, mark_import),
    ( nonvar(Caller),
      caller_module(Caller, From, MC),
      M \= MC,
      \+ used_usemod(M, MC)
    ->assertz(used_usemod(M, MC))
    ; true
    ).

caller_module(M:_,                _, M) :- !.
caller_module('<assertion>'(M:_), _, M) :- !.
caller_module(_, clause(Ptr), M) :- clause_property(Ptr, module(M)).

collect_imports(M, FromChk, Pairs, Tail) :-
    findall(warning-(c(use_module, import, U)-(Loc/(F/A))),
            current_unused_import(M, FromChk, U, Loc, F, A),
            Pairs, Tail).

current_unused_import(M, FromChk, U, Loc, F, A) :-
    clause(loc_declaration(Head, M, import(U), From), _, CRef),
    call(FromChk, From),
    M \= user,
    \+ memberchk(Head, [term_expansion(_,_),
                        term_expansion(_,_,_,_),
                        goal_expansion(_,_),
                        goal_expansion(_,_,_,_),
                        except(_)
                       ]),
    \+ used_import(CRef),
    \+ loc_declaration(Head, M, goal, _),
    module_property(M, class(Class)),
    memberchk(Class, [user]),
    functor(Head, F, A),
    from_location(From, Loc).

:- multifile ignore_import/2.

ignore_import(_, rtchecks_rt).
ignore_import(M, IM) :- expansion_module(M, IM).

collect_usemods(M, FromChk, Pairs, Tail) :-
    findall(warning-(c(module, use_module, M)-(Loc/U)),
            ( current_used_use_module(M, FromChk, U, From),
              from_location(From, Loc)
            ), Pairs, Tail).

current_used_use_module(M, FromChk, U, From) :-
    ( loc_declaration(U, M, use_module, From),
      ExL = []
    ; loc_declaration(use_module(U, except(ExL)), M, use_module_2, From)
    ),
    call(FromChk, From),
    M \= user,
    module_property(M, class(Class)),
    memberchk(Class, [user]),
    from_to_file(From, File),
    \+ findall(I, source_file_property(File, included_in(I, _)),
               [_, _|_]),
    absolute_file_name(U, UFile, [file_type(prolog), access(exist),
                                  file_errors(fail)]),
    current_module(UM, UFile),
    \+ ignore_import(M, UM),
    module_property(UM, exports(EL)),
    EL \= [],
    subtract(EL, ExL, PIL),
    \+ ( module_property(UM, exported_operators(OL)),
         OL \= []
       ),
    \+ ( member(F/A, PIL),
         functor(Head, F, A),
         implementation_module(UM:Head, IM),
         ( used_usemod(M, IM)                        % is used
         ; predicate_property(UM:Head, multifile),   % is extended
           clause(UM:Head, _, Ref),
           clause_property(Ref, file(File))
         )
       ).

mark_import(M:Head, CM, _, _, _, _) :-
    nonvar(M),
    callable(Head),
    mark_import(Head, M, CM).

mark_import(Head, M, CM) :-
    forall(( clause(loc_declaration(Head, CM, import(_), _), _, CRef),
             \+ used_import(CRef)),
           assertz(used_import(CRef))),
    ( M \= CM,
      \+used_usemod(CM, M)
    ->assertz(used_usemod(CM, M))
    ; true
    ).

cleanup_imports :-
    retractall(used_import(_)),
    retractall(used_usemod(_, _)).