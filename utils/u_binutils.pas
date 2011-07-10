unit u_binutils;

interface

uses
  SysUtils, Classes;

function SetBit(Bit: Byte; Value: DWord): DWord; inline;
function ResetBit(Bit: Byte; Value: DWord): DWord; inline;
function GetBit(Bit: Byte; Value: DWord): Byte; inline;
procedure MoveDWord(Bits: Byte; SRC: DWord; var DST1, DST2: DWord); inline;

procedure AppendBits(var D: PByte; var O: Byte; var Total: Integer; V, N: Byte); inline;
function ExtractBits(var D: PByte; var O: Byte; N: Byte): Byte; inline;

implementation

function SetBit(Bit: Byte; Value: DWord): DWord; inline;
begin
  Result := Value or (1 shl Bit);
end;

function ResetBit(Bit: Byte; Value: DWord): DWord; inline;
begin
  Result := Value and ((not 1) shl Bit);
end;

function GetBit(Bit: Byte; Value: DWord): Byte; inline;
begin
  Result := (Value and (1 shl Bit)) shr Bit;
end;

procedure MoveDWord(Bits: Byte; SRC: DWord; var DST1, DST2: DWord); inline;
begin
  DST1 := (DST1 and (not (high(DWord) shl Bits))) or (SRC shl Bits);
  DST2 := (DST2 and (not (high(DWord) shr (32 - Bits)))) or (SRC shr (32 - Bits));
end;


procedure AppendBits(var D: PByte; var O: Byte; var Total: Integer; V, N: Byte); inline;
const
  Mask: Array[0..8] of Byte = ($00, $01, $03, $07, $0F, $1F, $3F, $7F, $FF);
begin
  PWord(D)^ := (Word(D^) and not (Mask[N] shl O)) or (V shl O);
  inc(O, N);
  inc(D, O shr 3);
  inc(Total, O shr 3);
  O := O and $07;
end;

function ExtractBits(var D: PByte; var O: Byte; N: Byte): Byte; inline;
const
  Mask: Array[0..8] of Byte = ($00, $01, $03, $07, $0F, $1F, $3F, $7F, $FF);
begin
  Result := (PWord(D)^ shr O) and Mask[N];
  inc(O, N);
  inc(D, O shr 3);
  O := O and $07;
end;

end.

