(* camlp5r *)
(* $Id: eprinter.ml,v 1.12 2007/12/11 18:21:52 deraugla Exp $ *)
(* Copyright (c) INRIA 2007 *)

type t 'a =
  { pr_name : string;
    pr_fun : mutable string -> pr_fun 'a;
    pr_levels : mutable list (pr_level 'a) }
and pr_level 'a = { pr_label : string; pr_rules : mutable pr_rule 'a }
and pr_rule 'a =
  Extfun.t 'a (pr_fun 'a -> pr_fun 'a -> pr_context -> string)
and pr_fun 'a = pr_context -> 'a -> string
and pr_context = { ind : int; bef : string; aft : string; dang : string };

type position =
  [ First
  | Last
  | Before of string
  | After of string
  | Level of string ]
;

value add_lev (lab, extf) levs =
  let lab =
    match lab with
    [ Some lab -> lab
    | None -> "" ]
  in
  let lev = {pr_label = lab; pr_rules = extf Extfun.empty} in
  [lev :: levs]
;

value extend pr pos levs =
  match pos with
  [ None ->
      let levels = List.fold_right add_lev levs pr.pr_levels in
      pr.pr_levels := levels
  | Some (Level lab) ->
      let levels =
        loop pr.pr_levels where rec loop =
          fun
          [ [pr_lev :: pr_levs] ->
              if lab = pr_lev.pr_label then
                match levs with
                [ [(_, extf) :: levs] ->
                    let lev =
                      {(pr_lev) with pr_rules = extf pr_lev.pr_rules}
                    in
                    let levs = List.fold_right add_lev levs pr_levs in
                    [lev :: levs]
                | [] -> [pr_lev :: pr_levs] ]
              else [pr_lev :: loop pr_levs]
          | [] -> failwith ("level " ^ lab ^ " not found") ]
      in
      pr.pr_levels := levels
  | Some (After lab) ->
      let levels =
        loop pr.pr_levels where rec loop =
          fun
          [ [pr_lev :: pr_levs] ->
              if lab = pr_lev.pr_label then
                let pr_levs = List.fold_right add_lev levs pr_levs in
                [pr_lev :: pr_levs]
              else [pr_lev :: loop pr_levs]
          | [] -> failwith ("level " ^ lab ^ " not found") ]
      in
      pr.pr_levels := levels
  | Some _ ->
      failwith "not impl EXTEND_PRINTER entry with at level parameter" ]
;

value pr_fun name pr lab =
  loop False pr.pr_levels where rec loop app =
    fun
    [ [] ->
        fun pc z ->
          failwith
            (Printf.sprintf "unable to print %s%s" name
               (if lab = "" then "" else " \"" ^ lab ^ "\""))
    | [lev :: levl] ->
        if lab = "" || app || lev.pr_label = lab then
          let next = loop True levl in
          curr where rec curr pc z =
            Extfun.apply lev.pr_rules z curr next pc
        else loop app levl ]
;

value make name = do {
  let pr = {pr_name = name; pr_fun = fun []; pr_levels = []} in
  pr.pr_fun := pr_fun name pr;
  pr
};

value clear pr = do {
  pr.pr_levels := [];
  pr.pr_fun := pr_fun pr.pr_name pr;
};

value apply_level pr lname pc z = pr.pr_fun lname pc z;
value apply pr pc z = pr.pr_fun "" pc z;

value empty_pc = {ind = 0; bef = ""; aft = ""; dang = ""};

value print pr =
  List.iter
    (fun lev -> do {
       Printf.printf "level \"%s\"\n" lev.pr_label;
       Extfun.print lev.pr_rules;
       flush stdout;
     })
    pr.pr_levels
;

value tab ind = String.make ind ' ';

value sprint_break nspaces offset pc f g =
  Pretty.horiz_vertic
    (fun () ->
       let sp = String.make nspaces ' ' in
       Pretty.sprintf "%s%s%s" (f {(pc) with aft = ""}) sp
         (g {(pc) with bef = ""}))
    (fun () ->
       let s1 = f {(pc) with aft = ""} in
       let s2 =
         g {(pc) with ind = pc.ind + offset; bef = tab (pc.ind + offset)}
       in
       Pretty.sprintf "%s\n%s" s1 s2)
;

value sprint_break_all force_newlines pc f fl =
  Pretty.horiz_vertic
    (fun () ->
       if force_newlines then Pretty.sprintf "\n"
       else
         loop (f (if fl = [] then pc else {(pc) with aft = ""})) fl
         where rec loop s =
           fun
           [ [(sp, off, f) :: fl] ->
               let s =
                 Pretty.sprintf "%s%s%s" s (String.make sp ' ')
                   (f {(pc) with bef = "";
                       aft = if fl = [] then pc.aft else ""})
               in
               loop s fl
           | [] -> s ])
    (fun () ->
       loop (f (if fl = [] then pc else {(pc) with aft = ""})) fl
       where rec loop s =
         fun
         [ [(sp, off, f) :: fl] ->
             let s =
               Pretty.sprintf "%s\n%s" s
                 (f {(pc) with ind = pc.ind + off; bef = tab (pc.ind + off);
                     aft = if fl = [] then pc.aft else ""})
             in
             loop s fl
         | [] -> s ])
;
