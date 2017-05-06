/*  Part of Assertion Reader for SWI-Prolog

    Author:        Edison Mera Menendez
    E-mail:        efmera@gmail.com
    WWW:           https://github.com/edisonm/assertions
    Copyright (C): 2015, Process Design Center, Breda, The Netherlands.

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/

:- module(assrt_interface, []).

:- use_module(library(assrt_lib), []).
:- use_module(library(interface), []).
:- use_module(library(context_values)).

% Propagate assertions in an interface to the implementation

assrt_lib:asr_head_prop(in_asr(IM, Head, Asr), IM, Head, Status, Type, Dict, Loc) :-
    head_prop_asr_intf(Head, IM, Status, Type, Dict, Loc, Asr).

head_prop_asr_intf(Head, IM, Status, Type, Dict, Loc, Asr) :-
    \+ current_context_value(evaluating, true),
    interface:'$implementation'(IM, Interface),
    with_context_value(assrt_lib:asr_head_prop(Asr, Interface, Head,
                                               Status, Type, Dict, Loc),
                       evaluating, true).

assrt_lib:asr_comm(in_asr(IM, Head, Asr), Comm, Loc) :-
    head_prop_asr_intf(Head, IM, _, _, _, _, Asr),
    assrt_lib:asr_comm(Asr, Comm, Loc).
assrt_lib:asr_comp(in_asr(IM, Head, Asr), M, Comp, Loc) :-
    head_prop_asr_intf(Head, IM, _, _, _, _, Asr),
    assrt_lib:asr_comp(Asr, M, Comp, Loc).
assrt_lib:asr_call(in_asr(IM, Head, Asr), M, Call, Loc) :-
    head_prop_asr_intf(Head, IM, _, _, _, _, Asr),
    assrt_lib:asr_call(Asr, M, Call, Loc).
assrt_lib:asr_succ(in_asr(IM, Head, Asr), M, Succ, Loc) :-
    head_prop_asr_intf(Head, IM, _, _, _, _, Asr),
    assrt_lib:asr_succ(Asr, M, Succ, Loc).
assrt_lib:asr_glob(in_asr(IM, Head, Asr), M, Glob, Loc) :-
    head_prop_asr_intf(Head, IM, _, _, _, _, Asr),
    assrt_lib:asr_glob(Asr, M, Glob, Loc).
