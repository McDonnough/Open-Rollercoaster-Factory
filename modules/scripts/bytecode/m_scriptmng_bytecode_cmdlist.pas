unit m_scriptmng_bytecode_cmdlist;

interface

uses
  SysUtils, Classes, m_scriptmng_bytecode_vm;

type
  TScriptOperation = procedure(C: Pointer);

  TScriptCommand = record
    OPCode: Word;
    Mask: String;
    Operation: TScriptOperation;
    Length: PtrUInt;
    end;
  PScriptCommand = ^TScriptCommand;

  TScriptCMDList = class
    public
      List: Array[Word] of TScriptCommand;
      function GetByMask(S: String): TScriptCommand;
      procedure Add(A: TScriptCommand);
      constructor Create;
    end;

implementation

uses
  m_scriptmng_bytecode_vm_runner, m_varlist;

function _(A: Word; B: String; C: TScriptOperation; D: PtrUInt): TScriptCommand;
begin
  Result.OPCode := A;
  Result.Mask := B;
  Result.Operation := C;
  Result.Length := D;
end;

procedure TScriptCMDList.Add(A: TScriptCommand);
begin
  if List[A.OPCode].Operation <> nil then
    ModuleManager.ModLog.AddWarning('Command ' + A.Mask + ' overwrites ' + List[A.OPCode].Mask);
  List[A.OPCode] := A;
end;

function TScriptCMDList.GetByMask(S: String): TScriptCommand;
var
  I: Word;
begin
  Result.Operation := @_NOP;
  Result.Length := 2;
  Result.OPCode := $0000;
  Result.Mask := 'NOP';
  for i := 0 to high(List) do
    if List[i].Mask = S then
      Exit(List[i]);
end;

constructor TScriptCMDList.Create;
var
  i: Word;
begin
  // Pre-fill the list wil empties
  for i := Low(Word) to high(Word) do
    List[i].Operation := nil;


  // Stack OPs
  Add(_($0100, 'PUSHI %INT',          @_PUSHI,       SizeOf(Word) + SizeOf(PtrUInt)));
  Add(_($0101, 'PUSHIR %RINT',        @_PUSHIR,      SizeOf(Word) + SizeOf(Byte)));
  Add(_($0102, 'PUSHVR %RVEC',        @_PUSHVR,      SizeOf(Word) + SizeOf(Byte)));
  Add(_($0103, 'PUSHMR %RVEC',        @_PUSHMR,      SizeOf(Word) + SizeOf(Byte)));

  Add(_($0111, 'POPI %RINT',          @_POPI,        SizeOf(Word) + SizeOf(Byte)));
  Add(_($0112, 'POPV %RVEC',          @_POPV,        SizeOf(Word) + SizeOf(Byte)));
  Add(_($0113, 'POPM %RVEC',          @_POPM,        SizeOf(Word) + SizeOf(Byte)));


  // Replace the empties with NOPs
  for i := Low(Word) to high(Word) do
    if List[i].Operation = nil then
      Add(_(i, 'NOP', @_NOP, SizeOf(Word)));
end;

end.