(* camlp4r *)
(* This file has been generated by program: do not edit! *)

(*
Added statements:

  At toplevel (structure item):

     DEFINE <uident>
     DEFINE <uident> = <expression>
     DEFINE <uident> (<parameters>) = <expression>
     IFDEF <dexpr> THEN <structure_items> END
     IFDEF <dexpr> THEN <structure_items> ELSE <structure_items> END
     IFNDEF <dexpr> THEN <structure_items> END
     IFNDEF <dexpr> THEN <structure_items> ELSE <structure_items> END

  In expressions:

     IFDEF <dexpr> THEN <expression> ELSE <expression> END
     IFNDEF <dexpr> THEN <expression> ELSE <expression> END
     __FILE__
     __LOCATION__

  In patterns:

     IFDEF <dexpr> THEN <pattern> ELSE <pattern> END
     IFNDEF <dexpr> THEN <pattern> ELSE <pattern> END

  A <dexpr> is either:

     <dexpr> OR <dexpr>
     <dexpr> AND <dexpr>
     NOT <dexpr>
     ( <dexpr> )
     <uident>

  As Camlp4 options:

     -D<uident>
     -U<uident>

  After having used a DEFINE <uident> followed by "= <expression>", you
  can use it in expressions *and* in patterns. If the expression defining
  the macro cannot be used as a pattern, there is an error message if
  it is used in a pattern.

  The expression __FILE__ returns the current compiled file name.
  The expression __LOCATION__ returns the current location of itself.

*)

