open Generic

module Z : Generator with type t = Z.t = struct
  type t = Z.t

  let gen = Crowbar.(map [int64] Z.of_int64)

  let ( = ) = Z.equal
end

module Q : Generator with type t = Q.t = struct
  type t = Q.t

  let gen =
    Crowbar.(
      map [int64; int64] (fun n d -> Q.(of_int64 n / of_int64 (Int64.succ d))))

  let ( = ) = Q.equal
end

module Free_ring = struct
  type t = Zero | One | Add of t * t | Mul of t * t | Neg of t

  let gen =
    let open Crowbar in
    fix (fun gen ->
        choose
          [ const Zero;
            const One;
            map [gen; gen] (fun l r -> Add (l, r));
            map [gen; gen] (fun l r -> Mul (l, r));
            map [gen] (fun x -> Neg x) ])

  let rec equal x y =
    match (x, y) with
    | (Zero, Zero) -> true
    | (One, One) -> true
    | (Add (l, r), Add (l', r')) -> equal l l' && equal r r'
    | (Mul (l, r), Mul (l', r')) -> equal l l' && equal r r'
    | (Neg x, Neg x') -> equal x x'
    | _ -> false

  let rec pp fmtr (x : t) =
    let open Format in
    match x with
    | Zero -> fprintf fmtr "0"
    | One -> fprintf fmtr "1"
    | Add (x, y) -> fprintf fmtr "@[(%a + %a)@]" pp x pp y
    | Mul (x, y) -> fprintf fmtr "%a * %a" pp x pp y
    | Neg x -> fprintf fmtr "@[(-%a)@]" pp x

  let ( = ) = equal
end

module Make_ring_gen (R : Basic_structures.Basic_intf.Lang.Ring) = struct
  type t = R.t R.m

  let rec interpret ?(zero = R.zero) (expr : Free_ring.t) =
    match expr with
    | Free_ring.Zero -> zero
    | Free_ring.One -> R.one
    | Free_ring.Add (l, r) -> R.add (interpret l) (interpret r)
    | Free_ring.Mul (l, r) -> R.mul (interpret l) (interpret r)
    | Free_ring.Neg x -> R.neg (interpret x)

  let gen = Crowbar.(map [Free_ring.gen] interpret)
end
