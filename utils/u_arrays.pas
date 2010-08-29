unit u_arrays;

interface

uses
  SysUtils, Classes;

type
  TRow = class
    protected
      fData: Array of Integer;
      procedure SetValue(X, V: Integer);
      function GetValue(X: Integer): Integer;
      function GetLength: Integer;
    public
      property Value[X: Integer]: Integer read getValue write setValue;
      property Length: Integer read GetLength;
      procedure Insert(X, V: Integer);
      procedure Delete(X: Integer);
      function HasValue(X: Integer): Boolean;
      procedure Sort;
      procedure Resize(L: Integer);
      function Extract(X, C: Integer): TRow;
      function Min: Integer;
      function Max: Integer;
      constructor Create;
      constructor Create(Count: Integer; Items: Pointer);
    end;

  TTable = class
    protected
      fData: Array of Array of Integer;
      function getValue(x, y: Integer): Integer;
      procedure setValue(x, y, val: Integer);
      function getWidth: Integer;
      function getHeight: Integer;
    public
      property Height: Integer read getHeight;
      property Width: Integer read getWidth;
      property Value[x, y: Integer]: Integer read getValue write setValue;
      procedure Resize(W, H: Integer);
      procedure InsertRow(Y: Integer; Items: TRow);
      procedure InsertCol(X: Integer; Items: TRow);
      function GetRow(Y: Integer): TRow;
      function GetCol(X: Integer): TRow;
      procedure DeleteRow(Y: Integer);
      procedure DeleteCol(X: Integer);
      procedure Injenct(OfsX, OfsY: Integer; Items: TTable);
      function HasRow(Items: TRow): Integer;
      function HasCol(Items: TRow): Integer;
      function GetPart(OfsX, OfsY, W, H: Integer): TTable;
      procedure FastCopy(D: Pointer); // WARNING: NOT FAILSAFE
      destructor Free;
    end;

implementation

uses
  u_functions, math;

procedure TRow.SetValue(X, V: Integer);
begin
  if (X >= Length) or (X < 0) then
    Exit;
  fData[X] := V;
end;

function TRow.GetValue(X: Integer): Integer;
begin
  if (X >= Length) or (X < 0) then
    Result := 0
  else
    Result := fData[X];
end;

function TRow.GetLength: Integer;
begin
  Result := High(fData) + 1;
end;

procedure TRow.Insert(X, V: Integer);
var
  i: Integer;
begin
  SetLength(fData, Length + 1);
  for i := high(fData) downto X + 1 do
    fData[i] := fData[i - 1];
  fData[X] := V;
end;

procedure TRow.Delete(X: Integer);
var
  i: Integer;
begin
  if Length <= 0 then
    Exit;
  for i := X + 1 to high(fData) do
    fData[i - 1] := fData[i];
  SetLength(fData, Length - 1);
end;

