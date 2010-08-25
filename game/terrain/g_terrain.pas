unit g_terrain;

interface

uses
  SysUtils, Classes, u_vectors, m_texmng_class, dglOpenGL, g_loader_ocf, u_dom, u_arrays;

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

  TTerrain = class
    protected
      fSizeX, fSizeY: Word;
      fWaterOnly: Boolean;
      fMap: Array of Array of TTerrainMapPoint;
      fTmpMap: Array of Array of Word;
      fCanAdvance, fAdvancing: Boolean;
      fCollection: TTerrainCollection;
      fCoordsToUpdate: Array of Integer;
      fMarks, fMarkMap: TTable;
      MinX, MinY, MaxX, MaxY: Integer;
      function GetHeightAtPosition(X, Y: Single): Single;
      procedure SetHeightAtPosition(X, Y, Height: Single);
      function GetWaterAtPosition(X, Y: Single): Single;
      procedure SetWaterAtPosition(X, Y, Height: Single);
      function GetTextureAtPosition(X, Y: Single): Byte;
      procedure SetTextureAtPosition(X, Y: Single; Tex: Byte);
      function CreateRaiseLowerMap: Integer;
    public
      CurrMark: TVector2D;
      MarkMode: Integer;
      property SizeX: Word read fSizeX;
      property SizeY: Word read fSizeY;
      property HeightMap[X: Single; Y: Single]: Single read GetHeightAtPosition write SetHeightAtPosition;
      property WaterMap[X: Single; Y: Single]: Single read GetWaterAtPosition write SetWaterAtPosition;
      property TexMap[X: Single; Y: Single]: Byte read GetTextureAtPosition write SetTextureAtPosition;
      property Collection: TTerrainCollection read fCollection;
      property Marks: TTable read fMarks;
      procedure FillWithWater(X, Y, H: Single);
      procedure RemoveWater(X, Y: Single; Notify: Boolean = true);
      procedure ChangeCollection(S: String);
      procedure Resize(X, Y: Integer);
      procedure LoadDefaults;
      procedure BeginUpdate;
      procedure EndUpdate;
      procedure CreateMarkMap;
      procedure SetTo(Height: Single);
      procedure SetToMin(Height: Single);
      procedure SetToMax(Height: Single);
      procedure RaiseTo(Height: Single = -1);
      procedure LowerTo(Height: Single = -1);
      procedure Smooth;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_math, m_varlist, u_events, math, u_graphics, u_functions;

type
  EInvalidFormat = class(Exception);

