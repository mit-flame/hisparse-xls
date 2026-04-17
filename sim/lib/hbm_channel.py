import json
from typing import Any
import pprint

"""
partition the raw matrix into smaller
sub matrices dependent on the vec
buffer lengths
"""
def raw_to_partitioned(
    matrix_fp:          str,
    out_vec_buf_len:    int,
    inp_vec_buf_len:    int
):
    parts = {}
    with open(matrix_fp) as file:
        fj = json.load(file)
        meta = fj["metadata"]
        num_row_parts = meta["h"] // out_vec_buf_len # must divide cleanly
        num_col_parts = meta["w"] // inp_vec_buf_len # must divide cleanly
        for row_part in range(0, num_row_parts):
            for col_part in range(0, num_col_parts):
                partition_name = f"{row_part}_{col_part}_p"
                parts[partition_name] = {
                    "metadata": {
                        "h": out_vec_buf_len,
                        "w": inp_vec_buf_len,
                    },
                    "raw": []
                }
                for row in range(row_part*out_vec_buf_len, (row_part + 1)*out_vec_buf_len):
                    parts[partition_name]["raw"].append([])
                    for col in range(col_part*inp_vec_buf_len, (col_part + 1)*inp_vec_buf_len):
                        parts[partition_name]["raw"][row % out_vec_buf_len].append(fj["raw"][row][col])
        meta["row_parts"] = num_row_parts
        meta["col_parts"] = num_col_parts
        parts["metadata"] = meta
    return parts

def raw_to_csr(
    matrix:     dict,
) -> dict:
    data = []
    indx = []
    rows = []
    first_row = True
    start_i = None
    d_ind = 0
    meta = matrix["metadata"]
    for row in range(0, meta["h"]):
        for col in range(0, meta["w"]):
            d = matrix["raw"][row][col]
            if d != 0:
                data.append(d)
                indx.append(col)
                if first_row:
                    start_i = d_ind
                    end_i = d_ind
                    first_row = False
                else:
                    end_i = d_ind
                d_ind += 1
        if first_row:
            rows.append(0)
        else:
            if start_i is not None:
                rows.append(start_i)
                start_i = None
            rows.append(end_i + 1)
    if first_row:
        # if the matrix was completely sparse, then we did not print a start_i, thus we are one element short
        rows.append(0)
    return {
        "metadata": meta,
        "data": data,
        "cols": indx,
        "rows": rows
    }


"""
cyclically assign rows to streams, number
of streams == number of PEs. idx_marker means
go to next row
"""
def csr_to_streams(
    csr:        dict,
    idx_marker: int,
    num_pe:     int
) -> dict:
    row = 0
    last_d_ind = csr["rows"][0]
    streams = {
        "metadata": csr["metadata"],
        "streams": {}
    }
    inner_stream = streams["streams"]
    for pe in range(0, num_pe):
        inner_stream[pe] = {
            "stream": [],
            "rows": [],
            "cols": []
        }
    for d_ind in csr["rows"][1:]:
        stream = row % num_pe
        if (row > stream):
            inner_stream[stream]["stream"].append(idx_marker)
            inner_stream[stream]["cols"].append(idx_marker)
        inner_stream[stream]["stream"].extend(csr["data"][last_d_ind:d_ind])
        inner_stream[stream]["rows"].append(row)
        inner_stream[stream]["cols"].extend(csr["cols"][last_d_ind:d_ind])
        last_d_ind = d_ind
        row += 1
    return streams

"""
combine successive skip row indicators
"""
def stream_skip_rows(
    streams:        dict,
    idx_marker:     Any
):
    def combine_markers(lst: list) -> list:
        newlist = []
        itr = 0
        while itr < len(lst):
            if lst[itr] == idx_marker:
                new_marker = lst[itr]
                itr += 1
                while itr < len(lst) and lst[itr] == idx_marker:
                    if type(idx_marker) == str:
                        new_marker = f"+{int(lst[itr][idx_marker.index("+"):]) + int(new_marker[idx_marker.index("+"):])}"
                    elif type(idx_marker) == int:
                        new_marker = lst[itr] + new_marker  #assuming negative numbers are skip row indicators
                    itr += 1
                newlist.append(new_marker)
            else:
                newlist.append(lst[itr])
                itr += 1
        return newlist
    new_streams = {"metadata": streams["metadata"], "streams": {}}
    for pe, stream in streams["streams"].items():
        new_streams["streams"][pe] = {}
        inner_stream = new_streams["streams"][pe]
        inner_stream["rows"] = stream["rows"]
        inner_stream["stream"] = combine_markers(stream["stream"])
        inner_stream["cols"] = combine_markers(stream["cols"])
    return new_streams


