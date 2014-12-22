# Expectra

#### Automate interactive programs with OCaml 

This is a small expect like library intended to be used primarily for 
interacting with Linode's Lish shell. That does not preclude it from 
working with other such interactive programs. 

The library is designed mostly to be fun to use, it relies on the Lwt
cooperative thread framework to handle interacting with an interactive program. 

```ocaml 
# let (>>=) = Lwt.bind;; 

# let result = Expectra.spawn "telnet google.com 80" 
    >>= fun ex -> Expectra.send ex "GET / HTTP/1.1\n\n" 
    >>= fun ex -> let strm = Expectra.stream ex ~expect:(Expectra.Begins "SAME") in 
      let locate = Lwt_stream.find (fun a -> match a with Expectra.Success a -> true | Expectra.Failure a -> false) strm in 
      (locate >>= function Some _ -> Lwt.return ex | None -> Lwt.fail Not_found)
    >>= fun ex -> Expectra.send ex "GET /mail HTTP/1.1\n\n" 
    >>= fun ex -> let strm = Expectra.stream ex ~expect:(Expectra.Begins "301 Moved") in 
      let locate = Lwt_stream.find (fun a -> match a with Expectra.Success _ -> true | Expectra.Failure _ -> false) strm in 
      locate;;

val result : Expectra.status option Lwt.t = <abstr> 

# result;;
- : Expectra.status option = Some (Expectra.Success "301 Moved")

# let result = Expectra.spawn "telnet google.com 80" 
    >>= fun ex -> Expectra.send ex "GET / HTTP/1.1\n\n" 
    >>= fun ex -> let strm = Expectra.stream ex ~expect:(Expectra.Begins "donkey") in 
      let locate = Lwt_stream.find (fun a -> match a with Expectra.Success a -> true | Expectra.Failure a -> false) strm in 
      (locate >>= function Some _ -> Lwt.return ex | None -> Lwt.fail Not_found)
    >>= fun ex -> Expectra.send ex "GET /mail HTTP/1.1\n\n" 
    >>= fun ex -> let strm = Expectra.stream ex ~expect:(Expectra.Begins "301 Moved") in 
      let locate = Lwt_stream.find (fun a -> match a with Expectra.Success _ -> true | Expectra.Failure _ -> false) strm in 
      locate;;

val result : Expectra.status option Lwt.t = <abstr> 

# result;;
Exception: Not_found.                            

(* or more simply *) 
# let locate ex strm =  Lwt_stream.find (function Expectra.Success _ -> true | Expectra.Failure _ -> false) strm
    >>= function Some s -> Lwt.return (Expectra.set_status ex s) | None -> Lwt.fail Not_found ;;

# let result = Expectra.spawn "telnet google.com 80" 
    >>= fun ex -> Expectra.send ex "GET / HTTP/1.1\n\n"
    >>= fun ex -> Expectra.stream ex ~expect:(Expectra.Begins "SAME") |> locate ex 
    >>= fun ex -> Expectra.send ex "GET /mail HTTP/1.1\n\n" 
    >>= fun ex -> Expectra.stream ex ~expect:(Expectra.Begins ".*301.*") |> locate ex 
    >>= fun ex -> Expectra.close ex
    >>= fun ex -> Expectra.get_status ex |> Lwt.return ;;
val result : Expectra.status Lwt.t = <abstr> 

# result;;
- : Expectra.status = Expectra.Success "HTTP/1.1 301 Moved Permanently" 


```
