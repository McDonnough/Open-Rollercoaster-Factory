// Inlcude other files
{$I mem_cmds.inc}


// Define an operation that does.. nothing
{$IFNDEF BYTECODE_IMPL}
procedure _NOP(C: Pointer);

{$ELSE}

procedure _NOP(C: Pointer);
begin
end;
{$ENDIF}