"""
pack streams together into an hbm channel
"""
def streams_to_hbmchannel(
    streams:            dict,
    padding_idx_marker: int
) -> list:
    mxlen = 0
    for _, stream in streams["streams"].items():
        assert len(stream["cols"]) == len(stream["stream"]), "Something went wrong"
        if len(stream["cols"]) > mxlen:
            mxlen = len(stream["cols"])
    payloads = []
    for i in range(0, mxlen):
        payload = []
        element = None
        for _, stream in streams["streams"].items():
            if i < len(stream["cols"]):
                element = (stream["stream"][i], stream["cols"][i])
            else:
                element = (padding_idx_marker, padding_idx_marker)
            payload.append(element)
        payloads.append(payload)
    return payloads

"""
create iterable from hbmchannel (idk why i made this)
"""
def streams_to_hbmchannel_iterable(
    streams:            dict,
    padding_idx_marker: int
):
    hbmchannel = streams_to_hbmchannel(streams, padding_idx_marker)
    for el in hbmchannel:
        yield el

"""
based upon data_formatter.h's csr2cpsr
returns a dictionary of iterables, representing a mock
HBM storing a matrix in CPSR format
"""
def raw_to_cpsr_hbmchannel_iterator(
        matrix_fp:              str,
        next_row_marker:        int,
        padding_marker:         int,
        out_vec_buf_len:        int,
        inp_vec_buf_len:        int,
        pe_per_channel:         int,
        num_hbm_chan:           int,
        skip_rows:              bool = False
):
    _hbm = {}
    partitioned_matrix = raw_to_partitioned(matrix_fp, out_vec_buf_len, inp_vec_buf_len)
    for partition, matrix in partitioned_matrix.items():
        if partition == "metadata":
            continue
        _hbm[partition] = {}
        csr = raw_to_csr(matrix)
        streams = csr_to_streams(csr, next_row_marker, pe_per_channel*num_hbm_chan)
        if skip_rows:
            streams = stream_skip_rows(streams, next_row_marker)
        stream_per_chan = len(streams["streams"]) // num_hbm_chan
        for hbm_chan in range(0, num_hbm_chan):
            legal_streams = range(hbm_chan*stream_per_chan, (hbm_chan + 1)*stream_per_chan)
            split_stream = {"metadata": streams["metadata"]}
            split_stream["streams"] =  {k: v for k, v in streams["streams"].items() if k in legal_streams}
            _hbm[partition][hbm_chan] = streams_to_hbmchannel_iterable(split_stream, padding_marker)
    _hbm["metadata"] = partitioned_matrix["metadata"]
    return _hbm

"""
again no idea why i made it an iterable lol
"""
def raw_to_cpsr_hbmchannel(
        matrix_fp:              str,
        next_row_marker:        int,
        padding_marker:         int,
        out_vec_buf_len:        int,
        inp_vec_buf_len:        int,
        pe_per_channel:         int,
        num_hbm_chan:           int,
        skip_rows:              bool = False
):
    _hbm = {}
    partitioned_matrix = raw_to_partitioned(matrix_fp, out_vec_buf_len, inp_vec_buf_len)
    for partition, matrix in partitioned_matrix.items():
        if partition == "metadata":
            continue
        _hbm[partition] = {}
        csr = raw_to_csr(matrix)
        streams = csr_to_streams(csr, next_row_marker, pe_per_channel*num_hbm_chan)
        if skip_rows:
            streams = stream_skip_rows(streams, next_row_marker)
        stream_per_chan = len(streams["streams"]) // num_hbm_chan
        for hbm_chan in range(0, num_hbm_chan):
            legal_streams = range(hbm_chan*stream_per_chan, (hbm_chan + 1)*stream_per_chan)
            split_stream = {"metadata": streams["metadata"]}
            split_stream["streams"] =  {k: v for k, v in streams["streams"].items() if k in legal_streams}
            _hbm[partition][hbm_chan] = streams_to_hbmchannel(split_stream, padding_marker)
    _hbm["metadata"] = partitioned_matrix["metadata"]
    return _hbm

"""
converts grabbed value from mem into int
"""
def grab_binary_value(mem: "HBM_CHAN", addr: int) -> int:
    packed_pld = mem[addr]
    packed_pld_str = ""
    ALL_ONES = 2**32 - 1
    for stream in reversed(packed_pld):
        if type(stream[0]) == str:
            if "+" in stream[0]: # next row marker
                packed_pld_str += f"{ALL_ONES:0{8}x}" + f"{int(stream[0][1:]):0{8}x}"
            else: # padding
                packed_pld_str += f"{0:0{8}x}" + f"{0:0{8}x}"
        else:
            packed_pld_str += f"{stream[1]:0{8}x}" + f"{stream[0]:0{8}x}"
    return int(packed_pld_str, 16)

def vec_int_func(mem: list, addr: int): 
    packed_pld_str = ""
    for stream in range(2):
        packed_pld_str += f"{mem[addr*2 + stream]:0{8}x}"
    return int(packed_pld_str, 16)

