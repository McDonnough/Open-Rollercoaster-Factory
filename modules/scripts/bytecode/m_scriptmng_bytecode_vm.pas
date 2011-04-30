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
      fUniformSP: PtrUInt;
      procedure SetStackPointer(A: PtrUInt); inline;
    public
      CodeHandle: TBytecodeScriptHandle;
      Script: TScript;
      property SP: PtrUInt read fSP write setStackPointer;
      property Stack: TStack read fStack;
      function GetLocation(Bytes: Integer): PtrUInt;
      function GetRealPointer(Location: PtrUInt): Pointer;
      procedure Init;
      procedure Execute;
      procedure ExecFunction(Name: String);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist;

function TScriptInstanceHandle.GetLocation(Bytes: Integer): PtrUInt;
begin
  Result := SP;
  SP := SP + Bytes;
end;

function TScriptInstanceHandle.GetRealPointer(Location: PtrUInt): Pointer;
begin
  Result := fStack.FirstByte + Location;
end;

procedure TScriptInstanceHandle.SetStackPointer(A: PtrUInt);
begin
  fSP := A;
  if fSP + SizeOf(TMatrix4D) >= fStack.Size then
    fStack.Expand;
end;

procedure TScriptInstanceHandle.ExecFunction(Name: String);
begin
  if CodeHandle.Functions[Name] = 0 then
    ModuleManager.ModLog.AddWarning('Function ' + Name + ' does not exist');
  ModuleManager.ModScriptManager.VM.Run(self, CodeHandle.Functions[Name]);
end;

procedure TScriptInstanceHandle.Init;
begin
  ExecFunction('__INIT__');
  fMainFunction := CodeHandle.Functions['main'];
  if fMainFunction = 0 then
    ModuleManager.ModLog.AddError('No main function declared');
  fUniformSP := SP;
end;

procedure TScriptInstanceHandle.Execute;
begin
  ModuleManager.ModScriptManager.VM.Run(self, fMainFunction);
  SP := fUniformSP;
end;

constructor TScriptInstanceHandle.Create;
begin
  fStack := TStack.Create;
  fSP := 0;
  fUniformSP := 8;
  fMainFunction := 0;
  CodeHandle := nil;
end;

destructor TScriptInstanceHandle.Free;
begin
  fStack.Free;  
end;

end.