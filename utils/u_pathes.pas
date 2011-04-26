unit u_pathes;

interface

uses
  SysUtils, Classes, u_vectors, u_math, math, u_linkedlists;

type
  TBezierPoint = class;

  TPathPointData = record
    Position: TVector3D;
    Tangent: TVector3D;
    Banking, T: Single;
    Point: TBezierPoint;
    end;

  TBezierCurveLookupPoint = record
    Distance, T: Single;
    end;

  TBezierPoint = class(TLinkedListItem)
    protected
      fLookupTable: Array of TBezierCurveLookupPoint;
      fParameters: Array[0..3] of TVector3D;
      fC1, fC2, fP: TVector3D;
      fLength: Single;
      fChanged: Boolean;
      fForcedNext: TBezierPoint;
      procedure ChangeC1(P: TVector3D);
      procedure ChangeC2(P: TVector3D);
      procedure ChangeP(P: TVector3D);
    public
      Banking: Single;
      Distance: Single;
      property Position: TVector3D read fP write ChangeP;
      property CP1: TVector3D read fC1 write ChangeC1;
      property CP2: TVector3D read fC2 write ChangeC2;
      property Length: Single read fLength;
      function TAtDistance(D: Single): Single;
      function PositionAtT(T: Single): TVector3D;
      function BankingAtT(T: Single): Single;
      function TangentAtT(T: Single): TVector3D;
      function DataAtT(T: Single): TPathPointData;
      procedure BuildLookupTable;
      constructor Create;
    end;

  TPath = class(TLinkedList)
    protected
      fLength: Single;
      fLookupTable: Array of TBezierPoint;
    public
      Closed: Boolean;
      property Length: Single read fLength;
      function PointAtDistance(D: Single): TBezierPoint;
      function DataAtDistance(D: Single): TPathPointData;
      procedure BuildLookupTable;
      constructor Create;
      procedure Free;
    end;

implementation

procedure TBezierPoint.ChangeC1(P: TVector3D);
begin
  fC1 := P;
  fChanged := True;
  TPath(List).Changed := True;
end;

procedure TBezierPoint.ChangeC2(P: TVector3D);
begin
  fC2 := P;
  fChanged := True;
  TPath(List).Changed := True;
end;

procedure TBezierPoint.ChangeP(P: TVector3D);
begin
  fP := P;
  fChanged := True;
  TPath(List).Changed := True;
end;

function TBezierPoint.TAtDistance(D: Single): Single;
var
  ID: Integer;
  iMax, iMin: Integer;
begin
  if D >= fLookupTable[high(fLookupTable)].Distance then
    Result := 1;

  ID := Trunc((high(fLookupTable) - 1) * D);

  iMin := 0;
  iMax := high(fLookupTable) - 1;

  while iMin <> iMax do
    begin

    while fLookupTable[ID + 1].Distance <= D do
      begin
      ID := Round((ID + iMax) / 2);

      if fLookupTable[ID].Distance <= D then
        iMin := ID;
      end;

    iMax := ID;

    while fLookupTable[ID].Distance > D do
      begin
      ID := (ID + iMin) div 2;

      if fLookupTable[ID].Distance >= D then
        iMax := ID;
      end;

    iMin := ID;

    ID := (iMin + iMax) div 2;
    end;

  Result := Mix(fLookupTable[iMin].T, fLookupTable[iMin + 1].T, (D - fLookupTable[iMin].Distance) / (fLookupTable[iMin + 1].Distance - fLookupTable[iMin].Distance));
end;

function TBezierPoint.PositionAtT(T: Single): TVector3D;
begin
  Result := fParameters[3] * t * t * t
          + fParameters[2] * t * t
          + fParameters[1] * t
          + fParameters[0];
end;

function TBezierPoint.BankingAtT(T: Single): Single;
begin
  Result := Mix(Banking, fForcedNext.Banking, T);
end;

function TBezierPoint.TangentAtT(T: Single): TVector3D;
begin
  Result := Normalize(fParameters[3] * t * t * 3.0
                    + fParameters[2] * t * 2.0
                    + fParameters[1]);
end;

function TBezierPoint.DataAtT(T: Single): TPathPointData;
begin
  Result.Position := PositionAtT(T);
  Result.Tangent := TangentAtT(T);
  Result.Banking := BankingAtT(T);
  Result.Point := Self;
  Result.T := T;
