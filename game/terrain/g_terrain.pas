unit g_terrain;

interface

uses
  SysUtils, Classes, u_vectors, m_texmng_class, dglOpenGL;

type
  TTerrainMapPoint = record
    Height, Water, MinWater, MaxWater, WaterSpeed: Word;
    Texture: Byte;
    end;

  TTerrain = class(TThread)
    protected
      fSizeX, fSizeY: Word;
      fMap: Array of Array of TTerrainMapPoint;
      fTmpMap: Array of Array of Word;
      fCanAdvance, fAdvancing: Boolean;
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
      procedure Resize(X, Y: Integer);
      procedure AdvanceAutomaticWater;
      procedure LoadDefaults;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_math, m_varlist, u_events, math;

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
begin
  fX := Round(Clamp(5 * X, 0, fSizeX - 1));
  fY := Round(Clamp(5 * Y, 0, fSizeY - 1));
  fMap[fX, fY].Texture := Tex;
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
var
  i, j, k, l: Integer;
  diffMap: Array[-1..1, -1..1] of Word;
  fFieldsWantingWater, fWantedWater: Integer;
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
  Resize(1024, 1024);
  fMap[0, 0].Height := 5100;
  fMap[SizeX - 1, 0].Height := 5100;
  fMap[0, SizeY - 1].Height := 5100;
  fMap[SizeX - 1, SizeY - 1].Height := 5100;
  Subdivide(0, 0, SizeX, SizeY);
  for i := 1 to SizeX - 1 do
    for j := 1 to SizeY - 1 do
      begin
      if (abs((fMap[i, j].Height - fMap[i - 1, j].Height) / 0.2) > 160)
      or (abs((fMap[i, j].Height - fMap[i - 1, j - 1].Height) / 0.282) > 160)
      or (abs((fMap[i, j].Height - fMap[i, j - 1].Height) / 0.2) > 160) then
        begin
        fMap[i, j].Texture := 6;
        end;
      if (abs((fMap[i, j].Height - fMap[i - 1, j].Height) / 0.2) > 200)
      or (abs((fMap[i, j].Height - fMap[i - 1, j - 1].Height) / 0.282) > 200)
      or (abs((fMap[i, j].Height - fMap[i, j - 1].Height) / 0.2) > 200) then
        begin
        fMap[i, j].Texture := 5;
        end;
      end;
  EventManager.CallEvent('TTerrain.ChangedAll', nil, nil);
end;

constructor TTerrain.Create;
begin
  inherited Create(true);
  fCanAdvance := false;
  fAdvancing := false;
  Resume;
end;

destructor TTerrain.Free;
begin
  Terminate;
  sleep(100);
end;

end.