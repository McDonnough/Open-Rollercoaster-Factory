unit g_terrain;

interface

uses
  SysUtils, Classes, u_vectors, m_texmng_class, dglOpenGL;

type
  TTerrainMapPoint = record
    Height, Water, MinWater, MaxWater, WaterSpeed: Word;
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
    public
      property SizeX: Word read fSizeX;
      property SizeY: Word read fSizeY;
      property HeightMap[X: Single; Y: Single]: Single read GetHeightAtPosition write SetHeightAtPosition;
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
begin
  fSizeX := 0;
  fSizeY := 0;
  Resize(2048, 2048);
  for i := 0 to 2047 do
    begin
    for j := 0 to 2047 do
      fMap[i, j].Height := Round(256 * (7 + sin(degToRad(i * 4)) * sin(degToRad(j * 4)) + 4 * sin(degToRad(i)) * sin(degToRad(j))+ sin(degToRad(4 * i)) * sin(degToRad(4 * j)) + 0.25 * sin(degToRad(16 * i)) * sin(degToRad(16 * j))));
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