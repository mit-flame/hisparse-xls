import vector_helper;

pub proc vba_recv{

    streaming_pld:              chan<vector_helper::StreamPayload> in;
    payload_type_three:         chan<uN[96]> out;

    config(
        streaming_pld:              chan<vector_helper::StreamPayload> in,
        payload_type_three:         chan<uN[96]> out
    ) {
        (
            streaming_pld, payload_type_three
        )
    }

    init {
        token()
    }

    next(tok: token) {
        let (new_tok, spld) = recv(tok, streaming_pld);
        let opld = if (spld.commands != u2: 0) { spld.commands ++ uN[94]: 0 } else { u2: 0 ++ spld.row_index ++ spld.vector ++ spld.matrix_pld };
        (send(new_tok, payload_type_three, opld))
    }
}