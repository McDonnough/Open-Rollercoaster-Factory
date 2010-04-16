unit g_terrain;

interface

uses
  SysUtils, Classes, u_vectors, m_texmng_class, dglOpenGL, g_loader_ocf, u_dom;

type
  TTerrainMapPoint = record
    Height, Water, MinWater, MaxWater, WaterSpeed: Word;
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
    TexID: Byte;
    Name: String;
    end;

  TTerrainCollection = class
    protected
      fTexture: TTexture;
      fAutoplantTextures: Array of TTexture;
      fAutoplantResources: Array of Integer;
      fName: String;
    public
      Materials: Array[0..7] of TTerrainMaterial;
      property Name: String read fName;
      property Texture: TTexture read fTexture;
      constructor Create(FileName: String);
      destructor Free;
    end;

  TTerrain = class(TThread)
    protected
      fSizeX, fSizeY: Word;
      fMap: Array of Array of TTerrainMapPoint;
      fTmpMap: Array of Array of Word;
      fCanAdvance, fAdvancing: Boolean;
      fCollection: TTerrainCollection;
      procedure Execute; override;
      function GetHeightAtPosition(X, Y: Single): Single;
      procedure SetHeightAtPosition(X, Y, Height: Single);
      function GetTextureAtPosition(X, Y: Single): Byte;
      procedure SetTextureAtPosition(X, Y: Single; Tex: Byte);
    public
      property SizeX: Word read fSizeX;
      property SizeY: Word read fSizeY;
      property HeightMap[X: Single; Y: Single]: Single read GetHeightAtPosition write SetHeightAtPosition;
      property TexMap[X: Single; Y: Single]: Byte read GetTextureAtPosition write SetTextureAtPosition;
      property Collection: TTerrainCollection read fCollection;
      procedure ChangeCollection(S: String);
      procedure Resize(X, Y: Integer);
      procedure AdvanceAutomaticWater;
      procedure LoadDefaults;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_math, m_varlist, u_events, math, u_graphics;

type
  EInvalidFormat = class(Exception);

constructor TTerrainCollection.Create(FileName: String);
var
  i: Integer;
  fOCF: TOCFFile;
  e: TDOMElement;
  l, m: TDOMNodeList;
  tempTex: TTexImage;
  TexFormat: GLEnum;
  function LoadAutoplantTexture(ID: Integer): TTexture;
  var
    i: Integer;
  begin
    for i := 0 to high(fAutoplantTextures) do
      if fAutoplantResources[i] = id then
        exit(fAutoplantTextures[i]);
    with fOCF.Resources[ID] do
      begin
      if Format = 'tga' then
        temptex := TexFromTGA(fOCF.Bin[Section].Stream)
      else if Format = 'ocg' then
        temptex := TexFromOCG(fOCF.Bin[Section].Stream)
      else
        raise EInvalidFormat.Create('Invalid Format');
      TexFormat := GL_RGB;
      if TempTex.BPP = 32 then
        TexFormat := GL_RGBA;
      Result := TTexture.Create;
      Result.CreateNew(Temptex.Width, Temptex.Height, TexFormat);
      Result.SetClamp(GL_CLAMP, GL_CLAMP);
      Result.SetFilter(GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR_MIPMAP_LINEAR);
      Result.Fill(@TempTex.Data[0], TexFormat);
      gluBuild2DMipmaps(GL_TEXTURE_2D, TempTex.BPP div 8, Temptex.Width, Temptex.Height, TexFormat, GL_UNSIGNED_BYTE, @TempTex.Data[0]);
      end;
    setLength(fAutoplantResources, length(fAutoplantResources) + 1);
    fAutoplantResources[high(fAutoplantResources)] := ID;
    setLength(fAutoplantTextures, length(fAutoplantTextures) + 1);
    fAutoplantTextures[high(fAutoplantTextures)] := Result;
  end;
