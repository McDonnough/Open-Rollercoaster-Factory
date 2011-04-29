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
      fPC, fSP: PtrUInt;
      Registers: Array[0..15] of TVector4D;
      procedure SetStackPointer(A: PtrUInt); inline;
      procedure Run;
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

procedure TScriptInstanceHandle.Run;
begin
end;

procedure TScriptInstanceHandle.SetStackPointer(A: PtrUInt);
begin
  fSP := A;
  if fSP + 64 >= fStack.Size then
    fStack.Expand;
end;

procedure TScriptInstanceHandle.ExecFunction(Name: String);
begin
  fPC := CodeHandle.Functions[Name];
  Run;
end;

procedure TScriptInstanceHandle.Init;
begin
  ExecFunction('__INIT__');
  fMainFunction := CodeHandle.Functions['main'];
end;

procedure TScriptInstanceHandle.Execute;
begin
  fPC := fMainFunction;
  Run;
end;

constructor TScriptInstanceHandle.Create;
begin
  fStack := TStack.Create;
  fPC := 0;
  fSP := 0;
  fMainFunction := 0;
end;

destructor TScriptInstanceHandle.Free;
begin
  fStack.Free;  
end;

end.