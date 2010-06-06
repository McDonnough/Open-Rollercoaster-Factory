unit g_terrain;

interface

uses
  SysUtils, Classes, u_vectors, m_texmng_class, dglOpenGL, g_loader_ocf, u_dom;

type
  TTerrainMapPoint = record
    Height, Water: Word;
    Texture: Byte;
    end;

  TTerrainAutoplantProperties = record
    Factor: Single;
    Texture: TTexture;
    Available: Boolean;
    end;

  TTerrainParticleProperties = record
    Available: Boolean;
    end;

  TTerrainMaterial = record
    AutoplantProperties: TTerrainAutoplantProperties;
    ParticleProperties: TTerrainParticleProperties;
    Texture: TTexture;
    Name: String;
    end;

  ATerrainMaterial = array of TTerrainMaterial;

  TTerrain = class(TThread)
    protected
      fSizeX, fSizeY: Word;
      fMap: Array of Array of TTerrainMapPoint;
      fTmpMap: Array of Array of Word;
      fCanAdvance, fAdvancing: Boolean;
      fMaterials: ATerrainMaterial;
      procedure Execute; override;
      function GetHeightAtPosition(X, Y: Single): Single;
      procedure SetHeightAtPosition(X, Y, Height: Single);
      function GetWaterAtPosition(X, Y: Single): Single;
      procedure SetWaterAtPosition(X, Y, Height: Single);
      function GetTextureAtPosition(X, Y: Single): Byte;
      procedure SetTextureAtPosition(X, Y: Single; Tex: Byte);
    public
      property SizeX: Word read fSizeX;
      property SizeY: Word read fSizeY;
      property HeightMap[X: Single; Y: Single]: Single read GetHeightAtPosition write SetHeightAtPosition;
      property WaterMap[X: Single; Y: Single]: Single read GetWaterAtPosition write SetWaterAtPosition;
      property TexMap[X: Single; Y: Single]: Byte read GetTextureAtPosition write SetTextureAtPosition;
      property Materials: ATerrainMaterial read fMaterials;
      procedure Resize(X, Y: Integer);
      procedure AdvanceAutomaticWater;
      procedure LoadDefaults;
      procedure AddMaterial(RC: String);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_math, m_varlist, u_events, math, u_files, u_graphics, u_functions;

type
  EInvalidFormat = class(Exception);

procedure TTerrain.Execute;
var
  fTime, fDiff: UInt64;
begin
  while not Terminated do
    begin
    fTime := ModuleManager.ModGUITimer.GetTime;
    if fCanAdvance then
      begin
      fAdvancing := true;
      AdvanceAutomaticWater;
      fAdvancing := false;
      end;
    fDiff := ModuleManager.ModGUITimer.GetTime - fTime;
    sleep(Max(10, 25 - fDiff));
    end;
end;

function TTerrain.GetHeightAtPosition(X, Y: Single): Single;
var
  fX1, fX2, fY1, fY2: Word;
begin
  fX1 := Floor(Clamp(5 * X, 0, fSizeX - 1));
  fX2 := Ceil(Clamp(5 * X, 0, fSizeX - 1));
  fY1 := Floor(Clamp(5 * Y, 0, fSizeY - 1));
  fY2 := Ceil(Clamp(5 * Y, 0, fSizeY - 1));
  Result := Mix(Mix(fMap[fX1, fY1].Height, fMap[fX2, fY1].Height, fPart(5 * X)), Mix(fMap[fX1, fY2].Height, fMap[fX2, fY2].Height, fPart(5 * X)), fPart(5 * Y)) / 256;
end;

procedure TTerrain.SetHeightAtPosition(X, Y, Height: Single);
var
  fX, fY: Word;
  fFinal: DWord;
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  fMap[fX, fY].Height := Round(256 * Height);
  fFinal := fX + 65536 * fY;
  EventManager.CallEvent('TTerrain.Changed', @fFinal, nil);
end;

function TTerrain.GetWaterAtPosition(X, Y: Single): Single;
var
  fX1, fX2, fY1, fY2: Word;
