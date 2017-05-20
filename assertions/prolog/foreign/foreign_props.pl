/*  Part of Assertion Reader for SWI-Prolog

    Author:        Edison Mera Menendez
    E-mail:        efmera@gmail.com
    WWW:           https://github.com/edisonm/assertions
    Copyright (C): 2017, Process Design Center, Breda, The Netherlands.
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

:- module(foreign_props,
          [foreign/1,
           foreign/2,
           (native)/1,
           (native)/2,
           fimport/1,
           fimport/2,
           returns/2,
           parent/2,
           returns_state/1,
           memory_root/1,
           ptr/1,
           ptr/2,
           float_t/1,
           dict_t/2,
           dict_t/3,
           dict_join_t/4,
           dict_extend_t/4,
           join_dict_types/6,
           join_type_desc/5]).

:- use_module(library(assertions)).
:- use_module(library(metaprops)).
:- use_module(library(plprops)).
:- use_module(library(extend_args)).

:- global foreign/1.
foreign(G) :- call(G).

:- global foreign/2.
foreign(G, _) :- call(G).

:- global native(_, Name)
   # "This predicate is implemented in C ~w."-[Name].

native(Goal, _) :- call(Goal).

:- global declaration (native)/1
   # "This predicate is implemented in C with a pl_ prefix.".

native(X) :- native(X, X).

:- prop fimport/1.
:- meta_predicate fimport(0).
fimport(G) :- call(G).

:- prop fimport/2.
:- meta_predicate fimport(0,?).
fimport(G, _) :- call(G).

:- prop returns/2.
:- meta_predicate returns(0,?).
returns(G,_) :- call(G).

:- prop parent/2.
:- meta_predicate parent(0,?).
parent(G,_) :- call(G).

:- prop returns_state/1.
:- meta_predicate returns_state(0).
returns_state(G) :- call(G).

:- prop memory_root/1.
:- meta_predicate memory_root(0).
memory_root(G) :- call(G).

:- type float_t/1 # "Defines a float".
float_t(Num) :- num(Num).

:- type ptr/1 # "Defines a void pointer".
ptr(Ptr) :- int(Ptr).

:- type ptr/2 # "Defines a typed pointer. Note that if the value was
    allocated dinamically by foreign_interface, it allows its usage as parent in
    FI_new_child_value/array in the C side to perform semi-automatic memory
    management".

:- meta_predicate ptr(?,1).
ptr(Ptr, Type) :-
    call(Type, Ptr).

prolog:called_by(dict_t(_, Desc), foreign_props, M, L) :-
    called_by_dict_t(Desc, M, L).
prolog:called_by(dict_t(_, _, Desc), foreign_props, M, L) :-
    called_by_dict_t(Desc, M, L).

called_by_dict_t(Desc, CM, L) :-
    nonvar(Desc),
    dict_create(Dict, _Tag, Desc),
    findall(M:P,
            ( MType=Dict._Key,
              strip_module(CM:MType, M, T),
              nonvar(T),
              add_1st_arg(T, _, P)
            ), L).

:- type dict_t/2.
:- meta_predicate dict_t(?, :).
dict_t(Term, Desc) :-
    dict_t(Term, _, Desc).

:- type dict_t/3.
:- meta_predicate dict_t(?, ?, :).
dict_t(Term, Tag, M:Desc) :-
    dict_mq(Desc, M, Tag, Dict),
    dict_pairs(Term, Tag, Pairs),
    maplist(dict_kv(Dict), Pairs).

:- type dict_join_t/4.
:- meta_predicate dict_join_t(?, ?, 1, 1).
dict_join_t(Term, Tag, M1:Type1, M2:Type2) :-
    join_dict_types(Type1, M1, Type2, M2, Tag, Dict),
    dict_pairs(Term, Tag, Pairs),
    maplist(dict_kv(Dict), Pairs).

:- type dict_extend_t/4.
:- meta_predicate dict_extend_t(?, 1, ?, +).
dict_extend_t(Term, M:Type, Tag, Desc) :-
    join_type_desc(Type, M, Tag, Desc, Dict),
    dict_pairs(Term, Tag, Pairs),
    maplist(dict_kv(Dict), Pairs).

join_type_desc(Type, M, Tag, Desc2, Dict) :-
    type_desc(M:Type, Desc1),
    join_dict_descs(M:Desc1, M:Desc2, Tag, Dict).

dict_mq(M:Desc, _, Tag, Dict) :- !,
    dict_mq(Desc, M, Tag, Dict).
dict_mq(Desc, M, Tag, Dict) :-
    dict_create(Dict, Tag, Desc),
    forall(Value=Dict.Key, nb_set_dict(Key, Dict, M:Value)).

dict_kv(Dict, Key-Value) :-
    Type=Dict.Key,
    call(Type, Value).

type_desc(MType, Desc) :-
    extend_args(MType, [_], MCall),
    clause(MCall, dict_t(_, _, Desc)).

join_dict_types(Type1, M1, Type2, M2, Tag, Dict) :-
    type_desc(M1:Type1, Desc1),
    type_desc(M2:Type2, Desc2),
    join_dict_descs(M1:Desc1, M2:Desc2, Tag, Dict).

join_dict_descs(M1:Desc1, M2:Desc2, Tag, Dict) :-
    dict_mq(Desc1, M1, Tag, Dict1),
    dict_mq(Desc2, M2, Tag, Dict2),
    Dict=Dict1.put(Dict2),
    assertion(Dict=Dict2.put(Dict1)).