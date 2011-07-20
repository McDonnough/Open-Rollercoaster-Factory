unit vorbis;

{ Header translation from vorbisfile.h and codec.h }

interface

uses
  SysUtils, Classes;

{ General stuff }

const
  LIBNAME = 'vorbisfile';

type
  size_t = PtrUInt;

  {$IFDEF WINDOWS}
  long = Integer;
  {$ELSE}
    {$IFDEF CPU64}
    long = Int64;
    {$ELSE}
    long = Integer;
    {$ENDIF}
  {$ENDIF}
  plong = ^long;

  PPSingle = ^PSingle;
  PPPSingle = ^PPSingle;

  pFile = ^File; // Not sure about this

{ from os_types.h }

type
  ogg_int16_t  = SmallInt;
  ogg_int16_p  = ^SmallInt;
  ogg_uint16_t = Word;
  ogg_uint16_p = ^Word;
  ogg_int32_t  = Integer;
  ogg_int32_p  = ^Integer;
  ogg_uint32_t = DWord;
  ogg_uint32_p = ^DWord;
  ogg_int64_t  = Int64;
  ogg_int64_p  = ^Int64;
  ogg_uint64_t = QWord;
  ogg_uint64_p = ^QWord;

{ from ogg.h }

type
  oggpack_buffer = record
    endbyte         : long;
    endbit          : integer;
    buffer          : PByte;
    ptr             : PByte;
    storage         : long;
    end;

  ogg_stream_state = record
    body_data       : PByte;
    body_storage    : long;
    body_fill       : long;
    body_returned   : long;
    lacing_vals     : PInteger;
    granule_vals    : ogg_int64_p;
    lacing_storage  : long;
    lacing_fill     : long;
    lacing_packet   : long;
    lacing_returned : long;
    header          : Array[0..281] of Byte;
    header_fill     : Integer;
    e_o_s           : Integer;
    b_o_s           : Integer;
    serialno        : long;
    pageno          : long;
    packetno        : ogg_int64_t;
    granulepos      : ogg_int64_t;
    end;
  pogg_stream_state = ^ogg_stream_state;

  ogg_sync_state = record
    data            : PByte;
    storage         : Integer;
    fill            : Integer;
    returned        : Integer;
    unsynced        : Integer;
    headerbytes     : Integer;
    bodybytes       : Integer;
    end;
  pogg_sync_state = ^ogg_sync_state;

{ from codec.h }

type
  vorbis_info = record
    version         : Integer;
    channels        : Integer;
    rate            : long;
    bitrate_upper   : long;
    bitrate_nominal : long;
    bitrate_lower   : long;
    bitrate_window  : long;
    codec_setup     : Pointer;
    end;
  pvorbis_info = ^vorbis_info;

  vorbis_dsp_state = record
    analysisp       : Integer;
    vi              : pvorbis_info;
    pcm             : PPSingle;
    pcmret          : PPSingle;
    pcm_storage     : Integer;
    pcm_current     : Integer;
    pcm_returned    : Integer;
    preextrapolate  : Integer;
    eofflag         : Integer;
    lW              : long;
    W               : long;
    nW              : long;
    centerW         : Long;
    granulepos      : ogg_int64_t;
    sequence        : ogg_int64_t;
    glue_bits       : ogg_int64_t;
    time_bits       : ogg_int64_t;
    floor_bits      : ogg_int64_t;
    res_bits        : ogg_int64_t;
    backend_state   : Pointer;
    end;
  pvorbis_dsp_state = ^vorbis_dsp_state;

  vorbis_block = record
    pcm             : PPSingle;
    opb             : oggpack_buffer;
    lW              : long;
    W               : long;
    nW              : long;
    pcmend          : Integer;
    mode            : Integer;
    eofflag         : Integer;
    granulepos      : ogg_int64_t;
    sequence        : ogg_int64_t;
    vd              : pvorbis_dsp_state;
    localstore      : Pointer;
    localtop        : long;
    localalloc      : long;
    totaluse        : long;
    alloc_chain     : Pointer; // irritating declaration in original source
    glue_bits       : ogg_int64_t;
    time_bits       : ogg_int64_t;
    floor_bits      : ogg_int64_t;
    res_bits        : ogg_int64_t;
    internal        : Pointer;
    end;
  pvorbis_block = ^vorbis_block;

  vorbis_comment = record
    user_comments   : PPChar;
    comment_lengths : PInteger;
    comments        : Integer;
    vendor          : PChar;
    end;
  pvorbis_comment = ^vorbis_comment;

{ from vorbisfile.h }

{$DEFINE NOTOPEN    0}
{$DEFINE PARTOPEN   1}
{$DEFINE OPENED     2}
{$DEFINE STREAMSET  3}
{$DEFINE INITSET    4}