begin
  fX1 := Floor(Clamp(5 * X, 0, fSizeX - 1));
  fX2 := Ceil(Clamp(5 * X, 0, fSizeX - 1));
  fY1 := Floor(Clamp(5 * Y, 0, fSizeY - 1));
  fY2 := Ceil(Clamp(5 * Y, 0, fSizeY - 1));
  Result := Mix(Mix(fMap[fX1, fY1].Water, fMap[fX2, fY1].Water, fPart(5 * X)), Mix(fMap[fX1, fY2].Water, fMap[fX2, fY2].Water, fPart(5 * X)), fPart(5 * Y)) / 256;
end;

procedure TTerrain.SetWaterAtPosition(X, Y, Height: Single);
var
  fX, fY: Word;
  fFinal: DWord;
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  fMap[fX, fY].Water := Round(256 * Height);
  fFinal := fX + 65536 * fY;
  EventManager.CallEvent('TTerrain.Changed', @fFinal, nil);
end;

function TTerrain.GetTextureAtPosition(X, Y: Single): Byte;
var
  fX, fY: Word;
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  Result := fMap[fX, fY].Texture;
end;

procedure TTerrain.SetTextureAtPosition(X, Y: Single; Tex: Byte);
var
  fX, fY: Word;
  fFinal: DWord;
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  fMap[fX, fY].Texture := Tex;
  EventManager.CallEvent('TTerrain.Changed', @fFinal, nil);
end;

procedure TTerrain.Resize(X, Y: Integer);
var
  i, j: Integer;
begin
  fCanAdvance := false;
  while fAdvancing do
    sleep(1);
  SetLength(fMap, X);
  SetLength(fTmpMap, X);
  for i := 0 to high(fMap) do
    begin
    SetLength(fMap[i], Y);
    SetLength(fTmpMap[i], Y);
    for j := 0 to high(fMap[i]) do
      if (i >= fSizeX) or (j >= fSizeY) then
        with fMap[i, j] do
          begin
          Height := 1024;
          Water := 0;
          Texture := 0;
          end;
    end;
  fSizeX := X;
  fSizeY := Y;
  EventManager.CallEvent('TTerrain.Resize', @X, nil);
  EventManager.CallEvent('TTerrain.Changed', nil, nil);
  fCanAdvance := true;
end;

procedure TTerrain.AdvanceAutomaticWater;
begin
  try
  except
    writeln('Exception');
  end;
end;

