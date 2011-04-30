unit m_scriptmng_bytecode_vm_stack;

interface

uses
  SysUtils, Classes;

type
  TStack = class
    protected
      fSize: Integer;
      fData: Array of Byte;
      function getFirstElementPointer: Pointer;
    public
      property FirstByte: Pointer read getFirstElementPointer;
      property Size: Integer read fSize;
      procedure Expand;
      constructor Create;
      destructor Free;
    end;

implementation

function TStack.getFirstElementPointer: Pointer;
begin
  Result := @fData[0];
end;

procedure TStack.Expand;
begin
  fSize := fSize + 1024;
  setLength(fData, fSize);
end;

constructor TStack.Create;
begin
  fSize := 0;
  Expand;
end;

destructor TStack.Free;
begin
  SetLength(fData, 0);
end;

end.