end;

procedure TBezierPoint.BuildLookupTable;
var
  i: Integer;
  fPos: TVector3D;
const
  COUNT = 1000;
begin
  if fChanged then
    begin
    fForcedNext := TBezierPoint(Next);
    if fForcedNext = nil then
      fForcedNext := TBezierPoint(TPath(List).First);

    fParameters[3] := Position             * -1
                    + CP2                  *  3
                    + fForcedNext.CP1      * -3
                    + fForcedNext.Position *  1;
    fParameters[2] := Position             *  3
                    + CP2                  * -6
                    + fForcedNext.CP1      *  3;
    fParameters[1] := Position             * -3
                    + CP2                  *  3;
    fParameters[0] := Position             *  1;

    setLength(fLookupTable, COUNT + 1);
    fLength := 0;

    fLookupTable[0].T := 0;
    fLookupTable[0].Distance := 0;

    fPos := PositionAtT(0);
    for i := 1 to COUNT do
      begin
      fLength := fLength + VecLength(fPos - PositionAtT(i / COUNT));
      fPos := PositionAtT(i / COUNT);
      fLookupTable[i].T := i / COUNT;
      fLookupTable[i].Distance := fLength;
      end;
    fChanged := False;
    end;
end;

constructor TBezierPoint.Create;
begin
  inherited Create;
  Distance := 0;
  fChanged := True;
  fLength := 0;
  fParameters[0] := Vector(0, 0, 0);
  fParameters[1] := Vector(0, 0, 0);
  fParameters[2] := Vector(0, 0, 0);
  fParameters[3] := Vector(0, 0, 0);
  fC1 := Vector(0, 0, 0);
  fC2 := Vector(0, 0, 0);
  fP := Vector(0, 0, 0);
end;



function TPath.PointAtDistance(D: Single): TBezierPoint;
var
  ID: Integer;
  iMax, iMin: Integer;
begin
  D := Length * fPart(D / Length);

  if D >= fLookupTable[high(fLookupTable)].Distance then
    Result := fLookupTable[high(fLookupTable)];

  ID := Trunc(Clamp(high(fLookupTable) * D / Length, 0, high(fLookupTable) - 1));

  iMin := 0;
  iMax := high(fLookupTable) - 1;

  while iMin <> iMax do
    begin

    while fLookupTable[ID + 1].Distance <= D do
      begin
      ID := Round((ID + iMax) / 2);

      if fLookupTable[ID].Distance <= D then
        iMin := ID;
      end;

    iMax := ID;

    while fLookupTable[ID].Distance > D do
      begin
      ID := (ID + iMin) div 2;

      if fLookupTable[ID].Distance >= D then
        iMax := ID;
      end;

    iMin := ID;

    ID := (iMin + iMax) div 2;
    end;

  Result := fLookupTable[iMin];
end;

function TPath.DataAtDistance(D: Single): TPathPointData;
var
  Point: TBezierPoint;
begin
  D := Length * fPart(D / Length);

  Point := PointAtDistance(D);

  Result := Point.DataAtT(Point.TAtDistance(D - Point.Distance));
end;

procedure TPath.BuildLookupTable;
var
  I: Integer;
  CurrItem: TBezierPoint;
begin
  if Changed then
    begin
    fLength := 0;

    if Closed then
      SetLength(fLookupTable, Count)
    else
      begin
      SetLength(fLookupTable, Count - 1);
      TBezierPoint(Last).BuildLookupTable;
      end;

    CurrItem := TBezierPoint(First);

    for i := 0 to high(fLookupTable) do
      begin
      CurrItem.BuildLookupTable;
      CurrItem.Distance := fLength;

      fLookupTable[i] := CurrItem;
      fLength := fLength + CurrItem.Length;

      CurrItem := TBezierPoint(CurrItem.Next);
      end;
    end;
end;

function TPath.AddPoint: TBezierPoint;
begin
  Result := TBezierPoint.Create;
  Append(Result);
end;

constructor TPath.Create;
begin
  inherited Create;
  Changed := True;
  Closed := False;
  fLength := 0;
end;

procedure TPath.Free;
begin
  while Last <> nil do
    Last.Free;
  inherited Free;
end;


end.