constructor TTerrainCollection.Create(FileName: String);
var
  i: Integer;
  fOCF: TOCFFile;
  e: TDOMElement;
  l, m: TDOMNodeList;
  tempTex: TTexImage;
  CompressedTexFormat, TexFormat: GLEnum;
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
      else if Format = 'dbcg' then
        temptex := TexFromDBCG(fOCF.Bin[Section].Stream)
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
        TempTex := TexFromStream(fOCF.Bin[Section].Stream, '.' + Format);
        if TempTex.BPP = 0 then
          raise EInvalidFormat.Create('Invalid Format');
        TexFormat := GL_RGB;
        CompressedTexFormat := GL_COMPRESSED_RGB;
        if TempTex.BPP = 32 then
          begin
          TexFormat := GL_RGBA;
          CompressedTexFormat := GL_COMPRESSED_RGBA;
          end;
        fTexture.CreateNew(Temptex.Width, Temptex.Height, CompressedTexFormat);
        fTexture.setClamp(GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
        gluBuild2DMipmaps(GL_TEXTURE_2D, TempTex.BPP div 8, Temptex.Width, Temptex.Height, TexFormat, GL_UNSIGNED_BYTE, @TempTex.Data[0]);
        fTexture.SetFilter(GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR_MIPMAP_LINEAR);
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
        Materials[i].TexID := StrToIntWD(GetAttribute('texture'), 0);
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
              Materials[i].AutoplantProperties.Factor := StrToFloatWD(GetAttribute('count'), 1);
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



procedure TTerrain.FillWithWater(X, Y, H: Single);
var
  a: Array of Array[0..1] of Single;
  i: integer;
  procedure Add(X, Y: Single);
  begin
    if (X >= 0) and (X < SizeX / 5) and (Y >= 0) and (Y < SizeY / 5) then
      if Round(10 * WaterMap[X, Y]) <> Round(10 * H) then
        begin
        SetLength(a, Length(a) + 1);
        a[high(a), 0] := X;
        a[high(a), 1] := Y;
        WaterMap[X, Y] := Round(10 * H) / 10;
        end;
  end;
begin
  RemoveWater(X, Y, false);
  BeginUpdate;
  setLength(a, 1);
  a[0, 0] := X;
  a[0, 1] := Y;
  i := 0;
  while i <= high(a) do
    begin
    WaterMap[a[i, 0], a[i, 1]] := Round(10 * H) / 10;
    if Round(10 * HeightMap[a[i, 0], a[i, 1]]) < Round(10 * H) then
      begin
      Add(a[i, 0] - 0.2, a[i, 1] - 0.2);
      Add(a[i, 0] - 0.2, a[i, 1]      );
      Add(a[i, 0] - 0.2, a[i, 1] + 0.2);
      Add(a[i, 0]      , a[i, 1] + 0.2);
      Add(a[i, 0] + 0.2, a[i, 1] + 0.2);
      Add(a[i, 0] + 0.2, a[i, 1]      );
      Add(a[i, 0] + 0.2, a[i, 1] - 0.2);
      Add(a[i, 0]      , a[i, 1] - 0.2);
      end;
    inc(i);
    end;
  EndUpdate;
end;

procedure TTerrain.RemoveWater(X, Y: Single; Notify: Boolean = true);
var
  a: Array of Array[0..1] of Single;
  i: integer;
  H: Single;
  procedure Add(X, Y: Single);
  begin
    if (X >= 0) and (X < SizeX / 5) and (Y >= 0) and (Y < SizeY / 5) then
      if Round(10 * WaterMap[X, Y]) = Round(10 * H) then
        begin
        SetLength(a, Length(a) + 1);
        a[high(a), 0] := X;
        a[high(a), 1] := Y;
        WaterMap[X, Y] := 0;
        end;
  end;
begin
  H := WaterMap[X, Y];
  if H = 0 then
    exit;
  if Notify then
    BeginUpdate;
  setLength(a, 1);
  a[0, 0] := X;
  a[0, 1] := Y;
  i := 0;
  while i <= high(a) do
    begin
    WaterMap[a[i, 0], a[i, 1]] := 0;
    Add(a[i, 0] - 0.2, a[i, 1] - 0.2);
    Add(a[i, 0] - 0.2, a[i, 1]      );
    Add(a[i, 0] - 0.2, a[i, 1] + 0.2);
    Add(a[i, 0]      , a[i, 1] + 0.2);
    Add(a[i, 0] + 0.2, a[i, 1] + 0.2);
    Add(a[i, 0] + 0.2, a[i, 1]      );
    Add(a[i, 0] + 0.2, a[i, 1] - 0.2);
    Add(a[i, 0]      , a[i, 1] - 0.2);
    inc(i);
    end;
  if Notify then
    EndUpdate;
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
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  fMap[fX, fY].Height := Round(256 * Height);
  SetLength(fCoordsToUpdate, 2 + length(fCoordsToUpdate));
  fCoordsToUpdate[high(fCoordsToUpdate) - 1] := Round(5 * X);
  fCoordsToUpdate[high(fCoordsToUpdate) - 0] := Round(5 * Y);
  fWaterOnly := false;
end;

function TTerrain.GetWaterAtPosition(X, Y: Single): Single;
var
  fX, fY: Word;
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  Result := fMap[fX, fY].Water / 256;
end;

procedure TTerrain.SetWaterAtPosition(X, Y, Height: Single);
var
  fX, fY: Word;
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  fMap[fX, fY].Water := Round(256 * Height);
  SetLength(fCoordsToUpdate, 2 + length(fCoordsToUpdate));
  fCoordsToUpdate[high(fCoordsToUpdate) - 1] := Round(5 * X);
  fCoordsToUpdate[high(fCoordsToUpdate) - 0] := Round(5 * Y);
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
  fData: Array of Integer;
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  fMap[fX, fY].Texture := Tex;
  SetLength(fData, 3);
  fData[0] := 1;
  fData[1] := Round(5 * X);
  fData[2] := Round(5 * Y);
  EventManager.CallEvent('TTerrain.ChangedTexmap', @fData[0], nil);
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
  fMarkMap.Resize(X, Y);
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
  ChangeCollection('terrain/defaultcollection.ocf');
  Resize(2048, 2048);
{  Resize(2048, 2048);
  fMap[0, 0].Height := 20000;
  fMap[SizeX - 1, 0].Height := 20000;
  fMap[0, SizeY - 1].Height := 20000;
  fMap[SizeX - 1, SizeY - 1].Height := 20000;
  Subdivide(0, 0, SizeX, SizeY);
  MakeMountain(512, 512, 384, 38000 / 256);
  MakeMountain(512, 512, 128, 30000 / 256);
  FillWithWater(0 / 5, 0 / 5, 28000 / 256);
  FillWithWater(512 / 5, 512 / 5, 32000 / 256);
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
        fMap[i, j].Texture := 5;
      if fMap[i, j].Height < fMap[i, j].Water then
        fMap[i, j].Texture := 3;
      end;}
  EventManager.CallEvent('TTerrain.ChangedAll', nil, nil);
end;

procedure TTerrain.ChangeCollection(S: String);
begin
  if fCollection <> nil then
    fCollection.Free;
  fCollection := TTerrainCollection.Create(S);
  EventManager.CallEvent('TTerrain.ChangedCollection', nil, nil);
end;

procedure TTerrain.BeginUpdate;
begin
  SetLength(fCoordsToUpdate, 1);
  fWaterOnly := true;
end;

procedure TTerrain.EndUpdate;
begin
  fCoordsToUpdate[0] := (Length(fCoordsToUpdate) - 1) div 2;
  if fWaterOnly then
    EventManager.CallEvent('TTerrain.ChangedWater', @fCoordsToUpdate[0], nil)
  else
    EventManager.CallEvent('TTerrain.Changed', @fCoordsToUpdate[0], nil);
end;

procedure TTerrain.CreateMarkMap;
  procedure Mark(X, Y: Single; F: Integer);
  var
    MM: Array[0..1, 0..1] of Single;
  begin
    MM[0, 0] := (1 - fPart(Y)) * (1 - fPart(X));
    MM[1, 0] := (1 - fPart(Y)) * (fPart(X));
    MM[0, 1] := (fPart(Y)) * (1 - fPart(X));
    MM[1, 1] := (fPart(Y)) * (fPart(X));

    fMarkMap.Value[Floor(X) + 0, Floor(Y) + 0] := Round(Mix(fMarkMap.Value[Floor(X) + 0, Floor(Y) + 0], F, MM[1, 1]));
    fMarkMap.Value[Floor(X) + 1, Floor(Y) + 0] := Round(Mix(fMarkMap.Value[Floor(X) + 1, Floor(Y) + 0], F, MM[0, 1]));
    fMarkMap.Value[Floor(X) + 0, Floor(Y) + 1] := Round(Mix(fMarkMap.Value[Floor(X) + 0, Floor(Y) + 1], F, MM[1, 0]));
    fMarkMap.Value[Floor(X) + 1, Floor(Y) + 1] := Round(Mix(fMarkMap.Value[Floor(X) + 1, Floor(Y) + 1], F, MM[0, 0]));
  end;

  procedure MakeLine(X, Y, A, B: Integer);
  var
    XPerStep, YPerStep: Single;
    Length, i: Integer;
  begin
    Length := Max(Abs(A - X), Abs(B - Y));
    XPerStep := (A - X) / Length;
    YPerStep := (B - Y) / Length;
    for i := 0 to Length do
      Mark(X + I * XPerStep, Y + I * YPerStep, 100);
  end;

  procedure CreatedField(OX, OY: Integer);
  var
    i, j: Integer;
    procedure FillField(X, Y: Integer);
    var
      a: TRow;
    begin
      a := TRow.Create;
      repeat
        fMarkMap.Value[X, Y] := 100;
        if (X > MinX) and (fMarkMap.Value[X - 1, Y] = 0) then
          begin
          A.Insert(A.Length, X);
          A.Insert(A.Length, Y);
          dec(X);
          end
        else if (X < MaxX) and (fMarkMap.Value[X + 1, Y] = 0) then
          begin
          A.Insert(A.Length, X);
          A.Insert(A.Length, Y);
          inc(X);
          end
        else if (Y > MinY) and (fMarkMap.Value[X, Y - 1] = 0) then
          begin
          A.Insert(A.Length, X);
          A.Insert(A.Length, Y);
          dec(Y);
          end
        else if (Y < MaxY) and (fMarkMap.Value[X, Y + 1] = 0) then
          begin
          A.Insert(A.Length, X);
          A.Insert(A.Length, Y);
          inc(Y);
          end
        else
          begin
          Y := A.Value[A.Length - 1];
          X := A.Value[A.Length - 2];
          A.Delete(A.Length - 1);
          A.Delete(A.Length - 1);
          end;
      until
        A.Length = 0;
      a.Free;
    end;
  begin
    MinX := Max(0, fMarks.GetCol(0).Min - 2);
    MinY := Max(0, fMarks.GetCol(1).Min - 2);
    MaxX := Min(SizeX - 1, fMarks.GetCol(0).Max + 2);
    MaxY := Min(SizeY - 1, fMarks.GetCol(1).Max + 2);
    if Marks.Height < 3 then
      exit;
    for i := MinX to MaxX do
      for j := MinY to MaxY do
        fMarkMap.Value[I, J] := 0;
    for i := 0 to Marks.Height - 2 do
      MakeLine(Marks.Value[0, i], Marks.Value[1, i], Marks.Value[0, i + 1], Marks.Value[1, i + 1]);
    MakeLine(Marks.Value[0, Marks.Height - 1], Marks.Value[1, Marks.Height - 1], Marks.Value[0, 0], Marks.Value[1, 0]);
    FillField(MinX, MinY);
    for i := MinX to MaxX do
      for j := MinY to MaxY do
        if fMarkMap.Value[I, J] <= 50 then
          if ((fMarkMap.Value[I + 1, J] > 50) and (fMarkMap.Value[I - 1, J] > 50)) or ((fMarkMap.Value[I, J + 1] > 50) and (fMarkMap.Value[I, J - 1] > 50)) then
            fMarkMap.Value[I, J] := 100;
    for i := MinX to MaxX do
      for j := MinY to MaxY do
        fMarkMap.Value[i, j] := 100 - fMarkMap.Value[i, j];
  end;
begin
  CreatedField(0, 0);
end;

procedure TTerrain.SetTo(Height: Single);
var
  i, j: Integer;
begin
  BeginUpdate;
  for i := MinX to MaxX do
    for j := MinY to MaxY do
      if fMarkMap.Value[I, J] > 0 then
        HeightMap[i / 5, j / 5] := Mix(HeightMap[i / 5, j / 5], Height, 0.01 * fMarkMap.Value[I, J]);
  EndUpdate;
end;

procedure TTerrain.SetToMin(Height: Single);
var
  i, j: Integer;
begin
  BeginUpdate;
  for i := MinX to MaxX do
    for j := MinY to MaxY do
      if fMarkMap.Value[I, J] > 0 then
        HeightMap[i / 5, j / 5] := Mix(HeightMap[i / 5, j / 5], Max(HeightMap[i / 5, j / 5], Height), 0.01 * fMarkMap.Value[I, J]);
  EndUpdate;
end;

procedure TTerrain.SetToMax(Height: Single);
var
  i, j: Integer;
begin
  BeginUpdate;
  for i := MinX to MaxX do
    for j := MinY to MaxY do
      if fMarkMap.Value[I, J] > 0 then
        HeightMap[i / 5, j / 5] := Mix(HeightMap[i / 5, j / 5], Min(HeightMap[i / 5, j / 5], Height), 0.01 * fMarkMap.Value[I, J]);
  EndUpdate;
end;

procedure TTerrain.RaiseTo(Height: Single = -1);
var
  M: Integer;
  i, j: Integer;
begin
  BeginUpdate;
  M := CreateRaiseLowerMap;
  for i := MinX to MaxX do
    for j := MinY to MaxY do
      if (fMarkMap.Value[I, J] > 0) and (HeightMap[i / 5, j / 5] < Height) then
        HeightMap[i / 5, j / 5] := Mix(HeightMap[i / 5, j / 5], Height, fMarkMap.Value[I, J] / M);
  Smooth;
  Smooth;
  Smooth;
  EndUpdate;
end;

procedure TTerrain.LowerTo(Height: Single = -1);
var
  M: Integer;
  i, j: Integer;
begin
  BeginUpdate;
  M := CreateRaiseLowerMap;
  for i := MinX to MaxX do
    for j := MinY to MaxY do
      if (fMarkMap.Value[I, J] > 0) and (HeightMap[i / 5, j / 5] > Height) then
        HeightMap[i / 5, j / 5] := Mix(HeightMap[i / 5, j / 5], Height, fMarkMap.Value[I, J] / M);
  Smooth;
  Smooth;
  Smooth;
  EndUpdate;
end;

procedure TTerrain.Smooth;
var
  i, j: Integer;
begin
  for i := MinX + 1 to MaxX - 1 do
    for j := MinY + 1 to MaxY - 1 do
      if (fMarkMap.Value[I, J] > 0) then
        fMap[i, j].Height := Round(0.3 * fMap[i + 0, j + 0].Height
                           + 0.125 * fMap[i + 1, j + 0].Height
                           + 0.125 * fMap[i + 0, j + 1].Height
                           + 0.125 * fMap[i - 1, j + 0].Height
                           + 0.125 * fMap[i + 0, j - 1].Height
                           + 0.050 * fMap[i + 1, j + 1].Height
                           + 0.050 * fMap[i - 1, j + 1].Height
                           + 0.050 * fMap[i - 1, j - 1].Height
                           + 0.050 * fMap[i + 1, j - 1].Height);
end;

function TTerrain.CreateRaiseLowerMap: Integer;
var
  i, j, k, l, Length: Integer;
begin
  Result := 0;
  for i := MinX to MaxX do
    begin
    Length := 0;
    for j := MinY to MaxY do
      if fMarkMap.Value[I, J] > 0 then
        begin
        if Length = 0 then
          k := j;
        inc(Length);
        end
      else
        begin
        if Length > 0 then
          for l := k to k + Length - 1 do
            fMarkMap.Value[i, L] := Round(1000 * 10 * Length * (0.5 - 0.5 * Cos(2 * PI * (L - K) / Length)));
        Length := 0;
        end;
    end;
  for j := MinY to MaxY do
    begin
    Length := 0;
    for i := MinX to MaxX do
      if fMarkMap.Value[I, J] > 0 then
        begin
        if Length = 0 then
          k := i;
        inc(Length);
        end
      else
        begin
        if Length > 0 then
          for l := k to k + Length - 1 do
            begin
            fMarkMap.Value[L, j] := Round(0.001 * fMarkMap.Value[L, j] * 10 * Length * (0.5 - 0.5 * Cos(2 * PI * (L - K) / Length)));
            Result := Max(Result, fMarkMap.Value[L, j]);
            end;
        Length := 0;
        end;
    end;
end;

constructor TTerrain.Create;
begin
  try
    fCanAdvance := false;
    fAdvancing := false;
    fCollection := nil;
    fMarks := TTable.Create;
    fMarkMap := TTable.Create;
    CurrMark := Vector(-1, -1);
    MarkMode := 0;
  except
    ModuleManager.ModLog.AddError('Could not create terrain: Internal error');
  end;
end;

destructor TTerrain.Free;
begin
  if fCollection <> nil then
    fCollection.Free;
  fMarkMap.Free;
  fMarks.Free;
end;

end.