procedure TTerrain.LoadDefaults;
var
  i, j: Integer;
  sdc: Integer;
  procedure subdivide(X1, Y1, X2, Y2: Integer);
  var
    i, fX2, fY2: Integer;
  begin
    if (X1 = X2 - 1) or (Y1 = Y2 - 1) then
      exit;
    fX2 := Round(Min(X2, SizeX - 1));
    fY2 := Round(Min(Y2, SizeY - 1));
    fMap[(X1 + X2) div 2, Y1].Height := Round(Mix(fMap[X1, Y1].Height, fMap[fX2, Y1].Height, 0.5));
    fMap[(X1 + X2) div 2, fY2].Height := Round(Mix(fMap[X1, fY2].Height, fMap[fX2, fY2].Height, 0.5));
    fMap[X1, (Y1 + Y2) div 2].Height := Round(Mix(fMap[X1, Y1].Height, fMap[X1, fY2].Height, 0.5));
    fMap[fX2, (Y1 + Y2) div 2].Height := Round(Mix(fMap[fX2, Y1].Height, fMap[fX2, fY2].Height, 0.5));
    fMap[(X1 + X2) div 2, (Y1 + Y2) div 2].Height := Round(Mix(Mix(fMap[X1, Y1].Height, fMap[fX2, Y1].Height, 0.5), Mix(fMap[X1, fY2].Height, fMap[fX2, fY2].Height, 0.5), 0.5) + ((10000 * sqrt(random) - 5000) * (fSizeX + fSizeY) / 1024) * 2 / (2 ** sdc));
    inc(sdc);
    subdivide(X1, Y1, (X1 + X2) div 2, (Y1 + Y2) div 2);
    subdivide((X1 + X2) div 2, Y1, X2, (Y1 + Y2) div 2);
    subdivide((X1 + X2) div 2, (Y1 + Y2) div 2, X2, Y2);
    subdivide(X1, (Y1 + Y2) div 2, (X1 + X2) div 2, Y2);
    dec(sdc);
  end;

  procedure FillWithWater(X, Y, H: Word);
  var
    a: Array of Array[0..1] of Word;
    i: integer;
    procedure Add(X, Y: Word);
    begin
      if (X >= 0) and (X < SizeX) and (Y >= 0) and (Y < SizeY) then
        if fMap[X, Y].Water <> H then
          begin
          SetLength(a, Length(a) + 1);
          a[high(a), 0] := X;
          a[high(a), 1] := Y;
          fMap[X, Y].Water := H;
          end;
    end;
  begin
    setLength(a, 1);
    a[0, 0] := X;
    a[0, 1] := Y;
    i := 0;
    while i <= high(a) do
      begin
      fMap[a[i, 0], a[i, 1]].Water := H;
      if fMap[a[i, 0], a[i, 1]].Height < H then
        begin
        Add(a[i, 0] - 1, a[i, 1] - 1);
        Add(a[i, 0] - 1, a[i, 1]    );
        Add(a[i, 0] - 1, a[i, 1] + 1);
        Add(a[i, 0]    , a[i, 1] + 1);
        Add(a[i, 0] + 1, a[i, 1] + 1);
        Add(a[i, 0] + 1, a[i, 1]    );
        Add(a[i, 0] + 1, a[i, 1] - 1);
        Add(a[i, 0]    , a[i, 1] - 1);
        end;
      inc(i);
      end;
  end;

  procedure MakeMountain(X, Y, Radius: Word; Height: Single);
  var
    i, j: Integer;
  begin
    for i := -Radius to Radius do
      for j := -Radius to Radius do
        begin
        if i * i + j * j > Radius * Radius then
          continue;
        fMap[X + i, Y + j].Height := Round(Mix(fMap[X + i, Y + j].Height, 256 * Height, (0.5 + 0.5 * Cos(i / Radius * 3.141592)) * (0.5 + 0.5 * Cos(j / Radius * 3.141592))));
        end;
  end;
begin
  sdc := 0;
  fSizeX := 0;
  fSizeY := 0;
  AddMaterial('terrain/grass.ocg');
  AddMaterial('terrain/rock.ocg');
  AddMaterial('terrain/sand.ocg');
  Resize(512, 512);
  fMap[0, 0].Height := 20000;
  fMap[SizeX - 1, 0].Height := 20000;
  fMap[0, SizeY - 1].Height := 20000;
  fMap[SizeX - 1, SizeY - 1].Height := 20000;
  Subdivide(0, 0, SizeX, SizeY);
//   FillWithWater(0, 0, 28000);
  for i := 1 to SizeX - 2 do
    for j := 1 to SizeY - 2 do
      fMap[i, j].Height := Round(0.3 * fMap[i + 0, j + 0].Height
                         + 0.125 * fMap[i + 1, j + 0].Height
                         + 0.125 * fMap[i + 0, j + 1].Height
                         + 0.125 * fMap[i - 1, j + 0].Height
                         + 0.125 * fMap[i + 0, j - 1].Height
                         + 0.050 * fMap[i + 1, j + 1].Height
                         + 0.050 * fMap[i - 1, j + 1].Height
                         + 0.050 * fMap[i - 1, j - 1].Height
                         + 0.050 * fMap[i + 1, j - 1].Height);
  for i := 1 to SizeX - 1 do
    for j := 1 to SizeY - 1 do
      begin
      if (abs((fMap[i, j].Height - fMap[i - 1, j].Height) / 0.2) > 200)
      or (abs((fMap[i, j].Height - fMap[i - 1, j - 1].Height) / 0.282) > 200)
      or (abs((fMap[i, j].Height - fMap[i, j - 1].Height) / 0.2) > 200) then
        fMap[i, j].Texture := 1;
      if fMap[i, j].Height < fMap[i, j].Water then
        fMap[i, j].Texture := 2;
      end;
  EventManager.CallEvent('TTerrain.ChangedAll', nil, nil);
