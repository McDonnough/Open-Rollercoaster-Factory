unit m_scriptmng_bytecode_classes;

interface

uses
  SysUtils, Classes;

type
  TLocationTableEntry = record
    Name: String;
    Location: PtrUInt;
    end;

  TLocationTable = class
    protected
      fEntries: Array of TLocationTableEntry;
      function Get(Name: String): PtrUInt;
      procedure Add(Name: String; Location: PtrUInt);
    public
      property Entries[Name: String]: PtrUInt read Get write Add; default;
    end;

implementation

function TLocationTable.Get(Name: String): PtrUInt;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to high(fEntries) do
    if fEntries[i].Name = Name then
      Result := fEntries[i].Location;
end;

procedure TLocationTable.Add(Name: String; Location: PtrUInt);
var
  i: Integer;
begin
  for i := 0 to high(fEntries) do
    if fEntries[i].Name = Name then
      begin
      fEntries[i].Location := Location;
      exit;
      end;
  setLength(fEntries, length(fEntries) + 1);
  fEntries[high(fEntries)].Name := Name;
  fEntries[high(fEntries)].Location := Location;
end;

end.