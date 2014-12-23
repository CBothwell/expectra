type status = 
  | Success of string 
  | Failure of exn 

type matches = 
  | Begins of string
  | Ends of string
  | Function of (string -> status) 
  | Any 

type t = {
  reader: Lwt_io.input Lwt_io.channel;
  writer: Lwt_io.output Lwt_io.channel; 
  stream: string Lwt_stream.t; 
  status: status; 
}

let get_status t = t.status  

let set_status t status = {t with status = status}

let expect_match line = function
  | Begins regx -> begin 
    let re = Str.regexp regx in 
    try ignore(Str.search_forward re line 0); Success (Str.matched_string line) 
    with Not_found -> Failure Not_found 
  end 
  | Ends regx -> begin
    let re = Str.regexp regx in 
    try ignore(Str.search_backward re line 0); Success (Str.matched_string line)
    with Not_found -> Failure Not_found 
  end
  | Function f -> f line 
  | Any -> Success line 
 
let next_line ?(expect=Any) t = 
  let (>>=) = Lwt.bind in 
  try Lwt_stream.next t.stream
    >>= fun line -> 
      Lwt.return {t with status = expect_match line expect}
  with Lwt_stream.Empty -> 
    Lwt.return {t with status = Failure Lwt_stream.Empty}

let stream ?(expect=Any) t = 
  let f line = 
    match expect_match line expect with  
    | Success _ -> true 
    | Failure _ -> false
  in
  Lwt_stream.filter f t.stream  

let send t ?(expect=Any) str = 
  let (>>=) = Lwt.bind in 
  Lwt_stream.junk_old t.stream 
  >>= fun () -> Lwt_io.write_line t.writer str 
  >>= fun () -> next_line {t with stream = Lwt_io.read_lines t.reader} ~expect

let create_pts ptm = 
  let open Ctypes in 
  let open PosixTypes in 
  let open Foreign in 
  let pts_view = Ctypes.view 
     ~read:Fd_send_recv.fd_of_int
     ~write:Fd_send_recv.int_of_fd Ctypes.int 
  in 
  let ptsname = foreign ~check_errno:true "ptsname" (pts_view @-> returning string_opt) in 
  let grantpt = foreign ~check_errno:true "grantpt" (pts_view @-> returning int) in 
  let unlockpt = foreign ~check_errno:true "unlockpt" (pts_view @-> returning int) in 
  let make_pts f = if (grantpt ptm = 0) && (unlockpt ptm = 0) 
  (* here we're measuring equality, not assignment *)
    then Unix.(openfile f [O_RDWR] 0o620) 
    else raise Not_found 
  in 
  match ptsname ptm with 
  | None -> raise Not_found
  | Some f -> make_pts f 

let spawn process = 
  let executeable, args = 
    let strls = Str.(split (regexp "[ \t]+") process) in 
    (List.hd strls, Array.of_list strls)
  in 
  let ptm = Unix.(openfile "/dev/ptmx" [O_RDWR] 0o620) in 
  let pts = try create_pts ptm with Not_found -> Printf.printf "Failed to get a pty"; exit 0 in 
  let lwt_read = Lwt_io.of_unix_fd ~mode:Lwt_io.Input ptm in 
  let lwt_write = Lwt_io.of_unix_fd ~mode:Lwt_io.Output ptm in 
  ignore @@ Unix.create_process executeable args pts pts pts;
  Lwt.return { 
    reader = lwt_read; writer = lwt_write;
    stream = Lwt_io.read_lines lwt_read;
    status = Success "Process started"; 
  }  

let close t = ignore @@ Lwt_io.close t.reader; Lwt.return t  
