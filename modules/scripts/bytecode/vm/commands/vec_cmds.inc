{$IFNDEF BYTECODE_IMPL}

procedure _DOT2(C: Pointer);
procedure _DOT3(C: Pointer);
procedure _DOT4(C: Pointer);

procedure _NORM2(C: Pointer);
procedure _NORM3(C: Pointer);
procedure _NORM4(C: Pointer);

procedure _LEN2(C: Pointer);
procedure _LEN3(C: Pointer);
procedure _LEN4(C: Pointer);

procedure _CROSS(C: Pointer);


procedure _TRANSLM(C: Pointer);
procedure _ROTM(C: Pointer);
procedure _ORIENTM(C: Pointer);

{$ELSE}

procedure _DOT2(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)].X := DotProduct(TVector2D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)])^), TVector2D((@VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X)^));
end;

procedure _DOT3(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)].X := DotProduct(TVector3D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)])^), TVector3D((@VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X)^));
end;

procedure _DOT4(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)].X := DotProduct(TVector4D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)])^), TVector4D((@VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X)^));
end;


procedure _NORM2(C: Pointer);
begin
  TVector2D((@VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X)^) := Normalize(TVector2D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X)^));
end;

procedure _NORM3(C: Pointer);
begin
  TVector3D((@VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X)^) := Normalize(TVector3D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X)^));
end;

procedure _NORM4(C: Pointer);
begin
  TVector4D((@VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X)^) := Normalize(TVector4D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)].X)^));
end;


procedure _LEN2(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X := VecLength(TVector2D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)])^));
end;

procedure _LEN3(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X := VecLength(TVector3D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)])^));
end;

procedure _LEN4(C: Pointer);
begin
  VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X := VecLength(TVector4D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)])^));
end;


procedure _CROSS(C: Pointer);
begin
  TVector3D((@VM.fRegisters[Byte((C + SizeOf(Word) + 2 * SizeOf(Byte))^)].X)^) := Cross(TVector3D((@VM.fRegisters[Byte((C + SizeOf(Word) + 0 * SizeOf(Byte))^)])^), TVector3D((@VM.fRegisters[Byte((C + SizeOf(Word) + 1 * SizeOf(Byte))^)].X)^));
end;



procedure _TRANSLM(C: Pointer);
begin
  TMatrix4D((@VM.fRegisters[Byte((C + SizeOf(Word))^)].X)^) := TranslationMatrix(Vector3D(VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)]));
end;

procedure _ROTM(C: Pointer);
begin
  TMatrix4D((@VM.fRegisters[Byte((C + SizeOf(Word))^)].X)^) := RotationMatrix(VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)].W, Vector3D(VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)]));
end;

procedure _ORIENTM(C: Pointer);
begin
  TMatrix4D((@VM.fRegisters[Byte((C + SizeOf(Word))^)].X)^) := RotationMatrix(Vector3D(VM.fRegisters[Byte((C + SizeOf(Word) + SizeOf(Byte))^)]));
end;

{$ENDIF}
