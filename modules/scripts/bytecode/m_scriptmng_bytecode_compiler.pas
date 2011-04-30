unit m_scriptmng_bytecode_compiler;

interface

uses
  SysUtils, Classes, u_scripts, m_scriptmng_bytecode_classes;

type
  TBytecodeScriptHandle = class
    protected
      fFirstByte: Pointer;
      fFunctionTable: TLocationTable;
      fGlobalLocations: TLocationTable;
    public
      Code: TScriptCode;
      ASMCode: String;
      ByteCode: Array of Byte;
      property FirstByte: Pointer read fFirstByte;
      property Functions: TLocationTable read fFunctionTable;
      property GlobalLocations: TLocationTable read fGlobalLocations;
      procedure Compile;
      procedure Assemble;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_functions;

procedure TBytecodeScriptHandle.Compile;
begin
  if SubString(Code.SourceCode, 1, 4) = 'ASM:' then
    ASMCode := Code.SourceCode;
//   else
//     begin
//     ModuleManager.ModScriptManager.Compiler.Compile(self);
//     ASMCode := ModuleManager.ModScriptManager.Compiler.Result;
//     end;
end;

procedure TBytecodeScriptHandle.Assemble;
begin
  ModuleManager.ModScriptManager.Assembler.Assemble(self);
  fFirstByte := @ByteCode[0];
  ASMCode := '';
end;

constructor TBytecodeScriptHandle.Create;
begin
  fFunctionTable := TLocationTable.Create;
  fGlobalLocations := TLocationTable.Create;
  fFirstByte := nil;
end;

destructor TBytecodeScriptHandle.Free;
begin
  fGlobalLocations.Free;
  fFunctionTable.Free;
  setLength(ByteCode, 0);
end;

end.