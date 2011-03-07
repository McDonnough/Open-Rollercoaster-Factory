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
      constructor Create(fOCF: TOCFFile);
      destructor Free;
    end;

  TTerrain = class
    protected
      fSizeX, fSizeY: Word;
      fWaterOnly: Boolean;
      fMap: Array of Array of TTerrainMapPoint;
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
      function GetExactHeightAtPosition(X, Y: Integer): Word;
      procedure SetExactHeightAtPosition(X, Y: Integer; Height: Word);
      function GetExactWaterAtPosition(X, Y: Integer): Word;
      procedure SetExactWaterAtPosition(X, Y: Integer; Height: Word);
      function GetExactTextureAtPosition(X, Y: Integer): Byte;
      procedure SetExactTextureAtPosition(X, Y: Integer; Tex: Byte);
      function CreateRaiseLowerMap: Integer;
      procedure InternalSmooth;
    public
      CurrMark: TVector2D;
      MarkMode: Integer;
      property SizeX: Word read fSizeX;
      property SizeY: Word read fSizeY;
      property ExactHeightMap[X, Y: Integer]: Word read GetExactHeightAtPosition write SetExactHeightAtPosition;
      property ExactTexMap[X, Y: Integer]: Byte read GetExactTextureAtPosition write SetExactTextureAtPosition;
      property ExactWaterMap[X, Y: Integer]: Word read GetExactWaterAtPosition write SetExactWaterAtPosition;
      property HeightMap[X: Single; Y: Single]: Single read GetHeightAtPosition write SetHeightAtPosition;
      property WaterMap[X: Single; Y: Single]: Single read GetWaterAtPosition write SetWaterAtPosition;
      property TexMap[X: Single; Y: Single]: Byte read GetTextureAtPosition write SetTextureAtPosition;
      property Collection: TTerrainCollection read fCollection;
      property Marks: TTable read fMarks;
      function CreateOCFSection: TOCFBinarySection;
      procedure ReadFromOCFSection(A: TOCFBinarySection);
      procedure LoadedCollection(Event: String; Data, Result: Pointer);
      procedure AutoTexture(Tex, Mode: Integer; V: Single);
      procedure FillWithWater(X, Y, H: Single; Notify: Boolean = true);
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
      procedure SetTexture(T: Integer);
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

constructor TTerrainCollection.Create(fOCF: TOCFFile);
var
  i: Integer;
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
  writeln('Hint: Creating TerrainCollection object');
  fName := fOCF.FileName;
  try
    fTexture := TTexture.Create;
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
        fTexture.SetFilter(GL_NEAREST_MIPMAP_LINEAR, GL_NEAREST_MIPMAP_LINEAR);
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
  writeln('Hint: Deleting TerrainCollection object');
  for i := 0 to high(fAutoplantTextures) do
    fAutoplantTextures[i].Free;
  fTexture.Free;
end;


function TTerrain.CreateOCFSection: TOCFBinarySection;
var
  i, j: Integer;
  P: Pointer;
  fTerrainData: Array of Byte;
begin
  SetLength(fTerrainData, 4 { SizeX, SizeY } + SizeX * SizeY * (2 { Vertex } + 2 { Water }  + 1 { Material & Flags }));
  P := @fTerrainData[0];
  Word(P^) := SizeX;
  inc(p, 2);
  Word(P^) := SizeY;
  inc(p, 2);
  for i := 0 to SizeX - 1 do
    for j := 0 to SizeY - 1 do
      begin
      Word(P^) := fMap[i, j].Height;
      inc(P, 2);
      Word(P^) := fMap[i, j].Water;
      inc(P, 2);
      Byte(P^) := fMap[i, j].Texture;
      inc(P);
      end;
  Result := TOCFBinarySection.Create;
  Result.Append(@fTerrainData[0], length(fTerrainData));
end;

procedure TTerrain.ReadFromOCFSection(A: TOCFBinarySection);
var
  P: Pointer;
  i, j: Integer;
begin
  fSizeX := 0;
  fSizeY := 0;
  P := @A.Stream.Data[0];
  Resize(Word(P^), Word((P + 2)^));
  inc(p, 4);
  BeginUpdate;
  for i := 0 to SizeX - 1 do
    for j := 0 to SizeY - 1 do
      begin
      fMap[i, j].Height := Word(P^); inc(P, 2);
      fMap[i, j].Water := Word(P^); inc(P, 2);
      fMap[i, j].Texture := Byte(P^); inc(P);
      SetLength(fCoordsToUpdate, 2 + length(fCoordsToUpdate));
      fCoordsToUpdate[high(fCoordsToUpdate) - 1] := i;
      fCoordsToUpdate[high(fCoordsToUpdate) - 0] := j;
      end;
  EndUpdate;
end;

