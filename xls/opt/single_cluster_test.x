import matrix_helper;
import matrix_loader_recv;
import matrix_loader_send;
import matrix_loader_addr_arbiter;
import matrix_loader_pld_arbiter;
import vector_loader;
import vector_unpacker;
import vector_helper;
import vba_recv;
import vba_send;
import vba_addr_arbiter;
import generic_syncer;
import shuffler_core;
import arbiter_helper;
import arbiter;
import pe_helper;
import pe_send;
import pe_recv;
import pe_addr_arbiter;
import cluster_packer;
import clusters_results_merger;
import kernels_results_merger;

// same test as ml_vl_row_sf_pe_drain, but uses the codegen versions of the files


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
    vau_num_col_partitions:         chan<u32>[u32: 2]       out; // (this is literally the same info as the ML)
    vba_unified_addr:               chan<vector_helper::StreamAddr>[u32: 2] in;
    vba_streaming_pld:              chan<vector_helper::StreamPayload>[u32: 2] out;
    
    // running the ML
    ml_unified_addr:            chan<matrix_helper::StreamAddr> in;
    ml_unified_pld:             chan<matrix_helper::StreamPayload<u32: 2>> out;
    cur_row_partition:          chan<u32> out;
    mat_num_col_partitions:     chan<u32> out;
    tot_num_partitions:         chan<u32> out;

    // running both PEs
    pe_num_rows_updated:                    chan<u30>[u32: 2] out;      // sampled once every row partition
    pe_stream_id:                           chan<u32>[u32: 2] out;      // sampled once every row partition
    pe_unified_addr:                        chan<pe_helper::StreamAddr>[u32: 2] in;
    pe_unified_pld:                         chan<pe_helper::StreamPayload>[u32: 2] out;
    pe_accumulation_addr:                   chan<pe_helper::StreamAddr>[u32: 2] in;

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
        let (metadata_out, metadata_in) = chan<matrix_helper::StreamPayload<u32: 2>>("ml_metadata_pld");
        let (metadata_addr_out, metadata_addr_in) = chan<matrix_helper::StreamAddr>("ml_metadata_addr");
        let (streaming_addr_out, streaming_addr_in) = chan<matrix_helper::StreamAddr>("ml_stream_addr");
        let (stream_payload_out, stream_payload_in) = chan<matrix_helper::StreamPayload<u32: 2>>("ml_stream_payload");
        let (ml_unified_addr_out, ml_unified_addr_in) = chan<matrix_helper::StreamAddr>("ml_unified_addr");
        let (ml_unified_pld_out, ml_unified_pld_in) = chan<matrix_helper::StreamPayload<u32: 2>>("ml_unified_pld");
        spawn matrix_loader_addr_arbiter::matrix_loader_addr_arbiter(metadata_addr_in, streaming_addr_in, ml_unified_addr_out);
        spawn matrix_loader_pld_arbiter::matrix_loader_pld_arbiter<u32: 2>(ml_unified_pld_in, metadata_out, stream_payload_out);
        let (crp_out, crp_in) = chan<u32>("ml_current_row_partition_channel");
        let (mncp_out, mncp_in) = chan<u32>("ml_num_col_partition_channel");
        let (tnp_out, tnp_in) = chan<u32>("ml_tot_num_partitions_channel");
        spawn matrix_loader_send::matrix_loader_send<u32: 2>(metadata_addr_out, metadata_in, streaming_addr_out, crp_in, mncp_in, tnp_in);
        let (ptype2_out, ptype2_in) = chan<uN[96]>[u32: 2]("ml_payload_type_two_channel");
        spawn matrix_loader_recv::matrix_loader_recv<u32: 2>(stream_payload_in, ptype2_out);
        let (syncout, syncin) = chan<uN[96]>[u32: 2]("sync_sod_sfone");
        spawn generic_syncer::generic_syncer<u32: 2, u2: 1>(ptype2_in, syncout);
        let (eossyncout, eossyncin) = chan<uN[96]>[u32: 2]("sync_eos_sfone");
        spawn generic_syncer::generic_syncer<u32: 2, u2: 1>(syncin, eossyncout);
        let (sf_ptype2_out, sf_ptype2_in) = chan<uN[96]>[u32: 2]("sf_payload_type_two_channel");
        let (aptto, aptti) = chan<uN[96][u32: 2]>("arbiter_aptt");
        let (aivo, aivi) = chan<u1[u32: 2]>("arbiter_aiv");
        let (aroo, aroi) = chan<u32>("arbiter_aro");
        let (aco, aci) = chan<arbiter_helper::ArbOut<u32: 2>>("ac");
        spawn shuffler_core::shuffler_core<u32: 2, u32: 8>(
            eossyncin, sf_ptype2_out,
            aptto, aivo, aroo, aci
        );
        spawn arbiter::arbiter_wrapper<u32: 2>(aptti, aivi, aroi, aco);

        // VL to VAU output
        let (hvpo, hvpi) = chan<u32[u32: 2]>("hvp");
        let (hvao, hvai) = chan<u32>("hva");
        let (nmco, nmci) = chan<u32>("nmc");
        let (vpoo, vpoi) = chan<uN[96]>[u32: 1]("vpo");
        spawn vector_loader::vector_loader<u32: 1, u32: 2, u32: 4>(hvpi, hvao, nmci, vpoo);
        let (mvpto, mvpti) = chan<uN[64]>[u32: 2]("mvpt");
        spawn vector_unpacker::vector_unpacker<u32: 2>(vpoi[0], mvpto);
        let (vncpo, vncpi) = chan<u32>[u32: 2]("vncp");

        let (vba_la_out, vba_la_in) = chan<vector_helper::StreamAddr>[u32: 2]("vbala");
        let (vba_sa_out, vba_sa_in) = chan<vector_helper::StreamAddr>[u32: 2]("vbasa");
        spawn vba_send::vba_send<u32:2, u32: 2>(sf_ptype2_in[0], mvpti[0], vncpi[0], vba_la_out[0], vba_sa_out[0]);
        spawn vba_send::vba_send<u32:2, u32: 2>(sf_ptype2_in[1], mvpti[1], vncpi[1], vba_la_out[1], vba_sa_out[1]);
        let (vba_unified_addr_out, vba_unified_addr_in) = chan<vector_helper::StreamAddr>[u32: 2]("vba_unified");
        spawn vba_addr_arbiter::vba_addr_arbiter(vba_la_in[0], vba_sa_in[0], vba_unified_addr_out[0]);
        spawn vba_addr_arbiter::vba_addr_arbiter(vba_la_in[1], vba_sa_in[1], vba_unified_addr_out[1]);
        let (vba_streaming_pld_out, vba_streaming_pld_in) = chan<vector_helper::StreamPayload>[u32: 2]("vba_streaming");
        let (mptto, mptti) = chan<uN[96]>[u32: 2]("mptt"); // multistream payload type three
        spawn vba_recv::vba_recv(vba_streaming_pld_in[0], mptto[0]);
        spawn vba_recv::vba_recv(vba_streaming_pld_in[1], mptto[1]);

        // final shuffler out. I can use the same shuffler since the index is in the same spot bitwise
        let (syncout, syncin) = chan<uN[96]>[u32: 2]("sync_sod_sftwo");
        spawn generic_syncer::generic_syncer<u32: 2, u2: 1>(mptti, syncout);
        let (eossyncout, eossyncin) = chan<uN[96]>[u32: 2]("sync_eos_sfone");
        spawn generic_syncer::generic_syncer<u32: 2, u2: 1>(syncin, eossyncout);
        let (sf_pt3_out, sf_pt3_in) = chan<uN[96]>[u32: 2]("sf_pt3");
        let (aptto, aptti) = chan<uN[96][u32: 2]>("arbiter_aptt");
        let (aivo, aivi) = chan<u1[u32: 2]>("arbiter_aiv");
        let (aroo, aroi) = chan<u32>("arbiter_aro");
        let (aco, aci) = chan<arbiter_helper::ArbOut<u32: 2>>("ac");
        spawn shuffler_core::shuffler_core<u32: 2, u32: 8>(
            eossyncin, sf_pt3_out,
            aptto, aivo, aroo, aci
        );
        spawn arbiter::arbiter_wrapper<u32: 2>(aptti, aivi, aroi, aco);
        // SF to PE (the c stands for cluster)
        // topmost channels
        let (pnruo, pnrui) = chan<u30>[u32: 2]("pnru");
        let (psio, psii) = chan<u32>[u32: 2]("psi");
        let (pupo, pupi) = chan<pe_helper::StreamPayload>[u32: 2]("pup");
        let (paao, paai) = chan<pe_helper::StreamAddr>[u32: 2]("paa");
        // pe_send unique channels
        let (cao, cai) = chan<pe_helper::StreamAddr>[u32: 2]("ca");
        let (sao, sai) = chan<pe_helper::StreamAddr>[u32: 2]("sa");
        let (rao, rai) = chan<pe_helper::StreamAddr>[u32: 2]("ra");
        // pe_addr_arbiter unique channel (also topmost)
        let (puao, puai) = chan<pe_helper::StreamAddr>[u32: 2]("pua");
        // pe_recv unique channels
        let (cpt4o, cpt4i) = chan<uN[64]>[u32: 2]("cpt4");
        spawn pe_send::pe_send<u32: 2>(pnrui[0], sf_pt3_in[0], cao[0], sao[0], rao[0]);
        spawn pe_send::pe_send<u32: 2>(pnrui[1], sf_pt3_in[1], cao[1], sao[1], rao[1]);
        spawn pe_addr_arbiter::pe_addr_arbiter(cai[0], sai[0], rai[0], puao[0]);
        spawn pe_addr_arbiter::pe_addr_arbiter(cai[1], sai[1], rai[1], puao[1]);
        spawn pe_recv::pe_recv<u32: 2, u32: 5>(psii[0], pupi[0], paao[0], cpt4o[0]);
        spawn pe_recv::pe_recv<u32: 2, u32: 5>(psii[1], pupi[1], paao[1], cpt4o[1]);

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
            vncpo, vba_unified_addr_in, vba_streaming_pld_out,
            // for the ML
            ml_unified_addr_in, ml_unified_pld_out, crp_out, mncp_out, tnp_out,
            // for both PEs
            pnruo, psio, puai, pupo, paai,
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
        let tok7 = for (idx, tok):(u32, token) in u32:0..u32:2{send(tok, pe_num_rows_updated[idx], u30: 2)}(join());
        let tok8 = for (idx, tok):(u32, token) in u32:0..u32:2{send(tok, pe_stream_id[idx], idx)}(join());
        let tok9 = send(join(), current_row_partition, u32: 0);
        let tok10 = send(join(), num_hbm_channels_each_kernel, [u32: 1]);

        trace_fmt!("sending row info");
        let tok = join(tok1, tok2, tok3, tok4, tok5, tok6, tok7, tok8, tok9, tok10);
        
        // every row involves clearing of PE banks
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);

        // PART 1------------------------------------------------------
        // VL/VAU partition loading
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 1 , u32: 0]); // for now, you need to put the elements in reverse order

        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one.addr, cmd_addr_one.write_pld);
        let vau1_bank = update(vau1_bank, cmd_addr_two.addr, cmd_addr_two.write_pld);

        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 3 , u32: 2]);

        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one.addr, cmd_addr_one.write_pld);
        let vau1_bank = update(vau1_bank, cmd_addr_two.addr, cmd_addr_two.write_pld);

        trace_fmt!("VAU BANKS: {:0x} {:0x}", vau0_bank, vau1_bank);
        
        // per matrix partition metadata handshake
        let (tok, requested_index) = recv(tok, ml_unified_addr);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let start_of_partition = [u32: 0 ++ u32: 0, u32: 0 ++ u32: 0];
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: start_of_partition, commands: requested_index.commands, message_type: requested_index.message_type});
        let (tok, requested_index) = recv(tok, ml_unified_addr);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let stream_length_payload = [u32: 3 ++ u32: 0, u32: 1 ++ u32: 0];
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: stream_length_payload, commands: requested_index.commands, message_type: requested_index.message_type});
        // start of partition, buffer all the matrix sends first
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("SOD StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let pld = matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 0 ++ u32: 1, all_ones!<u32>() ++ u32: 1], commands: req_i.commands, message_type: req_i.message_type};
        let tok = send(tok, ml_unified_pld, pld);

        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let pld = matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 2 ++ u32: 2, zero!<u64>()], commands: req_i.commands, message_type: req_i.message_type};
        let tok = send(tok, ml_unified_pld, pld);

        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let pld = matrix_helper::StreamPayload<u32: 2>{payload_type_one: [all_ones!<u32>() ++ u32: 1, zero!<u64>()], commands: req_i.commands, message_type: req_i.message_type};
        let tok = send(tok, ml_unified_pld, pld);

        // then deal with the VAU after buffering matrix sends until VAU is not blocked on the "din" channel
        // (the number can be calculated beforehand but this is an easy way to do it as well)
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("SOD VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});

        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});

        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        // finally grab the EOD command
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("EOD StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("EOD VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});
        // PART 1------------------------------------------------------
        // try to make this as streamlined as possible
        // PART 2------------------------------------------------------
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 5 , u32: 4]);
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one.addr, cmd_addr_one.write_pld);
        let vau1_bank = update(vau1_bank, cmd_addr_two.addr, cmd_addr_two.write_pld);
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 7 , u32: 6]);
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one.addr, cmd_addr_one.write_pld);
        let vau1_bank = update(vau1_bank, cmd_addr_two.addr, cmd_addr_two.write_pld);
        trace_fmt!("VAU BANKS: {:0x} {:0x}", vau0_bank, vau1_bank);
        let (tok, requested_index) = recv(tok, ml_unified_addr);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 3 ++ u32: 0, u32: 0 ++ u32: 0], commands: requested_index.commands, message_type: requested_index.message_type});
        let (tok, requested_index) = recv(tok, ml_unified_addr);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 3 ++ u32: 0, u32: 3 ++ u32: 0], commands: requested_index.commands, message_type: requested_index.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("SOD StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [all_ones!<u32>() ++ u32: 1, all_ones!<u32>() ++ u32: 1], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 0 ++ u32: 3, u32: 0 ++ u32: 5], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 2 ++ u32: 4, u32: 3 ++ u32: 6], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("EOD StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("EOS StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("SOD VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let tok = send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, row_index: cmd_addr_two.row_indx as u30, matrix_pld: cmd_addr_two.matrix_pld, vector: vau1_bank[cmd_addr_two.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("EOD VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("EOS VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});
        // PART 2------------------------------------------------------
        // row change stuff:
        // finally unblocking the PEs and sampling the output (this is done on a per row/EOS basis)
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        //
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_accumulation_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        //--
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        //
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_accumulation_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        // symmetry stopped
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr SOD: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, commands: pe1reqaddr.commands});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr EOD: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, commands: pe1reqaddr.commands});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr EOS: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, commands: pe1reqaddr.commands});
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr SOD: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, commands: pe0reqaddr.commands});
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});        
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr EOD: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, commands: pe0reqaddr.commands});
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr EOS: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, commands: pe0reqaddr.commands});
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
        let tok7 = for (idx, tok):(u32, token) in u32:0..u32:2{send(tok, pe_num_rows_updated[idx], u30: 2)}(join());
        let tok8 = for (idx, tok):(u32, token) in u32:0..u32:2{send(tok, pe_stream_id[idx], idx)}(join());
        let tok9 = send(join(), current_row_partition, u32: 1);
        let tok10 = send(join(), num_hbm_channels_each_kernel, [u32: 1]);
        trace_fmt!("sending row info");
        let tok = join(tok1, tok2, tok3, tok4, tok5, tok6, tok7, tok8, tok9, tok10);
        // every row involves clearing of PE banks
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);

        // PART 3------------------------------------------------------
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 1 , u32: 0]);
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one.addr, cmd_addr_one.write_pld);
        let vau1_bank = update(vau1_bank, cmd_addr_two.addr, cmd_addr_two.write_pld);
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 3 , u32: 2]);
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one.addr, cmd_addr_one.write_pld);
        let vau1_bank = update(vau1_bank, cmd_addr_two.addr, cmd_addr_two.write_pld);
        trace_fmt!("VAU BANKS: {:0x} {:0x}", vau0_bank, vau1_bank);
        let (tok, requested_index) = recv(tok, ml_unified_addr);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 6 ++ u32: 0, u32: 0 ++ u32: 0], commands: requested_index.commands, message_type: requested_index.message_type});
        let (tok, requested_index) = recv(tok, ml_unified_addr);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 3 ++ u32: 0, u32: 3 ++ u32: 0], commands: requested_index.commands, message_type: requested_index.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("SOD StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 0 ++ u32: 7, u32: 0 ++ u32: 8], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [all_ones!<u32>() ++ u32: 1, all_ones!<u32>() ++ u32: 1], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 0 ++ u32: 9, u32: 0 ++ u32: 1], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("EOD StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("SOD VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("EOD VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});
        // PART 3------------------------------------------------------

        // PART 4------------------------------------------------------
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 5 , u32: 4]);
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one.addr, cmd_addr_one.write_pld);
        let vau1_bank = update(vau1_bank, cmd_addr_two.addr, cmd_addr_two.write_pld);
        let (tok, addr) = recv(tok, hbm_vector_addr);
        trace_fmt!("requested vector addr: {:0x}", addr);
        let tok = send(tok, hbm_vector_payload, [u32: 7 , u32: 6]);
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let vau0_bank = update(vau0_bank, cmd_addr_one.addr, cmd_addr_one.write_pld);
        let vau1_bank = update(vau1_bank, cmd_addr_two.addr, cmd_addr_two.write_pld);
        trace_fmt!("VAU BANKS: {:0x} {:0x}", vau0_bank, vau1_bank);
        let (tok, requested_index) = recv(tok, ml_unified_addr);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 9 ++ u32: 0, u32: 0 ++ u32: 0], commands: requested_index.commands, message_type: requested_index.message_type});
        let (tok, requested_index) = recv(tok, ml_unified_addr);
        trace_fmt!("metadata requested index {:0x}", requested_index);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 5 ++ u32: 0, u32: 5 ++ u32: 0], commands: requested_index.commands, message_type: requested_index.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("SOD StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 1 ++ u32: 2, u32: 1 ++ u32: 3], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 2 ++ u32: 4, u32: 2 ++ u32: 5], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 3 ++ u32: 6, u32: 3 ++ u32: 7], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [all_ones!<u32>() ++ u32: 1, all_ones!<u32>() ++ u32: 1], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("p1 addr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: [u32: 2 ++ u32: 8, u32: 2 ++ u32: 9], commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("EOD StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        let (tok, req_i) = recv(tok, ml_unified_addr);
        trace_fmt!("EOS StreamAddr: {:0x}", req_i);
        let tok = send(tok, ml_unified_pld, matrix_helper::StreamPayload<u32: 2>{payload_type_one: zero!<uN[64][2]>(), commands: req_i.commands, message_type: req_i.message_type});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("SOD VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let tok = send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, row_index: cmd_addr_two.row_indx as u30, matrix_pld: cmd_addr_two.matrix_pld, vector: vau1_bank[cmd_addr_two.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let tok = send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, row_index: cmd_addr_two.row_indx as u30, matrix_pld: cmd_addr_two.matrix_pld, vector: vau1_bank[cmd_addr_two.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let tok = send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, row_index: cmd_addr_two.row_indx as u30, matrix_pld: cmd_addr_two.matrix_pld, vector: vau1_bank[cmd_addr_two.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let tok = send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, row_index: cmd_addr_one.row_indx as u30, matrix_pld: cmd_addr_one.matrix_pld, vector: vau0_bank[cmd_addr_one.addr]});
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        let tok = send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, row_index: cmd_addr_two.row_indx as u30, matrix_pld: cmd_addr_two.matrix_pld, vector: vau1_bank[cmd_addr_two.addr]});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("EOD VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});
        let (tok, cmd_addr_one) = recv(tok, vba_unified_addr[0]);
        let (tok, cmd_addr_two) = recv(tok, vba_unified_addr[1]);
        trace_fmt!("EOS VBA\naddr {:0x} {:0x}", cmd_addr_one, cmd_addr_two);
        send(tok, vba_streaming_pld[0], vector_helper::StreamPayload{commands: cmd_addr_one.commands, ..zero!<vector_helper::StreamPayload>()});
        send(tok, vba_streaming_pld[1], vector_helper::StreamPayload{commands: cmd_addr_two.commands, ..zero!<vector_helper::StreamPayload>()});
        // PART 4------------------------------------------------------
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        //
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_accumulation_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        //--
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        //
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_accumulation_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        //--
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        //
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_accumulation_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        //--
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        //
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_accumulation_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        //--
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        //
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_accumulation_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        //--
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        //
        let (tok, pe0reqaddr) = recv(tok, pe_accumulation_addr[0]);
        trace_fmt!("pe0 req addr WRITE: {:0x}", pe0reqaddr);
        let pe0_bank = update(pe0_bank, pe0reqaddr.addr, pe0reqaddr.write_pld);
        let (tok, pe1reqaddr) = recv(tok, pe_accumulation_addr[1]);
        trace_fmt!("pe1 req addr WRITE: {:0x}", pe1reqaddr);
        let pe1_bank = update(pe1_bank, pe1reqaddr.addr, pe1reqaddr.write_pld);
        //--
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr SOD: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, commands: pe0reqaddr.commands});
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr READ: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});        
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr EOD: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, commands: pe0reqaddr.commands});
        let (tok, pe0reqaddr) = recv(tok, pe_unified_addr[0]);
        trace_fmt!("pe0 req addr EOS: {:0x}", pe0reqaddr);
        let tok = send(tok, pe_unified_pld[0], pe_helper::StreamPayload{mem_base: pe0_bank[pe0reqaddr.addr], matrix_val: pe0reqaddr.matrix_val, vector_val: pe0reqaddr.vector_val, addr: pe0reqaddr.addr as u30, commands: pe0reqaddr.commands});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr SOD: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, commands: pe1reqaddr.commands});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr READ: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, ..zero!<pe_helper::StreamPayload>()});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr EOD: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, commands: pe1reqaddr.commands});
        let (tok, pe1reqaddr) = recv(tok, pe_unified_addr[1]);
        trace_fmt!("pe1 req addr EOS: {:0x}", pe1reqaddr);
        let tok = send(tok, pe_unified_pld[1], pe_helper::StreamPayload{mem_base: pe1_bank[pe1reqaddr.addr], matrix_val: pe1reqaddr.matrix_val, vector_val: pe1reqaddr.vector_val, addr: pe1reqaddr.addr as u30, commands: pe1reqaddr.commands});
        let (tok, output_addr) = recv(tok, output_buffer_hbm_vector_addr);
        trace_fmt!("requested write out addr: {:0x}", output_addr);
        let (tok, output_pld) = recv(tok, output_buffer_hbm_vector_payload);
        trace_fmt!("requested write out payload: {:0x}", output_pld);
        let (tok, output_addr) = recv(tok, output_buffer_hbm_vector_addr);
        trace_fmt!("requested write out addr: {:0x}", output_addr);
        let (tok, output_pld) = recv(tok, output_buffer_hbm_vector_payload);
        trace_fmt!("requested write out payload: {:0x}", output_pld);
        let tok = send(tok, terminator, true);
        trace_fmt!("done");
        tester_state
    }
}