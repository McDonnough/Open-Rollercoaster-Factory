unit m_scriptmng_bytecode_compiler_asm_optimizer;

interface

uses
  SysUtils, Classes, m_scriptmng_bytecode_compiler_code_generator;

type
  TASMOptimizer = class
    protected
      function GenerateRealASMCode(Table: TASMTable): String;
    public
      function Optimize(Table: TASMTable): String;
    end;

implementation

function TASMOptimizer.GenerateRealASMCode(Table: TASMTable): String;
var
  i, j: Integer;
begin
  Result := 'ASM:' + #10;

  for i := 0 to high(Table.Commands) do
    if length(Table.Commands[i]) > 0 then
      begin
      Result += Table.Commands[i, 0];
      for j := 1 to high(Table.Commands[i]) do
        Result += ' ' + Table.Commands[i, j];
      Result += #10;
      end;
end;


function TASMOptimizer.Optimize(Table: TASMTable): String;
begin

  Result := GenerateRealASMCode(Table);
  writeln(Result);
end;

end.