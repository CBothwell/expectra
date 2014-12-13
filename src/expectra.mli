type status = 
  | Success of string 
  | Failure of exn

type matches = 
  | Begins of string
  | Ends of string 
  | Function of (string -> status) 
  | Any
(** matches will use the Str library for BeginsWith and EndsWith to match at the start or end
  * of a string. Any will match all input on a line and is the default. WithFunction provides a way
  * to exend how matches can be done with a function. If you need to use a differnt regular expression library, 
  * or if you have special needs when matching a line this will provide you that capability. *) 

type t 

val get_status : t -> status
(** get_status provides a way to get the status contained in the 
  * expcetra type without forcing you to deal with the implementation details
  * @param t -> the expectra type
  * @return -> the status of the expectra type *)

val set_status : t -> status -> t 
(** set status provides a way to set the status of the expectra type. 
  * this can be used to capture the current line in the status
  * @param t -> the expectra type
  * @param status -> a new status
  * @return -> the new expectra.t *) 
  

val next_line : ?expect:matches -> t -> t Lwt.t 
(** next_line gets the next line in interactive programs output
  * @param ?expect -> expect takes an optional matches argument to match the 
  *                  line agaisnt. 
  * @param t -> the expectra type 
  * @return -> an Lwt thread containing the next expectra type *)

val stream : ?expect:matches -> t -> status Lwt_stream.t 
(** stream gives you access to an Lwt_stream of the results returned by 
  * send. This gives you a way to interact with the output using the 
  * Lwt_stream functions. 
  * @param ?expect -> expect takes an optional matches to match each line against
  * @param t -> the expctra type
  * @returns -> returns the Lwt_stream by line of the interactive application *) 

val send : t -> ?expect:matches -> string -> t Lwt.t 
(** send sends a string to the interactive process and returns the first string of
  * the output. Additional output lines can be queried with next_line or stream. 
  * @param t -> the expectra type
  * @param ?expect -> optional type to match the line against
  * @param str -> a string to send to the interactive process
  * @return -> a new expectra type based on the output of the interactive application *) 

val spawn : string -> t Lwt.t 
(** spawn starts a new interactive process and returns an expectra type used to interact with
  * that process. 
  * @param string -> string of a unix command with options
  * @return -> an Lwt thread of the expectra type for interacting with *) 

val close : t -> t Lwt.t 
(** close will terminate the interactive process currently being used. 
  * @param t -> expectra type to terminate connection with 
  * @return -> returns a unit Lwt thread after closing the process and pipe to the process. *) 
