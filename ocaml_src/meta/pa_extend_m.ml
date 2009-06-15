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

(* This file has been generated by program: do not edit! *)

open Pa_extend;;

Grammar.extend
  [Grammar.Entry.obj (symbol : 'symbol Grammar.Entry.e),
   Some (Gramext.Level "top"),
   [None, Some Gramext.NonA,
    [[Gramext.Stoken ("UIDENT", "SFLAG2"); Gramext.Sself],
     Gramext.action
       (fun (s : 'symbol) _ (loc : Token.location) ->
          (ssflag2 loc s : 'symbol));
     [Gramext.Stoken ("UIDENT", "SFLAG"); Gramext.Sself],
     Gramext.action
       (fun (s : 'symbol) _ (loc : Token.location) ->
          (ssflag loc s : 'symbol));
     [Gramext.Stoken ("UIDENT", "SOPT"); Gramext.Sself],
     Gramext.action
       (fun (s : 'symbol) _ (loc : Token.location) ->
          (ssopt loc s : 'symbol));
     [Gramext.srules
        [[Gramext.Stoken ("UIDENT", "SLIST1")],
         Gramext.action (fun _ (loc : Token.location) -> (true : 'e__1));
         [Gramext.Stoken ("UIDENT", "SLIST0")],
         Gramext.action (fun _ (loc : Token.location) -> (false : 'e__1))];
      Gramext.Sself;
      Gramext.Sopt
        (Gramext.srules
           [[Gramext.Stoken ("UIDENT", "SEP");
             Gramext.Snterm
               (Grammar.Entry.obj (symbol : 'symbol Grammar.Entry.e))],
            Gramext.action
              (fun (t : 'symbol) _ (loc : Token.location) -> (t : 'e__2))])],
     Gramext.action
       (fun (sep : 'e__2 option) (s : 'symbol) (min : 'e__1)
            (loc : Token.location) ->
          (sslist loc min sep s : 'symbol))]]];;