function TRow.HasValue(X: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to high(fData) do
    if fData[i] = X then
      Exit(True);
end;

procedure TRow.Sort;
  procedure DoQuicksort(Left, Right: Integer);
  var
    Splitter: Integer;
    procedure Split(Left, Right: Integer);
      procedure Swap(var X: Integer; var Y: Integer);
      var
        Z: Integer;
      begin
        Z := X;
        X := Y;
        Y := Z;
      end;
    var
      Pivot, i, j: Integer;
    begin
      Pivot := fData[Right];
      I := Left;
      J := Right - 1;

      repeat
        while (fData[i] <= Pivot) and (i < right) do
          inc(i);

        while (fData[j] >= Pivot) and (j > left) do
          dec(j);

        if i < j then
          Swap(fData[i], fData[j]);
      until
        i >= j;
      Swap(fData[i], fData[Right]);
      Splitter := i;
    end;
  begin
    if Left < Right then
      begin
      Split(Left, Right);
      DoQuicksort(Left, Splitter - 1);
      DoQuicksort(Splitter + 1, Right);
      end;
  end;
begin
  DoQuicksort(0, Length - 1);
end;

procedure TRow.Resize(L: Integer);
var
  i, j: Integer;
begin
  j := Length;
  SetLength(fData, L);
  for i := j to Length - 1 do
    fData[i] := 0;
end;

function TRow.Extract(X, C: Integer): TRow;
begin
  Result := nil;
  if (X < 0) or (X >= Length) then
    exit;
  C := Math.Min(C, Length - X);
  Result := TRow.Create(C, @fData[X]);
end;

function TRow.Min: Integer;
var
  i: Integer;
begin
  Result := Value[0];
  for i := 1 to Length - 1 do
    Result := Math.Min(Result, Value[i]);
end;

function TRow.Max: Integer;
var
  i: Integer;
begin
  Result := Value[0];
  for i := 1 to Length - 1 do
    Result := Math.Max(Result, Value[i]);
end;

constructor TRow.Create;
begin
  SetLength(fData, 0);
end;

constructor TRow.Create(Count: Integer; Items: Pointer);
var
  i: Integer;
begin
  SetLength(fData, Count);
  for i := 0 to Count - 1 do
    fData[i] := Integer((Items + i * Sizeof(Integer))^);
end;




function TTable.getValue(x, y: Integer): Integer;
begin
  Result := 0;
  if (X >= 0) and (Y >= 0) and (X < Width) and (Y < Height) then
    Result := fData[X, Y];
end;

procedure TTable.setValue(x, y, val: Integer);
begin
  if (X >= 0) and (Y >= 0) and (X < Width) and (Y < Height) then
    fData[X, Y] := Val;
end;

function TTable.getWidth: Integer;
begin
  Result := Length(fData);
end;

function TTable.getHeight: Integer;
begin
  if Width = 0 then
    Result := 0
  else
    Result := Length(fData[0]);
end;

procedure TTable.Resize(W, H: Integer);
var
  i, j: Integer;
  OW, OH: Integer;
begin
  OW := Width;
  OH := Height;
  SetLength(fData, W);
  for i := 0 to W - 1 do
    SetLength(fData[i], H);
  for i := 0 to W - 1 do
    for j := 0 to H - 1 do
      if (i >= OW) or (j >= OH) then
        fData[i, j] := 0;
end;

procedure TTable.InsertRow(Y: Integer; Items: TRow);
var
  i, j: Integer;
begin
  Resize(Max(Width, Items.Length), Height + 1);
  for i := Height - 1 downto Y + 1 do
    for j := 0 to Width - 1 do
      fData[j, i] := fData[j, i - 1];
  for i := 0 to Items.Length - 1 do
    fData[i, Y] := Items.Value[i];
end;

procedure TTable.InsertCol(X: Integer; Items: TRow);
var
  i, j: Integer;
begin
  Resize(Width + 1, Max(Height, Items.Length));
  for i := Width - 1 downto X + 1 do
    for j := 0 to Height - 1 do
      fData[i, j] := fData[i - 1, j];
  for i := 0 to Items.Length - 1 do
    fData[X, i] := Items.Value[i];
end;

function TTable.GetRow(Y: Integer): TRow;
var
  i: Integer;
begin
  Result := nil;
  if (Y >= 0) and (Y < Height) then
    begin
    Result := TRow.Create;
    for i := 0 to Width - 1 do
      Result.Insert(i, fData[i, Y]);
    end;
end;

function TTable.GetCol(X: Integer): TRow;
begin
  Result := TRow.Create(Height, @fData[X, 0]);
end;

procedure TTable.DeleteRow(Y: Integer);
var
  i, j: Integer;
begin
  if (Y < 0) or (Y >= Height) then exit;
  for i := Y + 1 to Height - 1 do
    for j := 0 to Width - 1 do
      fData[j, i - 1] := fData[j, i];
  Resize(Width, Height - 1);
end;

procedure TTable.DeleteCol(X: Integer);
var
  i, j: Integer;
begin
  if (X < 0) or (X >= Width) then exit;
  for i := X + 1 to Width - 1 do
    for j := 0 to Height - 1 do
      fData[i - 1, j] := fData[i, j];
  Resize(Width - 1, Height);
end;

procedure TTable.Injenct(OfsX, OfsY: Integer; Items: TTable);
var
  i, j: Integer;
begin
  Resize(Max(Width, OfsX + Items.Width), Max(Height, OfsY + Items.Height));
  for i := 0 to Items.Width - 1 do
    for j := 0 to Items.Height - 1 do
      Value[OfsX + i, OfsY + j] := Items.Value[i, j];
end;

function TTable.HasRow(Items: TRow): Integer;
var
  i, j: Integer;
begin
  if Width >= Items.Length then
    begin
    for j := 0 to Height - 1 do
      begin
      for i := 0 to Items.Length - 1 do
        begin
        if Value[i, j] <> Items.Value[i] then
          break;
        if i = Items.Length - 1 then
          exit(j);
        end;
      end;
    end;
  Result := -1;
end;

function TTable.HasCol(Items: TRow): Integer;
var
  i, j: Integer;
begin
  if Height >= Items.Length then
    begin
    for j := 0 to Width - 1 do
      begin
      for i := 0 to Items.Length - 1 do
        begin
        if Value[j, i] <> Items.Value[i] then
          break;
        if i = Items.Length - 1 then
          exit(j);
        end;
      end;
    end;
  Result := -1;
end;

function TTable.GetPart(OfsX, OfsY, W, H: Integer): TTable;
var
  Col: TRow;
  i, j: Integer;
begin
  Result := nil;
  if (OfsX >= Width) or (OfsY >= Height) then
    exit;
  W := Min(W, Width - OfsX);
  H := Min(H, Height - OfsY);
  Result := TTable.Create;
  for i := 0 to W - 1 do
    Result.InsertCol(i, GetCol(OfsX + i).Extract(OfsY, Height));
end;

procedure TTable.FastCopy(D: Pointer); // WARNING: NOT FAILSAFE
var
  i, j: Integer;
begin
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      begin
      Integer(D^) := fData[i, j];
      inc(D, SizeOf(Integer));
      end;
end;

destructor TTable.Free;
var
  i: Integer;
begin
  for i := 0 to high(fData) do
    SetLength(fData[i], 0);
  SetLength(fData, 0);
end;

end.