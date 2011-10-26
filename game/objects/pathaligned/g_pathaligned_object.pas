unit g_pathalighned_object;

interface

uses
  SysUtils, Classes, u_scene, u_pathes, u_math, u_vectors, math;

type
  TPathAlignedMeshRepeatMode  = (mrmContinous, mrmContinousNoIntersection, mrmRepeatFull, mrmRepeatNoIntersection, mrmScatter);
  TPathAlignedMeshTexCoordMode = (tcmWorldCoord, tcmUnchangedUV, tcmTiledUV);

  TPathAlignedMesh = class
    protected
      fMesh, fBaseMesh: TGeoMesh;
      fPath: TPath;
      fRepeatMode: TPathAlignedMeshRepeatMode;
      fTexCoordMode: TPathAlignedMeshTexCoordMode;
    public
      property Mesh: TGeoMesh read fMesh;
      property Path: TPath read fPath;
      procedure AdjustToPath(P: TPath);
      constructor Create(M: TGeoMesh);
      destructor Destroy; override;
    end;

  TPathAlignedObject = class(TRealObject)
    
    end;

implementation

procedure TPathAlignedMesh.AdjustToPath(P: TPath);
var
  PrevS, S: Integer;
  OD: TPathPointData;
  FaceCount: Integer;
  procedure NextPathPoint(Distance: Single);
  var
    D: TPathPointData;
    
  begin
    OD := D;
    D := P.DataAtDistance(Distance);
  end;
begin
  PrevS := 0;
  S := 1;
  OD := P.DataAtDistance(0);
  repeat
    NextPathPoint(Min(S + 1, P.Length));
    inc(S);
    inc(PrevS);
  until
    S >= P.Length;
end;

constructor TPathAlignedMesh.Create(M: TGeoMesh);
begin
  fBaseMesh := M;
  fPath := nil;
  fMesh := nil;
end;

destructor TPathAlignedMesh.Destroy;
begin
  if fMesh <> nil then
    fMesh.Free;
end;

end.