procedure TTerrain.LoadedCollection(Event: String; Data, Result: Pointer);
begin
  if fCollection <> nil then
    fCollection.Free;
  fCollection := TTerrainCollection.Create(TOCFFile(Data));
  EventManager.CallEvent('TTerrain.ChangedCollection', nil, nil);
end;


procedure TTerrain.AutoTexture(Tex, Mode: Integer; V: Single);
var
  i, j: Integer;
begin
  for i := MinX to MaxX do
    for j := MinY to MaxY do
      if (fMarkMap.Value[I, J] > 0) then
        case Mode of
          0: if HeightMap[I / 5, J / 5] <= V then TexMap[I / 5, J / 5] := Tex;
          1: if HeightMap[I / 5, J / 5] >= V then TexMap[I / 5, J / 5] := Tex;
          2: if (abs((HeightMap[i / 5, j / 5] - HeightMap[(i - 1) / 5, (j) / 5]) / 0.2) > V)
             or (abs((HeightMap[i / 5, j / 5] - HeightMap[(i - 1) / 5, (j - 1) / 5]) / 0.282) > V)
             or (abs((HeightMap[i / 5, j / 5] - HeightMap[(i) / 5, (j - 1) / 5]) / 0.2) > V) then
               TexMap[I / 5, J / 5] := Tex;
          end;

end;

procedure TTerrain.FillWithWater(X, Y, H: Single; Notify: Boolean = true);
var
  a: Array of Array[0..1] of Integer;
  i: integer;
  procedure Add(X, Y: Integer);
  begin
    if (X >= 0) and (X < SizeX) and (Y >= 0) and (Y < SizeY) then
      if Round(10 * WaterMap[X / 5, Y / 5]) <> Round(10 * H) then
        begin
        SetLength(a, Length(a) + 1);
        a[high(a), 0] := X;
        a[high(a), 1] := Y;
        WaterMap[X / 5, Y / 5] := Round(10 * H) / 10;
        end;
  end;
begin
  RemoveWater(X, Y, false);
  BeginUpdate;
  setLength(a, 1);
  a[0, 0] := Round(5 * X);
  a[0, 1] := Round(5 * Y);
  i := 0;
  while i <= high(a) do
    begin
    WaterMap[a[i, 0] / 5, a[i, 1] / 5] := Round(10 * H) / 10;
    if Round(10 * HeightMap[a[i, 0] / 5, a[i, 1] / 5]) < Round(10 * H) then
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
  EndUpdate;
end;

procedure TTerrain.RemoveWater(X, Y: Single; Notify: Boolean = true);
var
  a: Array of Array[0..1] of Integer;
  i: integer;
  H: Single;
  procedure Add(X, Y: Integer);
  begin
    if (X >= 0) and (X < SizeX) and (Y >= 0) and (Y < SizeY) then
      if Round(10 * WaterMap[X / 5, Y / 5]) = Round(10 * H) then
        begin
        SetLength(a, Length(a) + 1);
        a[high(a), 0] := X;
        a[high(a), 1] := Y;
        WaterMap[X / 5, Y / 5] := 0;
        end;
  end;
begin
  H := WaterMap[X, Y];
  if H = 0 then
    exit;
  if Notify then
    BeginUpdate;
  setLength(a, 1);
  a[0, 0] := Round(5 * X);
  a[0, 1] := Round(5 * Y);
  i := 0;
  while i <= high(a) do
    begin
    WaterMap[a[i, 0] / 5, a[i, 1] / 5] := 0;
    Add(a[i, 0] - 1, a[i, 1] - 1);
    Add(a[i, 0] - 1, a[i, 1]    );
    Add(a[i, 0] - 1, a[i, 1] + 1);
    Add(a[i, 0]    , a[i, 1] + 1);
    Add(a[i, 0] + 1, a[i, 1] + 1);
    Add(a[i, 0] + 1, a[i, 1]    );
    Add(a[i, 0] + 1, a[i, 1] - 1);
    Add(a[i, 0]    , a[i, 1] - 1);
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

function TTerrain.GetExactHeightAtPosition(X, Y: Integer): Word;
begin
  try
    Result := fMap[X, Y].Height;
  except
    Result := 64 * 256;
  end;
end;

procedure TTerrain.SetExactHeightAtPosition(X, Y: Integer; Height: Word);
begin
  try
    fMap[X, Y].Height := Height;
  except
  end;
end;

function TTerrain.GetExactWaterAtPosition(X, Y: Integer): Word;
begin
  try
    Result := fMap[X, Y].Water;
  except
    Result := 0;
  end;
end;

procedure TTerrain.SetExactWaterAtPosition(X, Y: Integer; Height: Word);
begin
  try
    fMap[X, Y].Water := Height;
  except
  end;
end;

