(* camlp5r pa_extend.cmo q_MLast.cmo *)
(***********************************************************************)
(*                                                                     *)
(*                             Camlp5                                  *)
(*                                                                     *)
(*                Daniel de Rauglaudre, INRIA Rocquencourt             *)
(*                                                                     *)
(*  Copyright 2007 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(***********************************************************************)

(* $Id: pa_extend_m.ml,v 1.6 2007/08/05 16:27:59 deraugla Exp $ *)

open Pa_extend;

EXTEND
  symbol: LEVEL "top"
    [ NONA
      [ min = [ UIDENT "SLIST0" -> False | UIDENT "SLIST1" -> True ];
        s = SELF; sep = OPT [ UIDENT "SEP"; t = symbol -> t ] ->
          sslist loc min sep s
      | UIDENT "SOPT"; s = SELF ->
          ssopt loc s
      | UIDENT "SFLAG"; s = SELF ->
          ssflag loc s
      | UIDENT "SFLAG2"; s = SELF ->
          ssflag2 loc s ] ]
  ;
END;
