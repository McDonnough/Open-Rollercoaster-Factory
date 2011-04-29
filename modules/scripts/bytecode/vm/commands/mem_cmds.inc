{$IFNDEF BYTECODE_IMPL}

// PUSH commands: Append something to the stack

procedure _PUSHI(C: Pointer);
procedure _PUSHIR(C: Pointer);
procedure _PUSHVR(C: Pointer);
procedure _PUSHMR(C: Pointer);



// POP commands: Fetch something from the end of the stack

procedure _POPI(C: Pointer);
procedure _POPV(C: Pointer);
procedure _POPM(C: Pointer);

{$ELSE}

procedure _PUSHI(C: Pointer);
begin
  PtrUInt((Script.Stack.FirstByte + Script.SP)^) := PtrUInt((C + SizeOf(Word))^);
  Script.SP := Script.SP + SizeOf(PtrUInt);
end;

procedure _PUSHIR(C: Pointer);
begin
  PtrUInt((Script.Stack.FirstByte + Script.SP)^) := VM.fIRegisters[Byte((C + SizeOf(Word))^)];
  Script.SP := Script.SP + SizeOf(PtrUInt);
end;

procedure _PUSHVR(C: Pointer);
begin
  TVector4D((Script.Stack.FirstByte + Script.SP)^) := VM.fRegisters[Byte((C + SizeOf(Word))^)];
  Script.SP := Script.SP + SizeOf(TVector4D);
end;

procedure _PUSHMR(C: Pointer);
begin
  TMatrix4D((Script.Stack.FirstByte + Script.SP)^) := TMatrix4D((@VM.fRegisters[Byte((C + SizeOf(Word))^)].X)^);
  Script.SP := Script.SP + SizeOf(TMatrix4D);
end;





procedure _POPI(C: Pointer);
begin
  Script.SP := Script.SP - SizeOf(PtrUInt);
  VM.fIRegisters[Byte((C + SizeOf(Word))^)] := PtrUInt((Script.Stack.FirstByte + Script.SP)^);
end;

procedure _POPV(C: Pointer);
begin
  Script.SP := Script.SP - SizeOf(TVector4D);
  VM.fRegisters[Byte((C + SizeOf(Word))^)] := TVector4D((Script.Stack.FirstByte + Script.SP)^);
end;

procedure _POPM(C: Pointer);
begin
  Script.SP := Script.SP - SizeOf(TMatrix4D);
  TMatrix4D((@VM.fRegisters[Byte((C + SizeOf(Word))^)].X)^) := TMatrix4D((Script.Stack.FirstByte + Script.SP)^);
end;

{$ENDIF}