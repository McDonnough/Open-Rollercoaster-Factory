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
  WZ := 256 * Round(Z);
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
  CVE, i: Integer;
begin
  if X = fSizeX then
    exit
  else if X > fSizeX then
    begin
    AdjustMapSize;

    end
  else
    begin
    CVE := 0;
    for i := 0 to high(fHeightMap) do
      if X <= FPart(i / (fSizeX + 1)) * (fSizeX + 1) then
        begin
        fHeightMap[CVE] := fHeightMap[i];
        end;
    AdjustMapSize;
    end;
  fSizeX := X;
end;

procedure TTerrain.SetSizeY(Y: Word);
begin
  fSizeY := Y;
  SetLength(fHeightMap, (fSizeX + 1) * (fSizeY + 1));
  SetLength(fWaterMap, (fSizeX + 1) * (fSizeY + 1));
  SetLength(fTextureOffsetMap, (fSizeX + 1) * (fSizeY + 1));
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