begin
  try
    fTexture := TTexture.Create;
    fOCF := TOCFFile.Create(FileName);
    e := TDOMElement((fOCF.XML.Document.GetElementsByTagName('texturecollection'))[0]);
    with TDOMElement((e.GetElementsByTagName('texture'))[0]) do
      begin
      with fOCF.Resources[StrToInt(GetAttribute('resource:id'))] do
        begin
        if Format = 'tga' then
          temptex := TexFromTGA(fOCF.Bin[Section].Stream)
        else if Format = 'ocg' then
          temptex := TexFromOCG(fOCF.Bin[Section].Stream)
        else
          raise EInvalidFormat.Create('Invalid Format');
        TexFormat := GL_RGB;
        if TempTex.BPP = 32 then
          TexFormat := GL_RGBA;
        fTexture.CreateNew(Temptex.Width, Temptex.Height, TexFormat);
        fTexture.setClamp(GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
        fTexture.SetFilter(GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR_MIPMAP_LINEAR);
        fTexture.Fill(@TempTex.Data[0], TexFormat);
        gluBuild2DMipmaps(GL_TEXTURE_2D, TempTex.BPP div 8, Temptex.Width, Temptex.Height, TexFormat, GL_UNSIGNED_BYTE, @TempTex.Data[0]);
        end;
      end;
    e := TDOMElement((fOCF.XML.Document.GetElementsByTagName('materials'))[0]);
    l := e.GetElementsByTagName('material');
    for i := 0 to high(l) do
      begin
      Materials[i].AutoplantProperties.Available := false;
      Materials[i].AutoplantProperties.Texture := nil;
      Materials[i].AutoplantProperties.Factor := 0;
      with TDOMElement(l[i]) do
        begin
        Materials[i].TexID := StrToInt(GetAttribute('texture'));
        Materials[i].Name := GetAttribute('name');
        m := GetElementsByTagName('autoplants');
        if length(m) > 0 then
          begin
          e := TDOMElement(m[0]);
          if e.getAttribute('exist') = '1' then
            with e do
              begin
              Materials[i].AutoplantProperties.Available := true;
              Materials[i].AutoplantProperties.Texture := LoadAutoplantTexture(StrToInt(GetAttribute('resource:id')));
              Materials[i].AutoplantProperties.Factor := StrToFloat(GetAttribute('count'));
              end;
          end;
        end;
      end;
    fOCF.Free;
  except
    on EInvalidFormat do ModuleManager.ModLog.AddError('Failed to create terrain collection: Invalid stream format');
    else
      ModuleManager.ModLog.AddError('Failed to load terrain collection: Internal error');
  end;
end;

destructor TTerrainCollection.Free;
var
  i: Integer;
begin
  for i := 0 to high(fAutoplantTextures) do
    fAutoplantTextures[i].Free;
  fTexture.Free;
end;



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
          MinWater := 0;
          MaxWater := 0;
          WaterSpeed := 256;
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
    fMap[(X1 + X2) div 2, (Y1 + Y2) div 2].Height := Round(Mix(Mix(fMap[X1, Y1].Height, fMap[fX2, Y1].Height, 0.5), Mix(fMap[X1, fY2].Height, fMap[fX2, fY2].Height, 0.5), 0.5) + ((10000 * sqrt(random) - 5000) * (fSizeX + fSizeY) / 1024) / (2 ** sdc));
    inc(sdc);
    subdivide(X1, Y1, (X1 + X2) div 2, (Y1 + Y2) div 2);
    subdivide((X1 + X2) div 2, Y1, X2, (Y1 + Y2) div 2);
    subdivide((X1 + X2) div 2, (Y1 + Y2) div 2, X2, Y2);
    subdivide(X1, (Y1 + Y2) div 2, (X1 + X2) div 2, Y2);
    dec(sdc);
  end;
begin
  sdc := 0;
  fSizeX := 0;
  fSizeY := 0;
  ChangeCollection('terrain/defaultcollection.ocf');
  Resize(2048, 2048);
  fMap[0, 0].Height := 5100;
  fMap[SizeX - 1, 0].Height := 5100;
  fMap[0, SizeY - 1].Height := 5100;
  fMap[SizeX - 1, SizeY - 1].Height := 5100;
  Subdivide(0, 0, SizeX, SizeY);
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
        begin
        fMap[i, j].Texture := 5;
        end;
      end;
  EventManager.CallEvent('TTerrain.ChangedAll', nil, nil);
end;

procedure TTerrain.ChangeCollection(S: String);
begin
  if fCollection <> nil then
    fCollection.Free;
  fCollection := TTerrainCollection.Create(S);
  EventManager.CallEvent('TTerrain.ChangedCollection', nil, nil);
end;

constructor TTerrain.Create;
begin
  inherited Create(true);
  fCanAdvance := false;
  fAdvancing := false;
  fCollection := nil;
  Resume;
end;

destructor TTerrain.Free;
begin
  Terminate;
  sleep(100);
  if fCollection <> nil then
    fCollection.Free;
end;

end.