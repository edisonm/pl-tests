/*  Part of Extended Libraries for SWI-Prolog

    Author:        Edison Mera Menendez
    E-mail:        efmera@gmail.com
    WWW:           https://github.com/edisonm/xlibrary
    Copyright (C): 2014, Process Design Center, Breda, The Netherlands.
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

:- module(expansion_module,
          [expansion_module/2,
           is_expansion_module/1]).

reexported_module(EM1, EF) :-
    '$load_context_module'(EF, EM1, Opts),
    option(reexport(true), Opts).

expansion_module_(M, EM, EF) :-
    CM = compound_expand,
    module_property(CM, file(CF)),
    ( nonvar(EF)
    ->module_property(EM, file(EF)),
      '$load_context_module'(CF, EM, _),
      '$load_context_module'(EF, M, _)
    ; '$load_context_module'(EF, M, _),
      module_property(EM, file(EF)),
      '$load_context_module'(CF, EM, _)
    ).

expansion_module(M, EM, L, EF1, EF) :-
    expansion_module_(M, EM1, EF1),
    \+ memberchk(EM1, L),
    ( EM = EM1,
      EF = EF1
    ; reexported_module(EM1, EF2),
      expansion_module(EM1, EM, [M|L], EF2, EF)
    ).

%!  expansion_module(+Module, ?ExpansionModule)
%
%   Kludge: using swipl internals. Perhaps is not a good idea --EMM
%   Warning: could report duplicate solutions
%
expansion_module(M, EM) :-
    expansion_module(M, EM, [], _, _).

is_expansion_module(EM) :-
    CM = compound_expand,
    module_property(CM, file(CF)),
    '$load_context_module'(CF, EM, _).
