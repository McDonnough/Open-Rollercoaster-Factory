{$IFNDEF BYTECODE_IMPL}

procedure _AND(C: Pointer);
procedure _OR(C: Pointer);
procedure _XOR(C: Pointer);
procedure _NOT(C: Pointer);

procedure _GTI(C: Pointer);
procedure _GTV(C: Pointer);
procedure _GEI(C: Pointer);
procedure _GEV(C: Pointer);
procedure _LTI(C: Pointer);
procedure _LTV(C: Pointer);
procedure _LEI(C: Pointer);
procedure _LEV(C: Pointer);
procedure _EQI(C: Pointer);
procedure _EQV(C: Pointer);
procedure _NEQI(C: Pointer);
procedure _NEQV(C: Pointer);

{$ELSE}

procedure _AND(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] and VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;

procedure _OR(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] or VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;

procedure _XOR(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] xor VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;

procedure _NOT(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] := not VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)];
end;



procedure _GTI(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] > VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] then
    VM.fIRegisters[15] := 1;
end;

procedure _GTV(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X > VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X then
    VM.fIRegisters[15] := 1;
end;

procedure _GEI(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] >= VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] then
    VM.fIRegisters[15] := 1;
end;

procedure _GEV(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X >= VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X then
    VM.fIRegisters[15] := 1;
end;

procedure _LTI(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] < VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] then
    VM.fIRegisters[15] := 1;
end;

procedure _LTV(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X < VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X then
    VM.fIRegisters[15] := 1;
end;

procedure _LEI(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] <= VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] then
    VM.fIRegisters[15] := 1;
end;

procedure _LEV(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X <= VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X then
    VM.fIRegisters[15] := 1;
end;

procedure _EQI(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] = VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] then
    VM.fIRegisters[15] := 1;
end;

procedure _EQV(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X = VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X then
    VM.fIRegisters[15] := 1;
end;

procedure _NEQI(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] <> VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] then
    VM.fIRegisters[15] := 1;
end;

procedure _NEQV(C: Pointer);
begin
  VM.fIRegisters[15] := 0;
  if VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X <> VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X then
    VM.fIRegisters[15] := 1;
end;

{$ENDIF}
