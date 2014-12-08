# Expectra

#### Automate interactive programs with OCaml 

This is a small expect like library intended to be used primarily for 
interacting with Linode's Lish shell. That does not preclude it from 
working with other such interactive programs. 

The library is designed mostly to be fun to use, it relies on the Lwt
cooperative thread frame work to handle interacting with an interactive program. 

```ocaml 
let result = let open Lwt in 
  Expectra.spawn "telnet google.com 80" 
  >>= fun ex -> Expectra.send ex "GET / HTTP/1.1\n\n" ~expect:(Expectra.BeginsWith "Trying.*")
  >>= fun ex -> 
    match Expectra.get_status ex with 
    | Success st -> Expect.send ex "GET /mail HTTP/1.1\n\n" 
    | Failure st -> Expect.sned ex "GET /about HTTP/1.1\n\n" 

let output = Let open Lwt in 
  result >>= fun x -> match Expectra.get_status x with 
    | Success st -> st
    | Failure st -> st 
```
