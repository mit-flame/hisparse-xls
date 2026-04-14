pub proc example {

    addr:       chan<u32> out;
    pld:        chan<u32> in;

    config(addr: chan<u32> out, pld: chan<u32> in) { (addr, pld) }
    
    init{(u32: 0, token())}
    
    next (state: (u32, token)) {
      let new_state = 
      match (state.0) {
        u32: 0 => { u32: 1 },
        u32: 1 => { u32: 2},
        _ => {state.0}
      };
      let new_tok = send_if(state.1, addr, state.0 == u32: 0, u32: 0);
      let (new_tok, _) = recv_if(new_tok, pld, state.0 == u32: 0, u32: 0);
      let new_tok = send_if(new_tok, addr, state.0 == u32: 1, u32: 0);
      let (new_tok, _) = recv_if(new_tok, pld, state.0 == u32: 1, u32: 0);
      (new_state, new_tok)
    }
}