(* #load "pa_extend.cmo" *)
(* #load "q_MLast.cmo" *)

open Pcaml;;

type 'a item_or_def =
    SdStr of 'a
  | SdDef of string * (string list * MLast.expr) option
  | SdUnd of string
  | SdNop
;;

let rec list_remove x =
  function
    (y, _) :: l when y = x -> l
  | d :: l -> d :: list_remove x l
  | [] -> []
;;

let defined = ref ["CAMLP4S", None];;

let is_defined i = List.mem_assoc i !defined;;

let loc = Stdpp.dummy_loc;;

let subst mloc env =
  let rec loop =
    function
      MLast.ExLet (_, rf, pel, e) ->
        let pel = List.map (fun (p, e) -> p, loop e) pel in
        MLast.ExLet (loc, rf, pel, loop e)
    | MLast.ExIfe (_, e1, e2, e3) ->
        MLast.ExIfe (loc, loop e1, loop e2, loop e3)
    | MLast.ExApp (_, e1, e2) -> MLast.ExApp (loc, loop e1, loop e2)
    | MLast.ExLid (_, x) | MLast.ExUid (_, x) as e ->
        begin try MLast.ExAnt (loc, List.assoc x env) with
          Not_found -> e
        end
    | MLast.ExTup (_, x) -> MLast.ExTup (loc, List.map loop x)
    | MLast.ExRec (_, pel, None) ->
        let pel = List.map (fun (p, e) -> p, loop e) pel in
        MLast.ExRec (loc, pel, None)
    | e -> e
  in
  loop
;;

let substp mloc env =
  let rec loop =
    function
      MLast.ExApp (_, e1, e2) -> MLast.PaApp (loc, loop e1, loop e2)
    | MLast.ExLid (_, x) ->
        begin try MLast.PaAnt (loc, List.assoc x env) with
          Not_found -> MLast.PaLid (loc, x)
        end
    | MLast.ExUid (_, x) ->
        begin try MLast.PaAnt (loc, List.assoc x env) with
          Not_found -> MLast.PaUid (loc, x)
        end
    | MLast.ExInt (_, x) -> MLast.PaInt (loc, x)
    | MLast.ExTup (_, x) -> MLast.PaTup (loc, List.map loop x)
    | MLast.ExRec (_, pel, None) ->
        let ppl = List.map (fun (p, e) -> p, loop e) pel in
        MLast.PaRec (loc, ppl)
    | x ->
        Stdpp.raise_with_loc mloc
          (Failure
             "this macro cannot be used in a pattern (see its definition)")
  in
  loop
;;

let incorrect_number loc l1 l2 =
  Stdpp.raise_with_loc loc
    (Failure
       (Printf.sprintf "expected %d parameters; found %d" (List.length l2)
          (List.length l1)))
;;

let define eo x =
  begin match eo with
    Some ([], e) ->
      Grammar.extend
        [Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
         Some (Gramext.Level "simple"),
         [None, None,
          [[Gramext.Stoken ("UIDENT", x)],
           Gramext.action
             (fun _ (loc : Token.location) ->
                (Pcaml.expr_reloc (fun _ -> loc) 0 e : 'expr))]];
         Grammar.Entry.obj (patt : 'patt Grammar.Entry.e),
         Some (Gramext.Level "simple"),
         [None, None,
          [[Gramext.Stoken ("UIDENT", x)],
           Gramext.action
             (fun _ (loc : Token.location) ->
                (let p = substp loc [] e in
                 Pcaml.patt_reloc (fun _ -> loc) 0 p :
                 'patt))]]]
  | Some (sl, e) ->
      Grammar.extend
        [Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
         Some (Gramext.Level "apply"),
         [None, None,
          [[Gramext.Stoken ("UIDENT", x); Gramext.Sself],
           Gramext.action
             (fun (param : 'expr) _ (loc : Token.location) ->
                (let el =
                   match param with
                     MLast.ExTup (_, el) -> el
                   | e -> [e]
                 in
                 if List.length el = List.length sl then
                   let env = List.combine sl el in
                   let e = subst loc env e in
                   Pcaml.expr_reloc (fun _ -> loc) 0 e
                 else incorrect_number loc el sl :
                 'expr))]];
         Grammar.Entry.obj (patt : 'patt Grammar.Entry.e),
         Some (Gramext.Level "simple"),
         [None, None,
          [[Gramext.Stoken ("UIDENT", x); Gramext.Sself],
           Gramext.action
             (fun (param : 'patt) _ (loc : Token.location) ->
                (let pl =
                   match param with
                     MLast.PaTup (_, pl) -> pl
                   | p -> [p]
                 in
                 if List.length pl = List.length sl then
                   let env = List.combine sl pl in
                   let p = substp loc env e in
                   Pcaml.patt_reloc (fun _ -> loc) 0 p
                 else incorrect_number loc pl sl :
                 'patt))]]]
  | None -> ()
  end;
  defined := (x, eo) :: !defined
;;

let undef x =
  try
    let eo = List.assoc x !defined in
    begin match eo with
      Some ([], _) ->
        Grammar.delete_rule expr [Gramext.Stoken ("UIDENT", x)];
        Grammar.delete_rule patt [Gramext.Stoken ("UIDENT", x)]
    | Some (_, _) ->
        Grammar.delete_rule expr
          [Gramext.Stoken ("UIDENT", x); Gramext.Sself];
        Grammar.delete_rule patt [Gramext.Stoken ("UIDENT", x); Gramext.Sself]
    | None -> ()
    end;
    defined := list_remove x !defined
  with
    Not_found -> ()
;;

Grammar.extend
  (let _ = (expr : 'expr Grammar.Entry.e)
   and _ = (patt : 'patt Grammar.Entry.e)
   and _ = (str_item : 'str_item Grammar.Entry.e)
   and _ = (sig_item : 'sig_item Grammar.Entry.e) in
   let grammar_entry_create s =
     Grammar.Entry.create (Grammar.of_entry expr) s
   in
   let macro_def : 'macro_def Grammar.Entry.e =
     grammar_entry_create "macro_def"
   and str_item_or_macro : 'str_item_or_macro Grammar.Entry.e =
     grammar_entry_create "str_item_or_macro"
   and opt_macro_value : 'opt_macro_value Grammar.Entry.e =
     grammar_entry_create "opt_macro_value"
   and dexpr : 'dexpr Grammar.Entry.e = grammar_entry_create "dexpr"
   and uident : 'uident Grammar.Entry.e = grammar_entry_create "uident" in
   [Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e),
    Some Gramext.First,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (macro_def : 'macro_def Grammar.Entry.e))],
      Gramext.action
        (fun (x : 'macro_def) (loc : Token.location) ->
           (match x with
              SdStr [si] -> si
            | SdStr sil -> MLast.StDcl (loc, sil)
            | SdDef (x, eo) -> define eo x; MLast.StDcl (loc, [])
            | SdUnd x -> undef x; MLast.StDcl (loc, [])
            | SdNop -> MLast.StDcl (loc, []) :
            'str_item))]];
    Grammar.Entry.obj (macro_def : 'macro_def Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "IFNDEF");
       Gramext.Snterm (Grammar.Entry.obj (dexpr : 'dexpr Grammar.Entry.e));
       Gramext.Stoken ("", "THEN");
       Gramext.Snterm
         (Grammar.Entry.obj
            (str_item_or_macro : 'str_item_or_macro Grammar.Entry.e));
       Gramext.Stoken ("", "ELSE");
       Gramext.Snterm
         (Grammar.Entry.obj
            (str_item_or_macro : 'str_item_or_macro Grammar.Entry.e));
       Gramext.Stoken ("", "END")],
      Gramext.action
        (fun _ (d2 : 'str_item_or_macro) _ (d1 : 'str_item_or_macro) _
           (e : 'dexpr) _ (loc : Token.location) ->
           (if e then d2 else d1 : 'macro_def));
      [Gramext.Stoken ("", "IFNDEF");
       Gramext.Snterm (Grammar.Entry.obj (dexpr : 'dexpr Grammar.Entry.e));
       Gramext.Stoken ("", "THEN");
       Gramext.Snterm
         (Grammar.Entry.obj
            (str_item_or_macro : 'str_item_or_macro Grammar.Entry.e));
       Gramext.Stoken ("", "END")],
      Gramext.action
        (fun _ (d : 'str_item_or_macro) _ (e : 'dexpr) _
           (loc : Token.location) ->
           (if e then SdNop else d : 'macro_def));
      [Gramext.Stoken ("", "IFDEF");
       Gramext.Snterm (Grammar.Entry.obj (dexpr : 'dexpr Grammar.Entry.e));
       Gramext.Stoken ("", "THEN");
       Gramext.Snterm
         (Grammar.Entry.obj
            (str_item_or_macro : 'str_item_or_macro Grammar.Entry.e));
       Gramext.Stoken ("", "ELSE");
       Gramext.Snterm
         (Grammar.Entry.obj
            (str_item_or_macro : 'str_item_or_macro Grammar.Entry.e));
       Gramext.Stoken ("", "END")],
      Gramext.action
        (fun _ (d2 : 'str_item_or_macro) _ (d1 : 'str_item_or_macro) _
           (e : 'dexpr) _ (loc : Token.location) ->
           (if e then d1 else d2 : 'macro_def));
      [Gramext.Stoken ("", "IFDEF");
       Gramext.Snterm (Grammar.Entry.obj (dexpr : 'dexpr Grammar.Entry.e));
       Gramext.Stoken ("", "THEN");
       Gramext.Snterm
         (Grammar.Entry.obj
            (str_item_or_macro : 'str_item_or_macro Grammar.Entry.e));
       Gramext.Stoken ("", "END")],
      Gramext.action
        (fun _ (d : 'str_item_or_macro) _ (e : 'dexpr) _
           (loc : Token.location) ->
           (if e then d else SdNop : 'macro_def));
      [Gramext.Stoken ("", "UNDEF");
       Gramext.Snterm (Grammar.Entry.obj (uident : 'uident Grammar.Entry.e))],
      Gramext.action
        (fun (i : 'uident) _ (loc : Token.location) ->
           (SdUnd i : 'macro_def));
      [Gramext.Stoken ("", "DEFINE");
       Gramext.Snterm (Grammar.Entry.obj (uident : 'uident Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj
            (opt_macro_value : 'opt_macro_value Grammar.Entry.e))],
      Gramext.action
        (fun (def : 'opt_macro_value) (i : 'uident) _
           (loc : Token.location) ->
           (SdDef (i, def) : 'macro_def))]];
    Grammar.Entry.obj
      (str_item_or_macro : 'str_item_or_macro Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Slist1
         (Gramext.Snterm
            (Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e)))],
      Gramext.action
        (fun (si : 'str_item list) (loc : Token.location) ->
           (SdStr si : 'str_item_or_macro));
      [Gramext.Snterm
         (Grammar.Entry.obj (macro_def : 'macro_def Grammar.Entry.e))],
      Gramext.action
        (fun (d : 'macro_def) (loc : Token.location) ->
           (d : 'str_item_or_macro))]];
    Grammar.Entry.obj (opt_macro_value : 'opt_macro_value Grammar.Entry.e),
    None,
    [None, None,
     [[],
      Gramext.action
        (fun (loc : Token.location) -> (None : 'opt_macro_value));
      [Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (loc : Token.location) ->
           (Some ([], e) : 'opt_macro_value));
      [Gramext.Stoken ("", "(");
       Gramext.Slist1sep
         (Gramext.Stoken ("LIDENT", ""), Gramext.Stoken ("", ","));
       Gramext.Stoken ("", ")"); Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ _ (pl : string list) _ (loc : Token.location) ->
           (Some (pl, e) : 'opt_macro_value))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "top"),
    [None, None,
     [[Gramext.Stoken ("", "IFNDEF");
       Gramext.Snterm (Grammar.Entry.obj (dexpr : 'dexpr Grammar.Entry.e));
       Gramext.Stoken ("", "THEN"); Gramext.Sself;
       Gramext.Stoken ("", "ELSE"); Gramext.Sself;
       Gramext.Stoken ("", "END")],
      Gramext.action
        (fun _ (e2 : 'expr) _ (e1 : 'expr) _ (e : 'dexpr) _
           (loc : Token.location) ->
           (if e then e2 else e1 : 'expr));
      [Gramext.Stoken ("", "IFDEF");
       Gramext.Snterm (Grammar.Entry.obj (dexpr : 'dexpr Grammar.Entry.e));
       Gramext.Stoken ("", "THEN"); Gramext.Sself;
       Gramext.Stoken ("", "ELSE"); Gramext.Sself;
       Gramext.Stoken ("", "END")],
      Gramext.action
        (fun _ (e2 : 'expr) _ (e1 : 'expr) _ (e : 'dexpr) _
           (loc : Token.location) ->
           (if e then e1 else e2 : 'expr))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "simple"),
    [None, None,
     [[Gramext.Stoken ("LIDENT", "__LOCATION__")],
      Gramext.action
        (fun _ (loc : Token.location) ->
           (let bp = string_of_int (Stdpp.first_pos loc) in
            let ep = string_of_int (Stdpp.last_pos loc) in
            MLast.ExTup
              (loc, [MLast.ExInt (loc, bp); MLast.ExInt (loc, ep)]) :
            'expr));
      [Gramext.Stoken ("LIDENT", "__FILE__")],
      Gramext.action
        (fun _ (loc : Token.location) ->
           (MLast.ExStr (loc, !(Pcaml.input_file)) : 'expr))]];
    Grammar.Entry.obj (patt : 'patt Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "IFNDEF");
       Gramext.Snterm (Grammar.Entry.obj (dexpr : 'dexpr Grammar.Entry.e));
       Gramext.Stoken ("", "THEN"); Gramext.Sself;
       Gramext.Stoken ("", "ELSE"); Gramext.Sself;
       Gramext.Stoken ("", "END")],
      Gramext.action
        (fun _ (p2 : 'patt) _ (p1 : 'patt) _ (e : 'dexpr) _
           (loc : Token.location) ->
           (if e then p2 else p1 : 'patt));
      [Gramext.Stoken ("", "IFDEF");
       Gramext.Snterm (Grammar.Entry.obj (dexpr : 'dexpr Grammar.Entry.e));
       Gramext.Stoken ("", "THEN"); Gramext.Sself;
       Gramext.Stoken ("", "ELSE"); Gramext.Sself;
       Gramext.Stoken ("", "END")],
      Gramext.action
        (fun _ (p2 : 'patt) _ (p1 : 'patt) _ (e : 'dexpr) _
           (loc : Token.location) ->
           (if e then p1 else p2 : 'patt))]];
    Grammar.Entry.obj (dexpr : 'dexpr Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Sself; Gramext.Stoken ("", "OR"); Gramext.Sself],
      Gramext.action
        (fun (y : 'dexpr) _ (x : 'dexpr) (loc : Token.location) ->
           (x || y : 'dexpr))];
     None, None,
     [[Gramext.Sself; Gramext.Stoken ("", "AND"); Gramext.Sself],
      Gramext.action
        (fun (y : 'dexpr) _ (x : 'dexpr) (loc : Token.location) ->
           (y && y : 'dexpr))];
     None, None,
     [[Gramext.Stoken ("", "NOT"); Gramext.Sself],
      Gramext.action
        (fun (x : 'dexpr) _ (loc : Token.location) -> (not x : 'dexpr))];
     None, None,
     [[Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (x : 'dexpr) _ (loc : Token.location) -> (x : 'dexpr));
      [Gramext.Snterm (Grammar.Entry.obj (uident : 'uident Grammar.Entry.e))],
      Gramext.action
        (fun (i : 'uident) (loc : Token.location) ->
           (is_defined i : 'dexpr))]];
    Grammar.Entry.obj (uident : 'uident Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Token.location) -> (i : 'uident))]]]);;

Pcaml.add_option "-D" (Arg.String (define None))
  "<string> Define for IFDEF instruction.";;
Pcaml.add_option "-U" (Arg.String undef)
  "<string> Undefine for IFDEF instruction.";;