"""
    converts a single HBM chan's contents into vivado's COE file format
    probably assumess the arch is two stream
    see https://docs.amd.com/r/2024.2-English/ug896-vivado-ip/COE-File-Examples
"""
def hbm_chan_to_coe(mem: "HBM_CHAN"):
    coe = "memory_initialization_radix=16;\nmemory_initialization_vector="
    for i in range(len(mem)):
        coe += f"\n{grab_binary_value(mem, i):0{32}x},"
    coe = coe[:-1]
    coe += ";"
    print(coe)

"""
    does same as above for input vec, definitely assumes 2 stream
"""
def vec_to_coe(mem: list):
    coe = "memory_initialization_radix=16;\nmemory_initialization_vector="
    for i in range(len(mem)//2):
        coe += f"\n{vec_int_func(mem, i):0{16}x},"
    coe = coe[:-1]
    coe += ";"
    print(coe)

"""
creates a mock hbm that responds to index queries for a single hbm channel.
Multiple hbm channels would be multiple instances of this class with differing specific_chan's
written horribly (this entire file is, this entire repo is)
"""
class HBM_CHAN:
    def __init__(self, total_hbm: dict, chan: int, num_streams: int): # yes i know this is wasteful
        self.metadata_range = total_hbm["metadata"]["row_parts"] * total_hbm["metadata"]["col_parts"] * 2
        self.stream_lengths = [] # per partition stream lengths (one tuple per partition)
        self.num_streams = num_streams
        for key, part in total_hbm.items():
            if key == "metadata":
                continue
            lengths = [0]*num_streams
            for pkt in part[chan]:
                for ind, strm in enumerate(pkt):
                    if strm != ('#', '#'):
                        lengths[ind] += 1
            self.stream_lengths.append(tuple(lengths))
        self.partition_starts = [0]
        for el in self.stream_lengths:
            base = 0
            if len(self.partition_starts) != 0:
                base = self.partition_starts[-1]
            base += max(el)
            self.partition_starts.append(base)
        self.hbm = []
        for key, part in total_hbm.items():
            if key == "metadata":
                continue
            self.hbm.extend(part[chan])
        
    def __getitem__(self, ind: int):
        # metadata request
        if ind < self.metadata_range:
            # two packets of metadata per partition, odd is stream lengths, even is start of partition 
            if ind % 2 == 0:
                rval = [(0, self.partition_starts[ind//2])]
                rval.extend([(0,0)]*(self.num_streams - 1))
                return tuple(rval)
            else:
                rval = [(0, self.stream_lengths[ind//2][i]) for i in range(self.num_streams)]
                return rval
        # packed data request
        else:
            return self.hbm[ind - self.metadata_range]
        
    def __len__(self):
        return self.metadata_range + len(self.hbm)
                

    

if __name__ == "__main__":
    # HBM = raw_to_cpsr_hbmchannels("../../data/spmv1.json", "+1", "#", 2, 2, 2, 1)
    # HBM = raw_to_cpsr_hbmchannels("../../data/spmv2.json", -1, None, 12, 12, 2, 2, True)
    HBM = raw_to_cpsr_hbmchannel_iterator("../../data/spmv3.json", "+1", "#", 12, 12, 2, 2, True)
    for partition, hbm_channels in HBM.items():
        if partition == "metadata":
            continue
        print("~"*21 + "\n", f"| PARTITION {partition} |\n", "\r" + "~"*21)
        for hbm_chan, chan in hbm_channels.items():
            print()
            print(f"HBM CHANNEL {hbm_chan}")
            streams = {}
            mxlen = 0
            for packed_element in chan:
                strm = 0
                for stream in packed_element:
                    if strm not in streams:
                        streams[strm] = {"DATA":[], "COLS":[]}
                    data = f" {stream[0]}"
                    streams[strm]["DATA"].append(data)
                    col = f" {stream[1]}"
                    streams[strm]["COLS"].append(col)
                    if len(data) > mxlen:
                        mxlen = len(data)
                    if len(col) > mxlen:
                        mxlen = len(col)
                    strm += 1
            # pad each element based upon mxlen
            final_streams = {}
            for k, stream in streams.items():
                final_streams[k] = {"DATA":[], "COLS":[]}
                for key, elem in stream.items():
                    for e in elem:
                        final_streams[k][key].append(str(e).ljust(mxlen, " "))

            # data and cols are reversed to match the format of the paper. In reality,
            # the unreversed will be used by the testbench

            # both data and cols being printed
            # for _, stream in streams.items():
            #     print(f"DATA: {stream["DATA"][::-1]}")
            #     print(f"COLS: {stream["COLS"][::-1]}")
            # just data being printed (like the paper)
            for _, stream in final_streams.items():
                print(f"DATA: {" ".join(stream["DATA"][::-1])}")
        print("-"*30)
    total_hbm = raw_to_cpsr_hbmchannel("/home/ayana/MEng/hisparse-xls/data/spmv1.json", "+1", "#", 4, 4, 2, 1, True)
    hbm_chan_to_coe(HBM_CHAN(total_hbm=total_hbm, chan=0, num_streams=2))
    vec_to_coe(list(range(8)))
    print()
