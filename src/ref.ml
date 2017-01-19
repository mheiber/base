open! Import

(* In the definition of [t], we do not have [[@@deriving_inline bin_io, compare, sexp][@@@end]] because
   in general, syntax extensions tend to use the implementation when available rather than
   using the alias.  Here that would lead to use the record representation [ { mutable
   contents : 'a } ] which would result in different (and unwanted) behavior.  *)
type 'a t = 'a ref = { mutable contents : 'a }

include (struct
  type 'a t = 'a ref [@@deriving_inline compare, sexp]
  let t_of_sexp : 'a . (Sexplib.Sexp.t -> 'a) -> Sexplib.Sexp.t -> 'a t =
    let _tp_loc = "src/ref.ml.t"  in
    fun _of_a  -> fun t  -> (ref_of_sexp _of_a) t
  let sexp_of_t : 'a . ('a -> Sexplib.Sexp.t) -> 'a t -> Sexplib.Sexp.t =
    fun _of_a  -> fun v  -> (sexp_of_ref _of_a) v
  let compare : 'a . ('a -> 'a -> int) -> 'a t -> 'a t -> int =
    fun _cmp__a  ->
    fun a__001_  -> fun b__002_  -> compare_ref _cmp__a a__001_ b__002_

  [@@@end]
end : sig
           type 'a t = 'a ref [@@deriving_inline compare, sexp]
           include
           sig
             [@@@ocaml.warning "-32"]
             val t_of_sexp : (Sexplib.Sexp.t -> 'a) -> Sexplib.Sexp.t -> 'a t
             val sexp_of_t : ('a -> Sexplib.Sexp.t) -> 'a t -> Sexplib.Sexp.t
             val compare : ('a -> 'a -> int) -> 'a t -> 'a t -> int
           end
           [@@@end]
         end with type 'a t := 'a t)

external create : 'a   -> 'a t       = "%makemutable"
external ( ! )  : 'a t -> 'a         = "%field0"
external ( := ) : 'a t -> 'a -> unit = "%setfield0"

let swap t1 t2 =
  let tmp = !t1 in
  t1 := !t2;
  t2 := tmp

let replace t f = t := f !t

(* container functions below *)
let length _ = 1

let is_empty _ = false

let iter t ~f = f !t

let fold t ~init ~f = f init !t

let fold_result t ~init ~f = f init !t
let fold_until  t ~init ~f : ('a, 'b) Container_intf.Finished_or_stopped_early.t =
  match (f init !t : ('a, 'b) Container_intf.Continue_or_stop.t) with
  | Stop     x -> Stopped_early  x
  | Continue x -> Finished       x

let count t ~f = if f !t then 1 else 0
let sum _ t ~f = f !t

let exists t ~f = f !t

let for_all t ~f = f !t

let mem ?(equal = Poly.equal) t a = equal a !t

let find t ~f = let a = !t in if f a then Some a else None

let find_map t ~f = f !t

let to_list t = [ !t ]

let to_array t = [| !t |]

let min_elt t ~cmp:_ = Some !t
let max_elt t ~cmp:_ = Some !t

let set_temporarily t a ~f =
  let restore_to = !t in
  t := a;
  Exn.protect ~f ~finally:(fun () -> t := restore_to);
;;
