type status = 
  | Success of string 
  | Failure of string 

type matches = 
  | BeginsWith of string
  | EndsWith of string
  | WithFunction of (string -> status) 
  | Any 

type t = {
  reader: Lwt_io.input Lwt_io.channel;
  writer: Lwt_io.output Lwt_io.channel; 
  stream: string Lwt_stream.t; 
  status: status; 
}

let get_status t = t.status  

let expect_match line = function
  | BeginsWith regx -> begin 
    let re = Str.regexp regx in 
    try ignore(Str.search_forward re line 0); Success (Str.matched_string line) 
    with Not_found -> Failure "Not found" 
  end 
  | EndsWith regx -> begin
    let re = Str.regexp regx in 
    try ignore(Str.search_backward re line 0); Success (Str.matched_string line)
    with Not_found -> Failure "Not found" 
  end
  | WithFunction f -> f line 
  | Any -> Success line 
 
let next_line ?(expect=Any) t = 
  let (>>=) = Lwt.bind in 
  try Lwt_stream.next t.stream
    >>= fun line -> 
      Lwt.return {t with status = expect_match line expect}
  with Lwt_stream.Empty -> 
    Lwt.return {t with status = Failure "Empty stream"}

let stream ?(expect=Any) t = 
  let (>>=) = Lwt.bind in 
  let next ex = next_line ex ~expect in 
  Lwt_stream.from 
    (fun () -> next t
      >>= fun em -> match em.status with 
      | Failure s when Str.string_match (Str.regexp_string "Empty stream") s 0 -> Lwt.fail Lwt_stream.Empty 
      | Failure s as o -> Lwt.return @@ Some o
      | Success s as o -> Lwt.return @@ Some o ) 

let send t ?(expect=Any) str = 
  let (>>=) = Lwt.bind in 
  Lwt_stream.junk_old t.stream 
  >>= fun () -> Lwt_io.write_line t.writer str 
  >>= fun () -> next_line {t with stream = Lwt_io.read_lines t.reader} ~expect

let spawn process = 
  let read, write = Unix.open_process process in 
  let lwt_read = 
    Lwt_io.of_unix_fd 
      ~close:(fun () -> Lwt.return @@ ignore (Unix.close_process (read, write)))
      ~mode:Lwt_io.Input 
     (Unix.descr_of_in_channel read) in 
  let lwt_write = 
    Lwt_io.of_unix_fd ~mode:Lwt_io.Output (Unix.descr_of_out_channel write) in 
  Lwt.return { 
    reader = lwt_read; writer = lwt_write;
    stream = Lwt_stream.from_direct (fun () -> None);
    status = Success "Process started"; 
  }  

let close t = Lwt_io.close t.reader 
