unit m_scriptmng_bytecode_vm_stack;

interface

uses
  SysUtils, Classes;

type
  TStack = class
    protected
      fFirstElementPointer: Pointer;
      fSize: Integer;
      fData: Array of Byte;
    public
      property FirstByte: Pointer read fFirstElementPointer;
      property Size: Integer read fSize;
      procedure Expand;
      constructor Create;
      destructor Free;
    end;

implementation

procedure TStack.Expand;
begin
  fSize := fSize + 1024;
  setLength(fData, fSize);
  fFirstElementPointer := @fData[0];
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