(* camlp5r *)
(* $Id: eprinter.mli,v 1.6 2007/12/11 18:21:52 deraugla Exp $ *)
(* Copyright (c) INRIA 2007 *)

(** Extensible printers.

    This module allows creation of printers, apply them and clear them.
    It is also used by the [EXTEND_PRINTER] and [pprintf] statements,
    added by the [pa_extprint.cmo] parsing kit. *)

type t 'a = 'abstract;
   (** Printer type, to print values of type "'a". *)

type pr_context = { ind : int; bef : string; aft : string; dang : string };
   (** Printing context.
    - "ind" : the current indendation
    - "bef" : what should be printed before, in the same line
    - "aft" : what should be printed after, in the same line
    - "dang" : the dangling token to know whether parentheses are necessary *)

value make : string -> t 'a;
   (** Builds a printer. The string parameter is used in error messages.
       The printer is created empty and can be extended with the
       [EXTEND_PRINTER] statement. *)

value apply : t 'a -> pr_context -> 'a -> string;
   (** Applies a printer, returning the printed string of the parameter. *)
value apply_level : t 'a -> string -> pr_context -> 'a -> string;
   (** Applies a printer at some specific level. Raises [Failure] if the
       given level does not exist. *)

value clear : t 'a -> unit;
   (** Clears a printer, removing all its levels and rules. *)
value print : t 'a -> unit;
   (** Print printer patterns, in the order they are recorded, for
       debugging purposes. *)

value empty_pc : pr_context;
   (** Empty printer context, equal to:
       [{ind = 0; bef = ""; aft = ""; dang = ""}] *)

value sprint_break :
  int -> int -> pr_context -> (pr_context -> string) ->
    (pr_context -> string) -> string;
   (** [sprint_break nspaces offset pc f g] concat the two strings returned
       by [f] and [g], either in one line, if it holds without overflowing
       (see module [Pretty]), with [nspaces] spaces betwen them, or in two
       lines with [offset] spaces added in the indentation for the second
       line.
         This function don't need to be called directly. It is generated by
       the [pprintf] statement according to its parameters when the format
       contains breaks, like [@;] and [@ ]. *)

value sprint_break_all :
  bool -> pr_context -> (pr_context -> string) ->
    list (int * int * pr_context -> string) -> string;
   (** [sprint_break_all force_newlines pc f fl] concat all strings returned
       by the list with separators [f]-[fl], the separators being the number
       of spaces and the offset like in the function [sprint_break]. The
       function works as "all or nothing", i.e. if the resulting string
       does not hold on the line, all strings are printed in different
       lines (even if sub-parts could hold in single lines). If the parameter
       [force_newline] is [True], all string are printed in different
       lines, no horizontal printing is tested.
         This function don't need to be called directly. It is generated by
       the [pprintf] statement according to its parameters when the format
       contains parenthesized parts with "break all" like "@[<a>" and "@]",
       or "@[<b>" and "@]". *)

(**/**)

(* for system use *)

type position =
  [ First
  | Last
  | Before of string
  | After of string
  | Level of string ]
;

type pr_fun 'a = pr_context -> 'a -> string;

type pr_rule 'a =
  Extfun.t 'a (pr_fun 'a -> pr_fun 'a -> pr_context -> string)
;

value extend :
  t 'a -> option position ->
    list (option string * pr_rule 'a -> pr_rule 'a) -> unit;
