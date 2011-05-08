unit u_scripts;

interface

uses
  SysUtils, Classes;

type
  {$IFDEF CPU64}
  SInt = Int64;
  {$ELSE}
  SInt = Integer;
  {$ENDIF}

  TScript = class;

  TScriptCode = class
    protected
      fSourceCode: String;
    public
      Name: String;
      property SourceCode: String read fSourceCode;
      function CreateInstance: TScript;
      constructor Create(Code: String);
      destructor Free;
    end;

  TIOSection = record
    Data: Pointer;
    Bytes: Integer;
    Writeback: Boolean;
    Location: PtrUInt;
    end;

  TScript = class
    private
      fCode: TScriptCode;
      fIOSections: Array of TIOSection;
      fIOSectionCount: Integer;
    public
      property Code: TScriptCode read fCode;
      procedure Execute;
      procedure SetIO(Data: PByte; Bytes: Integer; Writeback: Boolean = False);
      procedure SetGlobal(Name: String; Data: PByte; Bytes: Integer);
      constructor Create;
      destructor Free;
    end;
  

implementation

uses
  m_varlist;

function TScriptCode.CreateInstance: TScript;
begin
  Result := TScript.Create;
  Result.fCode := self;
  ModuleManager.ModScriptManager.AddScript(Result);
end;

constructor TScriptCode.Create(Code: String);
begin
  fSourceCode := Code;
end;

destructor TScriptCode.Free;
begin
  ModuleManager.ModScriptManager.DestroyCode(Self);
end;


procedure TScript.Execute;
var
  I: Integer;
  J: PtrUInt;
  P: PByte;
begin
  ModuleManager.ModScriptManager.Execute(Self);
  for i := 0 to fIOSectionCount - 1 do
    if fIOSections[i].Writeback then
      begin
      P := ModuleManager.ModScriptManager.GetRealPointer(self, fIOSections[i].Location);
      for j := 0 to fIOSections[i].Bytes - 1 do
        Byte((fIOSections[i].Data + j)^) := (P + j)^;
      end;
  fIOSectionCount := 0;
end;

procedure TScript.SetIO(Data: PByte; Bytes: Integer; Writeback: Boolean = False);
var
  I: PtrUInt;
  P: PByte;
begin
  inc(fIOSectionCount);
  if fIOSectionCount > length(fIOSections) then
    setLength(fIOSections, length(fIOSections) + 16);
  fIOSections[fIOSectionCount - 1].Data := Data;
  fIOSections[fIOSectionCount - 1].Bytes := Bytes;
  fIOSections[fIOSectionCount - 1].Writeback := Writeback;
  fIOSections[fIOSectionCount - 1].Location := ModuleManager.ModScriptManager.GetLocation(self, Bytes);
  P := ModuleManager.ModScriptManager.GetRealPointer(self, fIOSections[fIOSectionCount - 1].Location);
  for i := 0 to Bytes - 1 do
    (P + i)^ := (Data + i)^;
end;

procedure TScript.SetGlobal(Name: String; Data: PByte; Bytes: Integer);
begin
  ModuleManager.ModScriptManager.SetGlobal(Self, Name, Data, Bytes);
end;

constructor TScript.Create;
begin
  fIOSectionCount := 0;
  SetLength(fIOSections, 16);
end;

destructor TScript.Free;
begin
  ModuleManager.ModScriptManager.DestroyScript(Self);
end;


end.