end;

procedure TTerrain.AddMaterial(RC: String);
var
  fOCF: TOCFFile;
  BS: TTexImage;
  E: TDOMElement;
  Format, NCFormat: GLEnum;
begin
  SetLength(fMaterials, length(fMaterials) + 1);
  fOCF := TOCFFile.Create(GetFirstExistingFilename(RC));
  with fMaterials[high(fMaterials)] do
    begin
    ParticleProperties.Available := false;
    AutoplantProperties.Available := false;
    AutoplantProperties.Texture := nil;
    E := TDOMElement(fOCF.XML.Document.GetElementsByTagName('material')[0]);
    Name := E.GetAttribute('name');
    E := TDOMElement(E.FirstChild);
    while E <> nil do
      begin
      if E.NodeName = 'texture' then
        begin
        BS := TexFromStream(fOCF.Bin[fOCF.Resources[StrToIntWD(E.GetAttribute('resource:id'), 0)].Section].Stream, '.' + fOCF.Resources[StrToIntWD(E.GetAttribute('resource:id'), 0)].Format);
        Texture := TTexture.Create;
        Format := GL_COMPRESSED_RGB;
        NCFormat := GL_RGB;
        if BS.BPP = 32 then
          begin
          Format := GL_COMPRESSED_RGBA;
          NCFormat := GL_RGBA;
          end;
        Texture.CreateNew(BS.Width, BS.Height, Format);
        gluBuild2DMipmaps(GL_TEXTURE_2D, BS.BPP div 8, BS.Width, BS.Height, NCFormat, GL_UNSIGNED_BYTE, @BS.Data[0]);
        Texture.Unbind;
        end
      else if E.NodeName = 'autoplant' then
        begin
        if E.GetAttribute('exist') = '1' then
          begin
          AutoplantProperties.Available := true;
          AutoplantProperties.Factor := StrToFloatWD(E.GetAttribute('factor'), 1);
          BS := TexFromStream(fOCF.Bin[fOCF.Resources[StrToIntWD(E.GetAttribute('resource:id'), 1)].Section].Stream, '.' + fOCF.Resources[StrToIntWD(E.GetAttribute('resource:id'), 1)].Format);
          AutoplantProperties.Texture := TTexture.Create;
          Format := GL_COMPRESSED_RGB;
          NCFormat := GL_RGB;
          if BS.BPP = 32 then
            begin
            Format := GL_COMPRESSED_RGBA;
            NCFormat := GL_RGBA;
            end;
          AutoplantProperties.Texture.CreateNew(BS.Width, BS.Height, Format);
          gluBuild2DMipmaps(GL_TEXTURE_2D, BS.BPP div 8, BS.Width, BS.Height, NCFormat, GL_UNSIGNED_BYTE, @BS.Data[0]);
          AutoplantProperties.Texture.Unbind;
          end;
        end;
      E := TDOMElement(E.NextSibling);
      end;
    end;
  fOCF.Free;
  EventManager.CallEvent('TTerrain.AddMaterial', @fMaterials[high(fMaterials)], nil);
end;

constructor TTerrain.Create;
begin
  try
    inherited Create(true);
    fCanAdvance := false;
    fAdvancing := false;
    Resume;
  except
    ModuleManager.ModLog.AddError('Could not create terrain: Internal error');
  end;
end;

destructor TTerrain.Free;
var
  i: Integer;
begin
  Terminate;
  sleep(100);
  for i := 0 to high(Materials) do
    begin
    Materials[i].Texture.Free;
    if Materials[i].AutoplantProperties.Texture <> nil then
      Materials[i].AutoplantProperties.Texture.Free;
    end;
end;

end.
