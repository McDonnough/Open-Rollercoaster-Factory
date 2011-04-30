{$IFNDEF BYTECODE_IMPL}
procedure _LDV1(C: Pointer);
procedure _LDV2(C: Pointer);
procedure _LDV3(C: Pointer);
procedure _LDV4(C: Pointer);
procedure _LDI(C: Pointer);

procedure _LDISP(C: Pointer);
procedure _LDSPI(C: Pointer);

procedure _LDIA(C: Pointer);
procedure _LDV1A(C: Pointer);
procedure _LDV2A(C: Pointer);
procedure _LDV3A(C: Pointer);
procedure _LDV4A(C: Pointer);

procedure _LDAI(C: Pointer);
procedure _LDAV1(C: Pointer);
procedure _LDAV2(C: Pointer);
procedure _LDAV3(C: Pointer);
procedure _LDAV4(C: Pointer);

procedure _LDVRCVRC(C: Pointer);

procedure _LDIRIR(C: Pointer);
procedure _LDVRVR(C: Pointer);

procedure _LDVRIR(C: Pointer);
procedure _LDIRVR(C: Pointer);

{$ELSE}

procedure _LDV1(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := Vector(Single((C + SizeOf(Word) + SizeOf(Byte))^), 0, 0, 1);
end;

procedure _LDV2(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := Vector(TVector2D((C + SizeOf(Word) + SizeOf(Byte))^), 0, 1);
end;

procedure _LDV3(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := Vector(TVector3D((C + SizeOf(Word) + SizeOf(Byte))^), 1);
end;

procedure _LDV4(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := TVector4D((C + SizeOf(Word) + SizeOf(Byte))^);
end;

procedure _LDI(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word))^)] := SInt((C + SizeOf(Word) + SizeOf(Byte))^);
end;



procedure _LDISP(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word))^)] := Script.SP;
end;

procedure _LDSPI(C: Pointer);
begin
  Script.SP := VM.fIRegisters[Byte((C + SizeOf(Word))^)];
end;



procedure _LDIA(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word))^)] := SInt((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)])^);
end;

procedure _LDV1A(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := Vector(
    Single((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)])^),
    0,
    0,
    1);
end;

procedure _LDV2A(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := Vector(
    TVector2D((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)])^),
    0,
    1);
end;

procedure _LDV3A(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := Vector(
    TVector3D((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)])^),
    1);
end;

procedure _LDV4A(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := TVector4D((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)])^);
end;




procedure _LDAI(C: Pointer);
begin
  SInt((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word))^)])^) := VM.fIRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)];
end;

procedure _LDAV1(C: Pointer);
begin
  Single((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word))^)])^) := VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)].X;
end;

procedure _LDAV2(C: Pointer);
begin
  TVector2D((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word))^)])^) := Vector2D(VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)]);
end;

procedure _LDAV3(C: Pointer);
begin
  TVector3D((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word))^)])^) := Vector3D(VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)]);
end;

procedure _LDAV4(C: Pointer);
begin
  TVector4D((Script.Stack.FirstByte + VM.fIRegisters[Byte((C + SizeOf(Word))^)])^) := VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)];
end;



procedure _LDVRCVRC(C: Pointer);
begin
  Single(((@VM.fRegisters[Byte((C + SizeOf(Word))^)].X) + PtrUInt((C + SizeOf(Word) + SizeOf(Byte))^) * SizeOf(Single))^)
    := Single(((@VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte) + SizeOf(PtrUInt))^)].X) + PtrUInt((C + SizeOf(Word) + SizeOf(Byte) + SizeOf(PtrUInt) + SizeOf(Byte))^) * SizeOf(Single))^);
end;



procedure _LDIRIR(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word))^)] := VM.fIRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)];
end;

procedure _LDVRVR(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)];
end;

procedure _LDVRIR(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word))^)].X := VM.fIRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)];
end;

procedure _LDIRVR(C: Pointer);
begin
  VM.fIRegisters[Byte((C + SizeOf(Word))^)] := Round(Int(VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)].X));
end;


{$ENDIF}