function TTerrain.GetExactTextureAtPosition(X, Y: Integer): Byte;
begin
  try
    Result := fMap[X, Y].Texture;
  except
    Result := 0;
  end;
end;

procedure TTerrain.SetExactTextureAtPosition(X, Y: Integer; Tex: Byte);
begin
  try
    fMap[X, Y].Texture := Tex;
  except
  end;
end;


procedure TTerrain.SetHeightAtPosition(X, Y, Height: Single);
var
  fX, fY: Word;
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  fMap[fX, fY].Height := Round(256 * Height);
  if fMap[fX, fY].Height >= fMap[fX, fY].Water then
    fMap[fX, fY].Water := 0;
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
  oSizeX, oSizeY: Integer;
begin
  fCanAdvance := false;
  while fAdvancing do
    sleep(1);
  SetLength(fMap, X);
  oSizeX := fSizeX;
  oSizeY := fSizeY;
  fSizeX := X;
  fSizeY := Y;
  for i := 0 to high(fMap) do
    SetLength(fMap[i], Y);
  for i := 0 to high(fMap) do
    for j := 0 to high(fMap[i]) do
      if (i >= oSizeX) or (j >= oSizeY) then
        with fMap[i, j] do
          begin
          Height := 16384;
          Water := 0;
          Texture := 0;
          end;
  fCanAdvance := true;
  fMarkMap.Resize(X, Y);
  EventManager.CallEvent('TTerrain.Resize', @X, nil);
end;

procedure TTerrain.LoadDefaults;
var
  i, j: Integer;
begin
  fSizeX := 0;
  fSizeY := 0;
  ChangeCollection('terrain/defaultcollection.ocf');
  Resize(1024, 1024);
end;

procedure TTerrain.ChangeCollection(S: String);
begin
  ModuleManager.ModOCFManager.RequestOCFFile(S, 'TTerrain.CollectionLoaded', nil);
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
  var
    RMaxX, RMaxY, RMinX, RMinY: Integer;
  begin
    RMinX := fMarks.GetCol(0).Min - 2;
    RMinY := fMarks.GetCol(1).Min - 2;
    RMaxX := fMarks.GetCol(0).Max + 2;
    RMaxY := fMarks.GetCol(1).Max + 2;
    MinX := Max(0, RMinX);
    MinY := Max(0, RMinY);
    MaxX := Min(SizeX - 1, RMaxX);
    MaxY := Min(SizeY - 1, RMaxY);
    if Marks.Height < 3 then
      exit;
    for i := MinX to MaxX do
      for j := MinY to MaxY do
        fMarkMap.Value[I, J] := 0;
    for i := 0 to Marks.Height - 2 do
      MakeLine(Marks.Value[0, i], Marks.Value[1, i], Marks.Value[0, i + 1], Marks.Value[1, i + 1]);
    MakeLine(Marks.Value[0, Marks.Height - 1], Marks.Value[1, Marks.Height - 1], Marks.Value[0, 0], Marks.Value[1, 0]);
    if (MinX = RMinX) and (MinY = RMinY) then
      FillField(MinX, MinY);
    if (MinX = RMinX) and (MaxY = RMaxY) then
      FillField(MinX, MaxY);
    if (MaxX = RMaxX) and (MinY = RMinY) then
      FillField(MaxX, MinY);
    if (MaxX = RMaxX) and (MaxY = RMaxY) then
      FillField(MaxX, MaxY);
    for i := MinX to MaxX do
      for j := MinY to MaxY do
        if fMarkMap.Value[I, J] <= 50 then
          if ((fMarkMap.Value[I + 1, J] > 50) and (fMarkMap.Value[I - 1, J] > 50)) or ((fMarkMap.Value[I, J + 1] > 50) and (fMarkMap.Value[I, J - 1] > 50)) then
            fMarkMap.Value[I, J] := 100;
    for i := MinX to MaxX do
      for j := MinY to MaxY do
        fMarkMap.Value[i, j] := 100 - fMarkMap.Value[i, j];
    for i := MinX to MaxX do
      begin
      if fMarkMap.Value[i, 2] > 0 then
        fMarkMap.Value[i, 1] := fMarkMap.Value[i, 2];
      if fMarkMap.Value[i, 1] > 0 then
        fMarkMap.Value[i, 0] := fMarkMap.Value[i, 1];
      if fMarkMap.Value[i, SizeY - 3] > 0 then
        fMarkMap.Value[i, SizeY - 2] := fMarkMap.Value[i, SizeY - 3];
      if fMarkMap.Value[i, SizeY - 2] > 0 then
        fMarkMap.Value[i, SizeY - 1] := fMarkMap.Value[i, SizeY - 2];
      end;
    for i := MinY to MaxY do
      begin
      if fMarkMap.Value[2, i] > 0 then
        fMarkMap.Value[1, i] := fMarkMap.Value[2, i];
      if fMarkMap.Value[1, i] > 0 then
        fMarkMap.Value[0, i] := fMarkMap.Value[1, i];
      if fMarkMap.Value[SizeX - 3, i] > 0 then
        fMarkMap.Value[SizeX - 2, i] := fMarkMap.Value[SizeX - 3, i];
      if fMarkMap.Value[SizeX - 2, i] > 0 then
        fMarkMap.Value[SizeX - 1, i] := fMarkMap.Value[SizeX - 2, i];
      end;
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

