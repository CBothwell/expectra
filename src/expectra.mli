type status = 
  | Success of string 
  | Failure of string

type matches = 
  | BeginsWith of string
  | EndsWith of string 
  | WithFunction of (string -> status) 
  | Any

type t 

val get_status : t -> status

val next_line : ?expect:matches -> t -> t Lwt.t 

val send : t -> ?expect:matches -> string -> t Lwt.t 

val spawn : string -> t Lwt.t 

val close : t -> unit Lwt.t 
