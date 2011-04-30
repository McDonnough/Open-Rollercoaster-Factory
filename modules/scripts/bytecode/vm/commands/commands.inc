// Inlcude other files
{$I mem_cmds.inc}
{$I reg_cmds.inc}
{$I jump_cmds.inc}
{$I bool_cmds.inc}
{$I math_cmds.inc}
{$I vec_cmds.inc}


{$IFNDEF BYTECODE_IMPL}
procedure _NOP(C: Pointer);
procedure _WRITEVR(C: Pointer);
procedure _WRITEIR(C: Pointer);

{$ELSE}

procedure _NOP(C: Pointer);
begin
end;


procedure _WRITEVR(C: Pointer);
begin
  writeln('Script: ', VM.fRegisters[Byte((C + SizeOf(Word))^)].X, ' ', VM.fRegisters[Byte((C + SizeOf(Word))^)].Y, ' ', VM.fRegisters[Byte((C + SizeOf(Word))^)].Z, ' ', VM.fRegisters[Byte((C + SizeOf(Word))^)].W);
end;

procedure _WRITEIR(C: Pointer);
begin
  writeln('Script: ', VM.fIRegisters[Byte((C + SizeOf(Word))^)]);
end;
{$ENDIF}
