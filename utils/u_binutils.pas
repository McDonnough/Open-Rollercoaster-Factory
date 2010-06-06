unit u_binutils;

interface

uses
  SysUtils, Classes;

function SetBit(Bit: Byte; Value: DWord): DWord;
function ResetBit(Bit: Byte; Value: DWord): DWord;
function GetBit(Bit: Byte; Value: DWord): Byte;
procedure MoveDWord(Bits: Byte; SRC: DWord; var DST1, DST2: DWord);

implementation

function SetBit(Bit: Byte; Value: DWord): DWord;
begin
  Result := Value or (1 shl Bit);
end;

function ResetBit(Bit: Byte; Value: DWord): DWord;
begin
  Result := Value and ((not 1) shl Bit);
end;

function GetBit(Bit: Byte; Value: DWord): Byte;
begin
  Result := (Value and (1 shl Bit)) shr Bit;
end;

procedure MoveDWord(Bits: Byte; SRC: DWord; var DST1, DST2: DWord);
begin
  DST1 := (DST1 and (not (high(DWord) shl Bits))) or (SRC shl Bits);
  DST2 := (DST2 and (not (high(DWord) shr (32 - Bits)))) or (SRC shr (32 - Bits));
end;

end.
