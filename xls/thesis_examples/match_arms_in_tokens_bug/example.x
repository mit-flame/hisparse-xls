pub proc example {

    addr:       chan<u32> out;
    pld:        chan<u32> in;

    config(addr: chan<u32> out, pld: chan<u32> in) { (addr, pld) }
    
    init{(u32: 0, token())}
    
    next (state: (u32, token)) {
        match (state.0) {
          u32:0 => {
            let new_tok = send(state.1, addr, u32: 0);
            let (new_tok, _) = recv(new_tok, pld);
            (u32: 1, new_tok)
          },
          u32:1 => {
            let new_tok = send(state.1, addr, u32: 0);
            let (new_tok, _) = recv(new_tok, pld);
            (u32: 2, new_tok)
          },
          _ => {
            state
          },
        }
    }
}