type
  ov_callbacks_read_func  = function(prt: Pointer; size: size_t; nmenb: size_t; datasource: Pointer): size_t; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  ov_callbacks_seek_func  = function(datasource: Pointer; offset: ogg_int64_t; whence: Integer): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  ov_callbacks_close_func = function(datasource: Pointer): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  ov_callbacks_tell_func  = function(datasource: Pointer): long; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};

  ov_callbacks = record
    read_func       : ov_callbacks_read_func;
    seek_func       : ov_callbacks_seek_func;
    close_func      : ov_callbacks_close_func;
    tell_func       : ov_callbacks_tell_func;
    end;
  pov_callbacks = ^ov_callbacks;

  OggVorbis_File = record
    datasource      : Pointer;
    seekable        : Integer;
    offset          : ogg_int64_t;
    _end            : ogg_int64_t;
    oy              : ogg_sync_state;
    links           : Integer;
    offsets         : ogg_int64_p;
    dataoffsets     : ogg_int64_p;
    serialnos       : plong;
    pcmlengths      : ogg_int64_p;
    vi              : pvorbis_info;
    vc              : pvorbis_comment;
    pcm_offset      : ogg_int64_t;
    ready_state     : Integer;
    current_serialno: long;
    current_link    : Integer;
    bittrack        : Double;
    samptrack       : Double;
    os              : ogg_stream_state;
    vd              : vorbis_dsp_state;
    vb              : vorbis_block;
    callbacks       : ov_callbacks;
    end;
  pOggVorbis_File = ^OggVorbis_File;

  ov_filter = procedure(pcm: PPSingle; channels: long; samples: long; filter_param: Pointer); {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};

function ov_clear(vf: pOggVorbis_File): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_fopen(const Path: PChar; vf: pOggVorbis_File): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_open(f: pFile; vf: pOggVorbis_File; const initial: PChar; ibytes: long): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_open_callbacks(datasource: Pointer; vf: pOggVorbis_File; const initial: PChar; ibytes: long; callbacks: ov_callbacks): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

function ov_test(f: pFile; vf: pOggVorbis_File; const initial: PChar; ibytes: long): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_test_callbacks(datasource: Pointer; vf: pOggVorbis_File; const initial: PChar; ibytes: long; callbacks: ov_callbacks): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_test_open(vf: pOggVorbis_File): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

function ov_bitrate(vf: pOggVorbis_File; i: Integer): long; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_bitrate_instant(vf: pOggVorbis_File): long; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_streams(vf: pOggVorbis_File): long; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_seekable(vf: pOggVorbis_File): long; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_serialnumber(vf: pOggVorbis_File; i: Integer): long; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

function ov_raw_total(vf: pOggVorbis_File; i: Integer): ogg_int64_t; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_pcm_total(vf: pOggVorbis_File; i: Integer): ogg_int64_t; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_time_total(vf: pOggVorbis_File; i: Integer): double; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

function ov_raw_seek(vf: pOggVorbis_File; pos: ogg_int64_t): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_pcm_seek(vf: pOggVorbis_File; pos: ogg_int64_t): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_pcm_seek_page(vf: pOggVorbis_File; pos: ogg_int64_t): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_time_seek(vf: pOggVorbis_File; pos: double): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_time_seek_page(vf: pOggVorbis_File; pos: double): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

function ov_raw_seek_lap(vf: pOggVorbis_File; pos: ogg_int64_t): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_pcm_seek_lap(vf: pOggVorbis_File; pos: ogg_int64_t): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_pcm_seek_page_lap(vf: pOggVorbis_File; pos: ogg_int64_t): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_time_seek_lap(vf: pOggVorbis_File; pos: double): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_time_seek_page_lap(vf: pOggVorbis_File; pos: double): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

function ov_raw_tell(vf: pOggVorbis_File): ogg_int64_t; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_pcm_tell(vf: pOggVorbis_File): ogg_int64_t; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_time_tell(vf: pOggVorbis_File): double; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

function ov_info(vf: pOggVorbis_File; link: Integer): pvorbis_info; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_comment(vf: pOggVorbis_File; link: Integer): pvorbis_comment; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

function ov_read_float(vf: pOggVorbis_File; pcm_channels: PPPSingle; samples: Integer; bitstream: PInteger): long; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_read_filter(vf: pOggVorbis_File; buffer: PChar; length: Integer; bigendianp: Integer; wordsize: Integer; sgned: Integer; bitstream: PInteger; filter: ov_filter; filter_param: Pointer): long; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_read(vf: pOggVorbis_File; buffer: PChar; length: Integer; bigendianp: Integer; wordsize: Integer; sgned: Integer; bitstream: PInteger): long; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_crosslap(vf1: pOggVorbis_File; vf2: pOggVorbis_File): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

function ov_halfrate(vf: pOggVorbis_File; flag: Integer): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;
function ov_halfrate_p(vf: pOggVorbis_File): Integer; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external LIBNAME;

implementation

end.