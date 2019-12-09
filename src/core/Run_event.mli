(* This file is free software. See file "license" for more details. *)

(** {1 Event Stored on Disk or Transmitted on Network} *)

module Db = Sqlite3_utils
module J = Misc.Json

type 'a or_error = ('a, string) CCResult.t

type prover  = Prover.t
type checker = unit

type +'a result = {
  program : 'a;
  problem : Problem.t;
  timeout: int;
  raw : Proc_run_result.t;
}

val program : 'a result -> 'a
val problem : _ result -> Problem.t
val raw : _ result -> Proc_run_result.t

val analyze_p_opt : prover result -> Res.t option
val analyze_p : prover result -> Res.t

type t =
  | Prover_run of prover result
  | Checker_run of checker result

type event = t

val mk_prover : prover result -> t
val mk_checker : checker result -> t

val pp : t CCFormat.printer

type snapshot = private {
  timestamp: float;
  events: t list;
  meta: string; (* additional metadata *)
}

module Snapshot : sig
  type t = snapshot

  val make : ?meta:string -> ?timestamp:float -> event list -> t

  val provers : t -> Prover.Set.t

  val pp : t CCFormat.printer
end

type snapshot_meta = private {
  s_timestamp: float;
  s_meta: string;
  s_provers: Prover.Set.t;
  s_len: int;
}

module Meta : sig
  type t = snapshot_meta

  val provers : t -> Prover.Set.t
  val timestamp : t -> float
  val length : t -> int

  val pp : t CCFormat.printer
end

val meta : snapshot -> snapshot_meta

val encode_result : 'a J.Encode.t -> 'a result J.Encode.t
val decode_result : 'a J.Decode.t -> 'a result J.Decode.t

val encode : t J.Encode.t
val decode : t J.Decode.t

val prepare_db : Db.t -> unit or_error
val to_db_prover_result : Db.t -> Prover.t result -> unit or_error
val to_db: Db.t -> t -> unit or_error
