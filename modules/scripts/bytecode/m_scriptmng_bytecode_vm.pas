unit m_scriptmng_bytecode_vm;

interface

uses
  SysUtils, Classes, u_scripts, m_scriptmng_bytecode_vm_stack, m_scriptmng_bytecode_compiler, m_scriptmng_bytecode_classes,
  u_vectors;

type
  TScriptInstanceHandle = class
    protected
      fMainFunction: PtrUInt;
      fStack: TStack;
      fSP: PtrUInt;
      procedure SetStackPointer(A: PtrUInt); inline;
    public
      CodeHandle: TBytecodeScriptHandle;
      Script: TScript;
      property SP: PtrUInt read fSP write setStackPointer;
      property Stack: TStack read fStack;
      procedure Init;
      procedure Execute;
      procedure ExecFunction(Name: String);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist;

procedure TScriptInstanceHandle.SetStackPointer(A: PtrUInt);
begin
  fSP := A;
  if fSP + SizeOf(TMatrix4D) >= fStack.Size then
    fStack.Expand;
end;

procedure TScriptInstanceHandle.ExecFunction(Name: String);
begin
  ModuleManager.ModScriptManager.VM.Run(self, CodeHandle.Functions[Name]);
end;

procedure TScriptInstanceHandle.Init;
begin
  ExecFunction('__INIT__');
  fMainFunction := CodeHandle.Functions['main'];
end;

procedure TScriptInstanceHandle.Execute;
begin
  ModuleManager.ModScriptManager.VM.Run(self, fMainFunction);
end;

constructor TScriptInstanceHandle.Create;
begin
  fStack := TStack.Create;
  fSP := SizeOf(Pointer);
  fMainFunction := 0;
end;

destructor TScriptInstanceHandle.Free;
begin
  fStack.Free;  
end;

end.