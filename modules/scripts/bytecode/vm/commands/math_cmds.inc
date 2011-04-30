{$IFNDEF BYTECODE_IMPL}

procedure _ADDI(C: Pointer);
procedure _ADDV(C: Pointer);

procedure _SUBI(C: Pointer);
procedure _SUBV(C: Pointer);

procedure _MULI(C: Pointer);
procedure _MULV(C: Pointer);

procedure _DIVI(C: Pointer);
procedure _DIVV(C: Pointer);


procedure _MULMV(C: Pointer);
procedure _MULMM(C: Pointer);


procedure _RNDI(C: Pointer);
procedure _RNDV(C: Pointer);

procedure _SQRT(C: Pointer);
procedure _POW(C: Pointer);

{$ELSE}

procedure _ADDI(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] + VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;

procedure _ADDV(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] + VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;


procedure _SUBI(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] - VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;

procedure _SUBV(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] - VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;


procedure _MULI(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] * VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;

procedure _MULV(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] * VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;


procedure _DIVI(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fIRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] div VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;

procedure _DIVV(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)] / VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)];
end;



procedure _MULMV(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] * TMatrix4D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X)^);
end;

procedure _MULMM(C: Pointer);
begin
  TMatrix4D((@VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)].X)^) := TMatrix4D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X)^) * TMatrix4D((@VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X)^);
end;



procedure _RNDI(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] := Round(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X);
end;

procedure _RNDV(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] := Vector(
    Round(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X),
    Round(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].Y),
    Round(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].Z),
    Round(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].W));
end;


procedure _SQRT(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)] := Vector(
    Sqrt(Abs(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X)),
    Sqrt(Abs(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].Y)),
    Sqrt(Abs(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].Z)),
    Sqrt(Abs(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].W)));
end;

procedure _POW(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)] := Vector(
    Power(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X, VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X),
    Power(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].Y, VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].Y),
    Power(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].Z, VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].Z),
    Power(VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].W, VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].W));
end;

{$ENDIF}
