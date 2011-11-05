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
  D, OD: TPathPointData;
  FaceCount: Integer;
  OldBinormal, Binormal: TVector3D;
  M, N: TMatrix3D;
  procedure NextPathPoint(Distance: Single);
  var
    I: Integer;
    F: PFace;
    V, V1: PVertex;
  begin
    D := P.DataAtDistance(Distance);
    Binormal := Normalize(CrossProduct(D.Normal, D.Tangent));
    M := Transpose(Matrix(Binormal, D.Normal, Vector(0, 0, 0)));

    V1 := @fBaseMesh.Vertices[I];
    
    for I := 0 to high(fBaseMesh.Vertices) do
      begin
      V := fMesh.AddVertex;
      V^.Position := Mix(V1^.Position * N + OD.Position, V1^.Position * M + D.Position, V1^.Position.Z);
      inc(V1);
      end;

    OldBinormal := Binormal;
    D := OD;
    N := M;
  end;
begin
  SetLength(fMesh.Vertices, 0);
  SetLength(fMesh.Faces, 0);

  PrevS := 0;
  S := 1;
  OD := P.DataAtDistance(0);
  OldBinormal := Normalize(CrossProduct(OD.Normal, OD.Tangent));
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