procedure TTerrain.SetTexture(T: Integer);
var
  i, j: Integer;
begin
  for i := MinX to MaxX do
    for j := MinY to MaxY do
      if fMarkMap.Value[I, J] > 0 then
        TexMap[i / 5, j / 5] := T;
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
  InternalSmooth;
  InternalSmooth;
  InternalSmooth;
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
  InternalSmooth;
  InternalSmooth;
  InternalSmooth;
  EndUpdate;
end;

procedure TTerrain.InternalSmooth;
var
  i, j: Integer;
begin
  for i := MinX + 1 to MaxX - 1 do
    for j := MinY + 1 to MaxY - 1 do
      if (fMarkMap.Value[I, J] > 0) then
        fMap[i, j].Height := Round((fMap[i + 0, j + 0].Height
                                  + fMap[i + 1, j + 0].Height
                                  + fMap[i + 0, j + 1].Height
                                  + fMap[i - 1, j + 0].Height
                                  + fMap[i + 0, j - 1].Height
                                  + fMap[i + 1, j + 1].Height
                                  + fMap[i - 1, j + 1].Height
                                  + fMap[i - 1, j - 1].Height
                                  + fMap[i + 1, j - 1].Height) / 9);
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

procedure TTerrain.Smooth;
var
  i, j: Integer;
begin
  BeginUpdate;
  for i := MinX to MaxX do
    for j := MinY to MaxY do
      if (fMarkMap.Value[I, J] > 0) then
        HeightMap[i / 5, j / 5] := (HeightMap[(i + 0) / 5, (j + 0) / 5]
                                  + HeightMap[(i + 1) / 5, (j + 0) / 5]
                                  + HeightMap[(i + 0) / 5, (j + 1) / 5]
                                  + HeightMap[(i - 1) / 5, (j + 0) / 5]
                                  + HeightMap[(i + 0) / 5, (j - 1) / 5]
                                  + HeightMap[(i + 1) / 5, (j + 1) / 5]
                                  + HeightMap[(i - 1) / 5, (j + 1) / 5]
                                  + HeightMap[(i - 1) / 5, (j - 1) / 5]
                                  + HeightMap[(i + 1) / 5, (j - 1) / 5]
                                  + HeightMap[(i + 2) / 5, (j - 2) / 5]
                                  + HeightMap[(i + 1) / 5, (j - 2) / 5]
                                  + HeightMap[(i + 0) / 5, (j - 2) / 5]
                                  + HeightMap[(i - 1) / 5, (j - 2) / 5]
                                  + HeightMap[(i - 2) / 5, (j - 2) / 5]
                                  + HeightMap[(i - 2) / 5, (j - 1) / 5]
                                  + HeightMap[(i - 2) / 5, (j + 0) / 5]
                                  + HeightMap[(i - 2) / 5, (j + 1) / 5]
                                  + HeightMap[(i - 2) / 5, (j + 2) / 5]
                                  + HeightMap[(i - 1) / 5, (j + 2) / 5]
                                  + HeightMap[(i + 0) / 5, (j + 2) / 5]
                                  + HeightMap[(i + 1) / 5, (j + 2) / 5]
                                  + HeightMap[(i + 2) / 5, (j + 2) / 5]
                                  + HeightMap[(i + 2) / 5, (j + 1) / 5]
                                  + HeightMap[(i + 2) / 5, (j + 0) / 5]
                                  + HeightMap[(i + 2) / 5, (j - 1) / 5]) / 25;
  EndUpdate;
end;

constructor TTerrain.Create;
begin
  writeln('Hint: Creating Terrain object');
  try
    fCanAdvance := false;
    fAdvancing := false;
    fCollection := nil;
    fMarks := TTable.Create;
    fMarkMap := TTable.Create;
    CurrMark := Vector(-1, -1);
    MarkMode := 0;
    EventManager.AddCallback('TTerrain.CollectionLoaded', @LoadedCollection);
  except
    ModuleManager.ModLog.AddError('Could not create terrain: Internal error');
  end;
end;

destructor TTerrain.Free;
begin
  writeln('Hint: Deleting Terrain object');
  EventManager.RemoveCallback(@LoadedCollection);
  if fCollection <> nil then
    fCollection.Free;
  fMarkMap.Free;
  fMarks.Free;
end;

end.
