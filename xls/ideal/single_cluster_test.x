import matrix_loader;
import vector_loader;
import vector_unpacker;
import vector_buffer_access_unit;
import shuffler;
import pe;
import cluster_packer;
import clusters_results_merger;
import kernels_results_merger;

// test acts as both the HBM source for the input matrix and vector buffer,
// as well as the HBM source for the output buffer. Finally, test will
// consume the result vector as well. Overall, test represents what composes
// a single cluster and how to run it

// two stream 8x8 matrix 2x2 partition test
// with a length 8 vector as well, vector and output banks are 2 long
// to create vector buffers and output buffers that are 4 in size each
// (to necessitate the 2x2 partitions to begin with). IFWQ depth is 5

// one cluster and one kernel
#[test_proc]
proc Tester {
    terminator: chan<bool> out;

    // running the VL
    hbm_vector_payload:             chan<u32[u32: 2]>      out;
    hbm_vector_addr:                chan<u32>               in;
    num_matrix_cols:                chan<u32>              out;

    // running the VAU
    vau_num_col_partitions:         chan<u32>[u32: 2] out; // (this is literally the same info as the ML)
    vecbuf_bank_addr:               chan<u32>[u32: 2]        in;
    vecbuf_dout:                    chan<u32>[u32: 2]        in;
    vecbuf_din:                     chan<u32>[u32: 2]       out;
    
    // running the ML
    payload_type_one:           chan<uN[64][u32: 2]> out;
    payload_type_one_index:     chan<u32> in;
    cur_row_partition:          chan<u32> out;
    mat_num_col_partitions:         chan<u32> out;
    tot_num_partitions:         chan<u32> out;

    // running both PEs
    cluster_vecbuf_bank_addr:               chan<u32>[u32: 2] in;
    cluster_vecbuf_bank_din:               chan<u32>[u32: 2]  out;
    cluster_vecbuf_bank_dout:              chan<u32>[u32: 2] in;
    cluster_num_rows_updated:               chan<u30>[u32: 2] out;      // sampled once every row partition
    cluster_stream_id:                      chan<u32>[u32: 2] out;

    // kernels_results_merger channels
    current_row_partition:                      chan<u32>   out;
    num_hbm_channels_each_kernel:               chan<u32[u32: 1]>  out;

    // output tap for the test
    output_buffer_hbm_vector_addr:                            chan<u32>   in;
    output_buffer_hbm_vector_payload:                         chan<u32[u32: 2]>  in;

    // the config necessary
    config(
        terminator: chan<bool> out,
    ){
        // ML to first shuffle unit output
        let (ptype1_out, ptype1_in) = chan<uN[64][2]>("ml_payload_type_one_channel");
        let (ptype1_index_out, ptype1_index_in) = chan<u32>("ml_payload_type_one_index_channel");
        let (crp_out, crp_in) = chan<u32>("ml_current_row_partition_channel");
        let (mncp_out, mncp_in) = chan<u32>("ml_num_col_partition_channel");
        let (tnp_out, tnp_in) = chan<u32>("ml_tot_num_partitions_channel");
        let (ptype2_out, ptype2_in) = chan<uN[96]>[u32: 2]("ml_payload_type_two_channel");
        let (sf_ptype2_out, sf_ptype2_in) = chan<uN[96]>[u32: 2]("sf_payload_type_two_channel");
        spawn matrix_loader::matrix_loader<u32: 2>(ptype1_in, ptype1_index_out, crp_in, mncp_in, tnp_in, ptype2_out);
        spawn shuffler::shuffler<u32: 2>(ptype2_in, sf_ptype2_out);

        // VL to VAU output
        let (hvpo, hvpi) = chan<u32[u32: 2]>("hvp");
        let (hvao, hvai) = chan<u32>("hva");
        let (nmco, nmci) = chan<u32>("nmc");
        let (vpoo, vpoi) = chan<uN[96]>[u32: 1]("vpo");
        spawn vector_loader::vector_loader<u32: 1, u32: 2, u32: 4>(hvpi, hvao, nmci, vpoo);
        let (mvpto, mvpti) = chan<uN[64]>[u32: 2]("mvpt");
        spawn vector_unpacker::vector_unpacker<u32: 2>(vpoi[0], mvpto);
        let (vncpo, vncpi) = chan<u32>[u32: 2]("vncp");

        let (mvbao, mvbai) = chan<u32>[u32: 2]("mvba");
        let (mvdoo, mvdoi) = chan<u32>[u32: 2]("mvdo");
        let (mvdio, mvdii) = chan<u32>[u32: 2]("mvdi");

        let (mptto, mptti) = chan<uN[96]>[u32: 2]("mptt"); // multistream payload type three
        spawn vector_buffer_access_unit::vecbuf_access_unit<u32: 2, u32: 2>(sf_ptype2_in[0], mvpti[0], vncpi[0], mvbao[0], mvdoo[0], mvdii[0], mptto[0]);
        spawn vector_buffer_access_unit::vecbuf_access_unit<u32: 2, u32: 2>(sf_ptype2_in[1], mvpti[1], vncpi[1], mvbao[1], mvdoo[1], mvdii[1], mptto[1]);

        // final shuffler out. I can use the same shuffler since the index is in the same spot bitwise
        let (sf_pt3_out, sf_pt3_in) = chan<uN[96]>[u32: 2]("sf_pt3");
        spawn shuffler::shuffler<u32: 2>(mptti, sf_pt3_out);

        // SF to PE (the c stands for cluster)
        let (cvbao, cvbai) = chan<u32>[u32: 2]("vba");
        let (cvbdio, cvbdii) = chan<u32>[u32: 2]("cvbdi");
        let (cvbdoo, cvbdoi) = chan<u32>[u32: 2]("cvbdi");
        let (cnruo, cnrui) = chan<u30>[u32: 2]("cnru");
        let (csio, csii) = chan<u32>[u32: 2]("csi");
        let (cpt4o, cpt4i) = chan<uN[64]>[u32: 2]("cpt4");
        spawn pe::processing_engine<u32: 2, u32: 2, u32: 5>(sf_pt3_in[0], cvbao[0], cvbdii[0], cvbdoo[0], cnrui[0], csii[0], cpt4o[0]);
        spawn pe::processing_engine<u32: 2, u32: 2, u32: 5>(sf_pt3_in[1], cvbao[1], cvbdii[1], cvbdoo[1], cnrui[1], csii[1], cpt4o[1]);

        // PEs to cluster packer (cluster packer vector payload is the acronym)
        // only one cluster but this still must be an array
        let (cpvpoo, cpvpoi) = chan<uN[96]>[u32: 1]("cpvpo");
        spawn cluster_packer::cluster_packer<u32: 2>(cpt4i, cpvpoo[0]);

        // cluster packer to clusters results merger (cr is cluster results)
        let (crvpoo, crvpoi) = chan<uN[96]>[u32: 1]("crvpo");
        spawn clusters_results_merger::clusters_results_merger<u32: 1, u32: 2>(cpvpoi, crvpoo[0]);

        // cluster results merger to kernels results merger
        let (krpo, krpi) = chan<u32>("krp");
        let (nhceko, nhceki) = chan<u32[u32: 1]>("nhcek");
        let (krhvao, krhvai) = chan<u32>("krhva");
        let (krhvpo, krhvpi) = chan<u32[u32: 2]>("krhvp"); 
        
        spawn kernels_results_merger::kernels_results_merger<u32: 1, u32: 2, u32: 2>(krpi, nhceki, crvpoi, krhvao, krhvpo);
        (
            // for the test case
            terminator,
            // for the VL
            hvpo, hvai, nmco,
            // for the VAU
            vncpo, mvbai, mvdoi, mvdio,
            // for the ML
            ptype1_out, ptype1_index_in, crp_out, mncp_out, tnp_out,
            // for both PEs
            cvbai, cvbdio, cvbdoi, cnruo, csio,
            // for the kernel results merger
            krpo, nhceko,
            // finally, the output
            krhvai, krhvpi
        )
    }

    init {(
    )}

    // a 8x8 matrix split into 2x2 partitions
    // [[1, 0, 2, 0,     0, 0, 0, 0],
    //  [0, 0, 0, 0,     0, 0, 0, 0],
    //  [0, 0, 0, 0,     3, 0, 4, 0],
    //  [0, 0, 0, 0,     5, 0, 0, 6],
    //
    //  [7, 0, 0, 0,     0, 2, 4, 6],
    //  [8, 0, 0, 0,     0, 3, 5, 7],
    //  [9, 0, 0, 0,     0, 0, 8, 0],
    //  [1, 0, 0, 0,     0, 0, 9, 0]]
    //
    // paired with a len 8 vector: [ 0
    //                               1
    //                               2
    //                               3
    //                               4
    //                               5
    //                               6
    //                               7
    //                               8 ]

    next(tester_state: ()) {
        // mock memory banks for both vector buffer access units
        let vau0_bank = zero!<u32[u32: 2]>();
        let vau1_bank = zero!<u32[u32: 2]>();
        // mock memory banks for both PEs <--- left off here
        let pe0_bank = zero!<u32[u32: 2]>();
        let pe1_bank = zero!<u32[u32: 2]>();

        // toplevel row info handshake for everything
        let tok1 = send(join(), cur_row_partition, u32: 0);
        let tok2 = send(join(), mat_num_col_partitions, u32: 2);
        let tok3 = send(join(), tot_num_partitions, u32: 4);
        let tok4 = send(join(), num_matrix_cols, u32: 8);
        let tok5 = send(join(), vau_num_col_partitions[0], u32: 2); // notice its the same as ML
        let tok6 = send(join(), vau_num_col_partitions[1], u32: 2); // notice its the same as ML
        let tok7 = for (idx, tok):(u32, token) in u32:0..u32:2{send(tok, cluster_num_rows_updated[idx], u30: 2)}(join());
        let tok8 = for (idx, tok):(u32, token) in u32:0..u32:2{send(tok, cluster_stream_id[idx], idx)}(join());
        let tok9 = send(join(), current_row_partition, u32: 0);
        let tok10 = send(join(), num_hbm_channels_each_kernel, [u32: 1]);

        trace_fmt!("sending row info");
        let tok = join(tok1, tok2, tok3, tok4, tok5, tok6, tok7, tok8, tok9, tok10);

        // every row involves clearing of PE banks
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);

        // PART 1------------------------------------------------------
        // VL/VAU partition loading
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 1 , u32: 0]); // for now, you need to put the elements in reverse order

        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let (tok, data_one) = recv(tok, vecbuf_dout[0]);
        let (tok, data_two) = recv(tok, vecbuf_dout[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one[0+:u30] as u32, data_one);
        let vau1_bank = update(vau1_bank, cmd_addr_two[0+:u30] as u32, data_two);

        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 3 , u32: 2]);

        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let (tok, data_one) = recv(tok, vecbuf_dout[0]);
        let (tok, data_two) = recv(tok, vecbuf_dout[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one[0+:u30] as u32, data_one);
        let vau1_bank = update(vau1_bank, cmd_addr_two[0+:u30] as u32, data_two);

        trace_fmt!("VAU BANKS: {:0x} {:0x}", vau0_bank, vau1_bank);
        
        // per matrix partition metadata handshake
        let (tok, requested_index) = recv(tok, payload_type_one_index);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let start_of_partition = [u32: 0 ++ u32: 0, u32: 0 ++ u32: 0];
        let tok = send(tok, payload_type_one, start_of_partition);
        let (tok, requested_index) = recv(tok, payload_type_one_index);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let stream_length_payload = [u32: 3 ++ u32: 0, u32: 1 ++ u32: 0];
        let tok = send(tok, payload_type_one, stream_length_payload);
        // start of partition, buffer all the matrix sends first
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let pld = [u32: 0 ++ u32: 1, all_ones!<u32>() ++ u32: 1];
        let tok = send(tok, payload_type_one, pld);

        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let pld = [u32: 2 ++ u32: 2, zero!<u64>()];
        let tok = send(tok, payload_type_one, pld);

        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let pld = [all_ones!<u32>() ++ u32: 1, zero!<u64>()];
        let tok = send(tok, payload_type_one, pld);

        // then deal with the VAU after buffering matrix sends until VAU is not blocked on the "din" channel
        // (the number can be calculated beforehand but this is an easy way to do it as well)
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);

        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        // PART 1------------------------------------------------------

        // try to make this as streamlined as possible
        // PART 2------------------------------------------------------
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 5 , u32: 4]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let (tok, data_one) = recv(tok, vecbuf_dout[0]);
        let (tok, data_two) = recv(tok, vecbuf_dout[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one[0+:u30] as u32, data_one);
        let vau1_bank = update(vau1_bank, cmd_addr_two[0+:u30] as u32, data_two);
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 7 , u32: 6]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let (tok, data_one) = recv(tok, vecbuf_dout[0]);
        let (tok, data_two) = recv(tok, vecbuf_dout[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one[0+:u30] as u32, data_one);
        let vau1_bank = update(vau1_bank, cmd_addr_two[0+:u30] as u32, data_two);
        trace_fmt!("VAU BANKS: {:0x} {:0x}", vau0_bank, vau1_bank);
        let (tok, requested_index) = recv(tok, payload_type_one_index);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, payload_type_one, [u32: 3 ++ u32: 0, u32: 0 ++ u32: 0]);
        let (tok, requested_index) = recv(tok, payload_type_one_index);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, payload_type_one, [u32: 3 ++ u32: 0, u32: 3 ++ u32: 0]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [all_ones!<u32>() ++ u32: 1, all_ones!<u32>() ++ u32: 1]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [u32: 0 ++ u32: 3, u32: 0 ++ u32: 5]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [u32: 2 ++ u32: 4, u32: 3 ++ u32: 6]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let tok = send(tok, vecbuf_din[1], vau1_bank[cmd_addr_two[0+:u30] as u32]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        // PART 2------------------------------------------------------
        // row change stuff:
        // finally unblocking the PEs and sampling the output (this is done on a per row/EOS basis)
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        //
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        //--
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        //
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        //--
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);

        // symmetry stopped
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        
        // finally read the results
        let (tok, output_addr) = recv(tok, output_buffer_hbm_vector_addr);
        trace_fmt!("requested write out addr: {:0x}", output_addr);
        let (tok, output_pld) = recv(tok, output_buffer_hbm_vector_payload);
        trace_fmt!("requested write out payload: {:0x}", output_pld);

        let (tok, output_addr) = recv(tok, output_buffer_hbm_vector_addr);
        trace_fmt!("requested write out addr: {:0x}", output_addr);
        let (tok, output_pld) = recv(tok, output_buffer_hbm_vector_payload);
        trace_fmt!("requested write out payload: {:0x}", output_pld);

        // new row required sends
        let tok1 = send(join(), cur_row_partition, u32: 1);
        let tok2 = send(join(), mat_num_col_partitions, u32: 2);
        let tok3 = send(join(), tot_num_partitions, u32: 4);
        let tok4 = send(join(), num_matrix_cols, u32: 8);
        let tok5 = send(join(), vau_num_col_partitions[0], u32: 2);
        let tok6 = send(join(), vau_num_col_partitions[1], u32: 2);
        let tok7 = for (idx, tok):(u32, token) in u32:0..u32:2{send(tok, cluster_num_rows_updated[idx], u30: 2)}(join());
        let tok8 = for (idx, tok):(u32, token) in u32:0..u32:2{send(tok, cluster_stream_id[idx], idx)}(join());
        let tok9 = send(join(), current_row_partition, u32: 1);
        let tok10 = send(join(), num_hbm_channels_each_kernel, [u32: 1]);
        trace_fmt!("sending row info");
        let tok = join(tok1, tok2, tok3, tok4, tok5, tok6, tok7, tok8, tok9, tok10);
        // every row involves clearing of PE banks
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);

        // PART 3------------------------------------------------------
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 1 , u32: 0]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let (tok, data_one) = recv(tok, vecbuf_dout[0]);
        let (tok, data_two) = recv(tok, vecbuf_dout[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one[0+:u30] as u32, data_one);
        let vau1_bank = update(vau1_bank, cmd_addr_two[0+:u30] as u32, data_two);
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 3 , u32: 2]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let (tok, data_one) = recv(tok, vecbuf_dout[0]);
        let (tok, data_two) = recv(tok, vecbuf_dout[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one[0+:u30] as u32, data_one);
        let vau1_bank = update(vau1_bank, cmd_addr_two[0+:u30] as u32, data_two);
        trace_fmt!("VAU BANKS: {:0x} {:0x}", vau0_bank, vau1_bank);
        let (tok, requested_index) = recv(tok, payload_type_one_index);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, payload_type_one, [u32: 6 ++ u32: 0, u32: 0 ++ u32: 0]);
        let (tok, requested_index) = recv(tok, payload_type_one_index);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, payload_type_one, [u32: 3 ++ u32: 0, u32: 3 ++ u32: 0]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [u32: 0 ++ u32: 7, u32: 0 ++ u32: 8]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [all_ones!<u32>() ++ u32: 1, all_ones!<u32>() ++ u32: 1]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [u32: 0 ++ u32: 9, u32: 0 ++ u32: 1]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        // PART 3------------------------------------------------------

        // PART 4------------------------------------------------------
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 5 , u32: 4]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let (tok, data_one) = recv(tok, vecbuf_dout[0]);
        let (tok, data_two) = recv(tok, vecbuf_dout[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one[0+:u30] as u32, data_one);
        let vau1_bank = update(vau1_bank, cmd_addr_two[0+:u30] as u32, data_two);
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 7 , u32: 6]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let (tok, data_one) = recv(tok, vecbuf_dout[0]);
        let (tok, data_two) = recv(tok, vecbuf_dout[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one[0+:u30] as u32, data_one);
        let vau1_bank = update(vau1_bank, cmd_addr_two[0+:u30] as u32, data_two);
        trace_fmt!("VAU BANKS: {:0x} {:0x}", vau0_bank, vau1_bank);
        let (tok, requested_index) = recv(tok, payload_type_one_index);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, payload_type_one, [u32: 9 ++ u32: 0, u32: 0 ++ u32: 0]);
        let (tok, requested_index) = recv(tok, payload_type_one_index);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, payload_type_one, [u32: 5 ++ u32: 0, u32: 5 ++ u32: 0]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [u32: 1 ++ u32: 2, u32: 1 ++ u32: 3]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [u32: 2 ++ u32: 4, u32: 2 ++ u32: 5]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [u32: 3 ++ u32: 6, u32: 3 ++ u32: 7]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [all_ones!<u32>() ++ u32: 1, all_ones!<u32>() ++ u32: 1]);
        let (tok, req_i) = recv(tok, payload_type_one_index);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, payload_type_one, [u32: 2 ++ u32: 8, u32: 2 ++ u32: 9]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let tok = send(tok, vecbuf_din[1], vau1_bank[cmd_addr_two[0+:u30] as u32]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let tok = send(tok, vecbuf_din[1], vau1_bank[cmd_addr_two[0+:u30] as u32]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let tok = send(tok, vecbuf_din[1], vau1_bank[cmd_addr_two[0+:u30] as u32]);
        let (tok, cmd_addr_one) = recv(tok, vecbuf_bank_addr[0]);
        let tok = send(tok, vecbuf_din[0], vau0_bank[cmd_addr_one[0+:u30] as u32]);
        let (tok, cmd_addr_two) = recv(tok, vecbuf_bank_addr[1]);
        let tok = send(tok, vecbuf_din[1], vau1_bank[cmd_addr_two[0+:u30] as u32]);
        // PART 4------------------------------------------------------
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        //
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        //--
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        //
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        //--
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        //
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        //--
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        //
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        //--
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        //
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        //--
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        //
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let (tok, pe0update) = recv(tok, cluster_vecbuf_bank_dout[0]);
        let pe0_bank = update(pe0_bank, pe0reqaddr[0+:u30], pe0update);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let (tok, pe1update) = recv(tok, cluster_vecbuf_bank_dout[1]);
        let pe1_bank = update(pe1_bank, pe1reqaddr[0+:u30], pe1update);
        //--
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);
        let (tok, pe0reqaddr) = recv(tok, cluster_vecbuf_bank_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[0], pe0_bank[pe0reqaddr[0+:u30]]);
        let (tok, pe1reqaddr) = recv(tok, cluster_vecbuf_bank_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, cluster_vecbuf_bank_din[1], pe1_bank[pe1reqaddr[0+:u30]]);

        let (tok, output_addr) = recv(tok, output_buffer_hbm_vector_addr);
        trace_fmt!("requested write out addr: {:0x}", output_addr);
        let (tok, output_pld) = recv(tok, output_buffer_hbm_vector_payload);
        trace_fmt!("requested write out payload: {:0x}", output_pld);
        let (tok, output_addr) = recv(tok, output_buffer_hbm_vector_addr);
        trace_fmt!("requested write out addr: {:0x}", output_addr);
        let (tok, output_pld) = recv(tok, output_buffer_hbm_vector_payload);
        trace_fmt!("requested write out payload: {:0x}", output_pld);
        // let (tok, p2_one) = recv(tok, sf_out[0]);
        // let (tok, p2_two) = recv(tok, sf_out[1]);
        // trace_fmt!("p2 one  EOS: {:0x}", p2_one);
        // trace_fmt!("p2 two  EOS: {:0x}", p2_two);
        let tok = send(tok, terminator, true);
        trace_fmt!("done");
        tester_state
    }
}