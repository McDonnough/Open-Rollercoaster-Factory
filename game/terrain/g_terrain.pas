unit g_terrain;

interface

uses
  SysUtils, Classes, l_ocf, g_park_types, u_vectors;

type
  TTerrain = class(TParkChild)
    protected
      fTextureCollectionName: String;
      fSizeX, fSizeY: Word;
      fHeightMap: Array of Word;
      fWaterMap: Array of Word;
      fTextureOffsetMap: Array of TVector2D;
      function GetHeightMap(X, Y: Single): Single;
      procedure SetHeightMap(X, Y: Single; Z: Single);
      procedure SetSizeX(X: Word);
      procedure SetSizeY(Y: Word);
    public
      property HeightMap[X: Single; Y: Single]: Single read GetHeightMap write SetHeightMap;
      property SizeX: Word read fSizeX write SetSizeX;
      property SizeY: Word read fSizeY write SetSizeY;
      procedure WriteOCFSection(var Section: TOCFSection);
      procedure ReadFromOCFSection(Section: TOCFSection);
    end;

implementation

uses
  u_math;

function TTerrain.GetHeightMap(X, Y: Single): Single;
begin
  X := Clamp(X, 0, fSizeX);
  Y := Clamp(Y, 0, fSizeY);
  Result := Mix(Mix(fHeightMap[Floor(X) + (fSizeX + 1) * Floor(Y)], fHeightMap[Ceil(X) + (fSizeX + 1) * Floor(Y)], FPart(X)),
                Mix(fHeightMap[Floor(X) + (fSizeX + 1) * Ceil(Y)], fHeightMap[Ceil(X) + (fSizeX + 1) * Ceil(Y)], FPart(X)),
                fPart(Y)) / 256;
end;

procedure TTerrain.SetHeightMap(X, Y: Single; Z: Single);
var
  WX, WY, WZ: Word;
begin
  X := Clamp(X, 0, fSizeX);
  Y := Clamp(Y, 0, fSizeY);
  WZ := Round(256 * Z);
  WX := Round(X);
  WY := Round(Y);
  fHeightMap[WX + (fSizeX + 1) * WY] := WZ;
end;

procedure TTerrain.SetSizeX(X: Word);
  procedure AdjustMapSize;
  begin
    SetLength(fHeightMap, (X + 1) * (fSizeY + 1));
    SetLength(fWaterMap, (X + 1) * (fSizeY + 1));
    SetLength(fTextureOffsetMap, (X + 1) * (fSizeY + 1));
  end;
var
  i, j: Integer;
  CP: Integer;
begin
  if X = fSizeX then
    exit
  else if X > fSizeX then
    begin
    AdjustMapSize;
    CP := (fSizeX + 1) * (fSizeY + 1) - 1;
    for i := fSizeY downto 0 do
      begin
      for j := X downto 0 do
        if j <= fSizeX then
          begin
          fHeightMap[(X + 1) * i + j] := fHeightMap[CP];
          fWaterMap[(X + 1) * i + j] := fWaterMap[CP];
          fTextureOffsetMap[(X + 1) * i + j] := fTextureOffsetMap[CP];
          Dec(CP);
          end
        else
          begin
          fHeightMap[(X + 1) * i + j] := 0;
          fWaterMap[(X + 1) * i + j] := 0;
          fTextureOffsetMap[(X + 1) * i + j] := Vector(0, 0);
          end;
      end;
    end
  else
    begin
    CP := 0;
    for i := 0 to fSizeY do
      begin
      for j := 0 to fSizeX do
        if j <= X then
          begin
          fHeightMap[CP] := fHeightMap[(fSizeX + 1) * i + j];
          fWaterMap[CP] := fWaterMap[(fSizeX + 1) * i + j];
          fTextureOffsetMap[CP] := fTextureOffsetMap[(fSizeX + 1) * i + j];
          Inc(CP);
          end;
      end;
    AdjustMapSize;
    end;
  fSizeX := X;
end;

procedure TTerrain.SetSizeY(Y: Word);
var
  i: integer;
begin
  SetLength(fHeightMap, (fSizeX + 1) * (Y + 1));
  SetLength(fWaterMap, (fSizeX + 1) * (Y + 1));
  SetLength(fTextureOffsetMap, (fSizeX + 1) * (Y + 1));
  for i := (fSizeX + 1) * (fSizeY + 1) to (fSizeX + 1) * (Y + 1) - 1 do
    begin
    fHeightMap[i] := 0;
    fWaterMap[i] := 0;
    fTextureOffsetMap[i] := Vector(0, 0);
    end;
  fSizeY := Y;
end;


procedure TTerrain.WriteOCFSection(var Section: TOCFSection);
var
  tmpW: Word;
begin
  Section.SectionType := 'Terrain';
  tmpw := Length(fTextureCollectionName);
  Section.Data.CopyFromByteArray(@tmpW, Sizeof(Word));
  Section.Data.AppendByteArray(@fSizeX, 2 * Sizeof(Word));
  Section.Data.AppendByteArray(@fHeightMap[0], (fSizeX + 1) * (fSizeY + 1) * Sizeof(Word));
  Section.Data.AppendByteArray(@fWaterMap[0], (fSizeX + 1) * (fSizeY + 1) * Sizeof(Word));
  Section.Data.AppendByteArray(@fTextureOffsetMap[0], (fSizeX + 1) * (fSizeY + 1) * Sizeof(TVector2D));
end;

procedure TTerrain.ReadFromOCFSection(Section: TOCFSection);
begin
end;

end.