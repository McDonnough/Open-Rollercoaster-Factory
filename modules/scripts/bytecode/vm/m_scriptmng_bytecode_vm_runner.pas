unit m_scriptmng_bytecode_vm_runner;

interface

uses
  SysUtils, Classes, m_scriptmng_bytecode_vm_stack, m_scriptmng_bytecode_vm, m_scriptmng_bytecode_compiler, math, u_math, u_vectors,
  u_scripts;

type
  TScriptVM = class
    private
      fPC: PtrUInt;
      fRegisters: Array[0..15] of TVector4D;
      fIRegisters: Array[0..15] of SInt;
      fUpdatePC: PtrUInt;
    public
      procedure Run(TheScript: TScriptInstanceHandle; Start: PtrUInt);
      constructor Create;
    end;

{$I commands.inc}

implementation

uses
  m_varlist, m_scriptmng_bytecode_cmdlist;

var
  VM: TScriptVM;
  Script: TScriptInstanceHandle;
  Commands: TScriptCMDList;

{$DEFINE BYTECODE_IMPL}
{$I commands.inc}

procedure TScriptVM.Run(TheScript: TScriptInstanceHandle; Start: PtrUInt);
var
  Command: PScriptCommand;
  P: Pointer;
begin
  Script := TheScript;

  fPC := Start;

  try
    while fPC > 0 do
      begin
      P := fPC + TheScript.CodeHandle.FirstByte;
      Command := @Commands.List[Word(P^)];
      fUpdatePC := Command^.Length;
      Command^.Operation(P);
      inc(fPC, fUpdatePC);
      end;
  except
    ModuleManager.ModLog.AddError('Script of ' + TheScript.Script.Code.Name + ' caused exception at ' + IntToStr(fPC));
  end;
end;

constructor TScriptVM.Create;
begin
  VM := Self;
  Commands := ModuleManager.ModScriptManager.CommandList;
end;

end.