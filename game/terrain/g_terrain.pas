unit g_terrain;

interface

uses
  SysUtils, Classes, l_ocf, g_park_types, u_vectors, m_texmng_class, dglOpenGL;

type
  TTerrain = class(TParkChild)
    protected
      fTextureCollectionName: String;
      fSizeX, fSizeY: Word;
      fHeightMap: Array of Word;
      fWaterMap: Array of Word;
      fTextureOffsetMap: Array of TVector2D;
      fTextureCollection: TTexture;
      procedure SetTextureCollectionName(S: String);
      function GetHeightMap(X, Y: Single): Single;
      function GetTextureOffsetMap(X, Y: Single): TVector2D;
      function GetWaterMap(X, Y: Single): Single;
      function GetSizeX: Word;
      function GetSizeY: Word;
      procedure SetHeightMap(X, Y: Single; Z: Single);
      procedure SetTextureOffsetMap(X, Y: Single; Z: TVector2D);
      procedure SetWaterMap(X, Y: Single; Z: Single);
      procedure SetSizeX(X: Word);
      procedure SetSizeY(Y: Word);
    public
      Multiplicator: Single;
      property HeightMap[X: Single; Y: Single]: Single read GetHeightMap write SetHeightMap;
      property TextureOffsetMap[X: Single; Y: Single]: TVector2D read GetTextureOffsetMap write SetTextureOffsetMap;
      property WaterMap[X: Single; Y: Single]: Single read GetWaterMap write SetWaterMap;
      property SizeX: Word read GetSizeX write SetSizeX;
      property SizeY: Word read GetSizeY write SetSizeY;
      property TextureCollectionName: String read fTextureCollectionName write SetTextureCollectionName;
      property Texture: TTexture read fTextureCollection;
      procedure WriteOCFSection(var Section: TOCFSection);
      procedure ReadFromOCFSection(Section: TOCFSection);
      procedure LoadDefaults;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_math, m_varlist;

procedure TTerrain.SetTextureCollectionName(S: String);
var
  i, j: Integer;
begin
  fTextureCollectionName := S;
  fTextureCollection.FromFile(S, true);
  for i := 0 to 16 do
    for j := 0 to 16 do
      fTextureCollection.Pixels[i, j] := $FFFFFFFF;
end;

function TTerrain.GetHeightMap(X, Y: Single): Single;
begin
  X := Clamp(X / Multiplicator, 0, fSizeX);
  Y := Clamp(Y / Multiplicator, 0, fSizeY);
  Result := Mix(Mix(fHeightMap[Floor(X) + (fSizeX + 1) * Floor(Y)], fHeightMap[Ceil(X) + (fSizeX + 1) * Floor(Y)], FPart(X)),
                Mix(fHeightMap[Floor(X) + (fSizeX + 1) * Ceil(Y)], fHeightMap[Ceil(X) + (fSizeX + 1) * Ceil(Y)], FPart(X)),
                fPart(Y)) / 256;
end;

function TTerrain.GetTextureOffsetMap(X, Y: Single): TVector2D;
begin
  X := Clamp(Round(X / Multiplicator), 0, fSizeX);
  Y := Clamp(Round(Y / Multiplicator), 0, fSizeY);
  Result := fTextureOffsetMap[Round(X + (fSizeX + 1) * Y)];
end;

function TTerrain.GetWaterMap(X, Y: Single): Single;
begin
  X := Clamp(X / Multiplicator, 0, fSizeX);
  Y := Clamp(Y / Multiplicator, 0, fSizeY);
  Result := Mix(Mix(fWaterMap[Floor(X) + (fSizeX + 1) * Floor(Y)], fWaterMap[Ceil(X) + (fSizeX + 1) * Floor(Y)], FPart(X)),
                Mix(fWaterMap[Floor(X) + (fSizeX + 1) * Ceil(Y)], fWaterMap[Ceil(X) + (fSizeX + 1) * Ceil(Y)], FPart(X)),
                fPart(Y)) / 256;
end;

function TTerrain.GetSizeX: Word;
begin
  Result := Round(fSizeX * Multiplicator);
end;

function TTerrain.GetSizeY: Word;
begin
  Result := Round(fSizeY * Multiplicator);
end;

procedure TTerrain.SetHeightMap(X, Y: Single; Z: Single);
var
  WX, WY, WZ: Word;
begin
  X := Clamp(X / Multiplicator, 0, fSizeX);
  Y := Clamp(Y / Multiplicator, 0, fSizeY);
  WZ := Round(256 * Z);
  WX := Round(X);
  WY := Round(Y);
  fHeightMap[WX + (fSizeX + 1) * WY] := WZ;
end;

procedure TTerrain.SetTextureOffsetMap(X, Y: Single; Z: TVector2D);
begin
  X := Clamp(Round(X / Multiplicator), 0, fSizeX);
  Y := Clamp(Round(Y / Multiplicator), 0, fSizeY);
  fTextureOffsetMap[Round(X + (fSizeX + 1) * Y)] := Z;
end;

procedure TTerrain.SetWaterMap(X, Y: Single; Z: Single);
begin
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
  X := Round(X / Multiplicator);
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
  Y := Round(Y / Multiplicator);
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
  Section.Data.AppendByteArray(@fTextureCollectionName[1], tmpW);
  Section.Data.AppendByteArray(@Multiplicator, Sizeof(Single));
  tmpW := SizeX;
  Section.Data.AppendByteArray(@tmpW, Sizeof(Word));
  tmpW := SizeY;
  Section.Data.AppendByteArray(@tmpW, Sizeof(Word));
  Section.Data.AppendByteArray(@fHeightMap[0], (fSizeX + 1) * (fSizeY + 1) * Sizeof(Word));
  Section.Data.AppendByteArray(@fWaterMap[0], (fSizeX + 1) * (fSizeY + 1) * Sizeof(Word));
  Section.Data.AppendByteArray(@fTextureOffsetMap[0], (fSizeX + 1) * (fSizeY + 1) * Sizeof(TVector2D));
end;

procedure TTerrain.ReadFromOCFSection(Section: TOCFSection);
var
  tmpW: Word;
begin
  Section.Data.ReadBytes(@tmpW, SizeOf(Word));
  SetLength(fTextureCollectionName, tmpW);
  Section.Data.ReadBytes(@fTextureCollectionName[1], tmpW);
  TextureCollectionName := fTextureCollectionName;
  Section.Data.ReadBytes(@Multiplicator, SizeOf(Single));
  Section.Data.ReadBytes(@tmpW, SizeOf(Word));
  SizeX := tmpW;
  Section.Data.ReadBytes(@tmpW, SizeOf(Word));
  SizeY := tmpW;
  Section.Data.ReadBytes(@fHeightMap[0], (fSizeX + 1) * (fSizeY + 1) * SizeOf(Word));
  Section.Data.ReadBytes(@fWaterMap[0], (fSizeX + 1) * (fSizeY + 1) * SizeOf(Word));
  Section.Data.ReadBytes(@fTextureOffsetMap[0], (fSizeX + 1) * (fSizeY + 1) * SizeOf(TVector2D));
  fLoaded := true;
end;

procedure TTerrain.LoadDefaults;
begin
  if fLoaded then exit;
  Multiplicator := 2;
  SizeX := 256;
  SizeY := 256;
  TextureCollectionName := 'terrain/defaultcollection.tga';
  fLoaded := true;
end;

constructor TTerrain.Create;
begin
  fTextureCollection := TTexture.Create;
  fTextureCollection.SetClamp(GL_CLAMP, GL_CLAMP);
end;

destructor TTerrain.Free;
begin
  fTextureCollection.Free;
end;

end.