{$IFNDEF BYTECODE_IMPL}
procedure _JMPI(C: Pointer);
procedure _JMPIR(C: Pointer);
procedure _JMP0I(C: Pointer);
procedure _JMP0IR(C: Pointer);


procedure _CALLI(C: Pointer);
procedure _CALLIR(C: Pointer);
procedure _CALL0I(C: Pointer);
procedure _CALL0IR(C: Pointer);


procedure _RET(C: Pointer);
procedure _RET0(C: Pointer);


{$ELSE}

procedure _JMPI(C: Pointer);
begin
  VM.fUpdatePC := 0;
  VM.fPC := PtrUInt((C + SizeOf(Word))^);
end;

procedure _JMPIR(C: Pointer);
begin
  VM.fUpdatePC := 0;
  VM.fPC := VM.fIRegisters[Byte((C + SizeOf(Word))^)];
end;

procedure _JMP0I(C: Pointer);
begin
  if VM.fIRegisters[15] <> 0 then
    _JMPI(C);
end;

procedure _JMP0IR(C: Pointer);
begin
  if VM.fIRegisters[15] <> 0 then
    _JMPIR(C);
end;



procedure _CALLI(C: Pointer);
begin
  PtrUInt((Script.Stack.FirstByte + Script.SP)^) := VM.fPC + SizeOf(Word) + SizeOf(PtrUInt);
  Script.SP := Script.SP + SizeOf(PtrUInt);
  VM.fUpdatePC := 0;
  VM.fPC := PtrUInt((C + SizeOf(Word))^);
end;

procedure _CALLIR(C: Pointer);
begin
  PtrUInt((Script.Stack.FirstByte + Script.SP)^) := VM.fPC + SizeOf(Word) + SizeOf(Byte);
  Script.SP := Script.SP + SizeOf(PtrUInt);
  VM.fUpdatePC := 0;
  VM.fPC := PtrUInt((C + SizeOf(Word))^);
end;

procedure _CALL0I(C: Pointer);
begin
  if VM.fIRegisters[15] <> 0 then
    _CALLI(C);
end;

procedure _CALL0IR(C: Pointer);
begin
  if VM.fIRegisters[15] <> 0 then
    _CALLIR(C);
end;



procedure _RET(C: Pointer);
begin
  Script.SP := Script.SP - SizeOf(PtrUInt);
  VM.fUpdatePC := 0;
  VM.fPC := PtrUInt((Script.Stack.FirstByte + Script.SP)^);
end;

procedure _RET0(C: Pointer);
begin
  if VM.fIRegisters[15] <> 0 then
    _RET(C);
end;


{$ENDIF}
