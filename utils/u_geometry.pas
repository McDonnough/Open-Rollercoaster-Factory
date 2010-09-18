unit u_geometry;

interface

uses
  SysUtils, Classes, u_math, u_vectors, m_texmng_class;

type
  TTriangle = Array[0..2] of TVector3D;
  TRay = Array[0..1] of TVector3D;

  TMeshTriangleVertexArray = Array[0..2] of Integer;

  TMeshVertex = record
    Position, Normal, BumpTangent: TVector3D;
    TexCoord: TVector2D;
    BumpTexCoordFactor: Single;
    Fix: Boolean;
    end;

  PMeshVertex = ^TMeshVertex;

  TMesh = class
    protected
      fVertices: Array of TMeshVertex;
      fTriangles: Array of TMeshTriangleVertexArray;
      fTransformMatrix: TMatrix4D;
      fStaticOffset, fOffset: TVector3D;
      fStaticRotationMatrix, fRotationMatrix: TMatrix3D;
      procedure setVertex(I: Integer; V: TMeshVertex);
      procedure setTriangle(I: Integer; V: TMeshTriangleVertexArray);
      function getVertex(I: Integer): TMeshVertex;
      function getPVertex(I: Integer): PMeshVertex;
      function getTriangle(I: Integer): TMeshTriangleVertexArray;
      function getVCount: Integer;
      function getTCount: Integer;
      procedure SetStaticOffset(A: TVector3D);
      procedure SetOffset(A: TVector3D);
      procedure SetStaticRotationMatrix(A: TMatrix3D);
      procedure SetRotationMatrix(A: TMatrix3D);
      procedure UpdateMatrix;
    public
      Parent: Pointer;
      MaxDistance, MinDistance: Single;
      Color: TVector4D;
      Texture, BumpMap: TTexture;
      property TransformMatrix: TMatrix4D read fTransformMatrix;
      property StaticOffset: TVector3D read fStaticOffset write SetStaticOffset;
      property Offset: TVector3D read fOffset write SetOffset;
      property StaticRotationMatrix: TMatrix3D read fStaticRotationMatrix write SetStaticRotationMatrix;
      property RotationMatrix: TMatrix3D read fRotationMatrix write SetRotationMatrix;
      property Vertices[i: Integer]: TMeshVertex read getVertex write setVertex;
      property pVertices[i: Integer]: PMeshVertex read getPVertex;
      property Triangles[i: Integer]: TMeshTriangleVertexArray read getTriangle write setTriangle;
      property VertexCount: Integer read getVCount;
      property TriangleCount: Integer read getTCount;
      constructor Create;
    end;

function MakeRay(A, B: TVector3D): TRay;
function MakeTriangle(A, B, C: TVector3D): TTriangle;
function MakeTriangleFromMeshTriangleVertexArray(Mesh: TMesh; A: TMeshTriangleVertexArray): TTriangle;
function RayTriangleIntersection(Ray: TRay; Tri: TTriangle; var I: TVector3D): Boolean;
function MakeMeshVertex(P, N: TVector3D; T: TVector2D): TMeshVertex;
function MakeExtendedMeshVertex(P, N: TVector3D; T: TVector2D; BF: Single; B: TVector3D): TMeshVertex;
function MakeTriangleVertexArray(A, B, C: Integer): TMeshTriangleVertexArray;

implementation

uses
  u_selection, u_events;

procedure TMesh.UpdateMatrix;
begin
  fTransformMatrix := TranslateMatrix(StaticOffset) * Matrix4D(StaticRotationMatrix);
  fTransformMatrix := fTransformMatrix * TranslateMatrix(Offset) * Matrix4D(RotationMatrix);
end;

procedure TMesh.SetStaticOffset(A: TVector3D);
begin
  fStaticOffset := A;
  UpdateMatrix;
end;

procedure TMesh.SetOffset(A: TVector3D);
begin
  fOffset := A;
  UpdateMatrix;
end;

procedure TMesh.SetStaticRotationMatrix(A: TMatrix3D);
begin
  fStaticRotationMatrix := A;
  UpdateMatrix;
end;

procedure TMesh.SetRotationMatrix(A: TMatrix3D);
begin
  fRotationMatrix := A;
  UpdateMatrix;
end;

procedure TMesh.setVertex(I: Integer; V: TMeshVertex);
begin
  if I > VertexCount then I := VertexCount;
  if I = VertexCount then
    SetLength(fVertices, I + 1);
  fVertices[i] := V;
  EventManager.CallEvent('TMesh.ChangedVertex', Self, @I);
end;

procedure TMesh.setTriangle(I: Integer; V: TMeshTriangleVertexArray);
begin
  if I > TriangleCount then I := TriangleCount;
  if I = TriangleCount then
    SetLength(fTriangles, I + 1);
  fTriangles[i] := V;
  EventManager.CallEvent('TMesh.ChangedTriangle', Self, @I);
end;

function TMesh.getVertex(I: Integer): TMeshVertex;
begin
  if I < VertexCount then
    Exit(fVertices[i]);
  Result := MakeMeshVertex(Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0));
end;

function TMesh.getPVertex(I: Integer): PMeshVertex;
begin
  if I < VertexCount then
    Exit(@fVertices[i]);
  Result := nil;
end;

function TMesh.getTriangle(I: Integer): TMeshTriangleVertexArray;
begin
  Result[0] := 0;
  Result[1] := 0;
  Result[2] := 0;
  if I >= TriangleCount then
    exit;
  Result := fTriangles[i];
end;

function TMesh.getVCount: Integer;
begin
  Result := Length(fVertices);
end;

function TMesh.getTCount: Integer;
begin
  Result := Length(fTriangles);
end;

constructor TMesh.Create;
begin
  Color := Vector(1, 1, 1, 1);
  MinDistance := 0;
  MaxDistance := 10000;
  Texture := nil;
  BumpMap := nil;
  Parent := nil;
  RotationMatrix := Identity3D;
  Offset := Vector(0, 0, 0);
  StaticRotationMatrix := Identity3D;
  StaticOffset := Vector(0, 0, 0);
end;



function MakeRay(A, B: TVector3D): TRay;
begin
  Result[0] := A;
  Result[1] := B;
end;

function MakeTriangle(A, B, C: TVector3D): TTriangle;
begin
  Result[0] := A;
  Result[1] := B;
  Result[2] := C;
end;

function MakeTriangleFromMeshTriangleVertexArray(Mesh: TMesh; A: TMeshTriangleVertexArray): TTriangle;
begin
  Result[0] := Vector3D(Vector(Mesh.Vertices[A[0]].Position, 1.0) * Mesh.TransformMatrix);
  Result[1] := Vector3D(Vector(Mesh.Vertices[A[1]].Position, 1.0) * Mesh.TransformMatrix);
  Result[2] := Vector3D(Vector(Mesh.Vertices[A[2]].Position, 1.0) * Mesh.TransformMatrix);
end;

function MakeMeshVertex(P, N: TVector3D; T: TVector2D): TMeshVertex;
begin
  Result.Position := P;
  Result.Normal := N;
  Result.TexCoord := T;
  Result.BumpTexCoordFactor := 1;
  Result.BumpTangent := Cross(Result.Normal, Vector(0, 1, 0));
end;

function MakeExtendedMeshVertex(P, N: TVector3D; T: TVector2D; BF: Single; B: TVector3D): TMeshVertex;
begin
  Result.Position := P;
  Result.Normal := N;
  Result.TexCoord := T;
  Result.BumpTexCoordFactor := 1;
  Result.BumpTangent := B;
end;

//
// This is a port of the Ray-Triangle-Implementation from
// http://softsurfer.com/Archive/algorithm_0105/algorithm_0105.htm
//

function RayTriangleIntersection(Ray: TRay; Tri: TTriangle; var I: TVector3D): Boolean;
var
  u, v, n: TVector3D;          // triangle vectors
  dir, w0, w: TVector3D;       // ray vectors
  r, a, b: Single;             // params to calc ray-plane intersect
  uu, uv, vv, wu, wv, D, s, t: Single;
begin
  I := Vector(0, 0, 0);
  // get triangle edge vectors and plane normal
  u := Tri[1] - Tri[0];
  v := Tri[2] - Tri[0];
  n := Cross(u, v);              // cross product
  if (VecLength(n) = 0) then     // triangle is degenerate
    exit(false);                 // do not deal with this case

  dir := Ray[1];                 // ray direction vector
  w0 := Ray[0] - Tri[0];
  a := -DotProduct(n, w0);
  b := DotProduct(n, dir);
  if (abs(b) < 0.0001) then      // ray is parallel to triangle plane
    if (a = 0) then              // ray lies in triangle plane
      exit(true)
    else                         // ray disjoint from plane
      exit(false);

  // get intersect point of ray with triangle plane
  r := a / b;
  if (r < 0.0) then              // ray goes away from triangle
    exit(false);                 // => no intersect
  // for a segment, also test if (r > 1.0) => no intersect

  I := Ray[0] + dir * r;         // intersect point of ray and plane

  // is I inside T?
  uu := DotProduct(u,u);
  uv := DotProduct(u,v);
  vv := DotProduct(v,v);
  w := I - Tri[0];
  wu := DotProduct(w,u);
  wv := DotProduct(w,v);
  D := uv * uv - uu * vv;

  // get and test parametric coords
  s := (uv * wv - vv * wu) / D;
  if ((s < 0.0) or (s > 1.0)) then       // I is outside T
    exit(false);
  t := (uv * wu - uu * wv) / D;
  if ((t < 0.0) or ((s + t) > 1.0)) then // I is outside T
    exit(false);

  Result := true;                 // I is in T
end;

function MakeTriangleVertexArray(A, B, C: Integer): TMeshTriangleVertexArray;
begin
  Result[0] := A;
  Result[1] := B;
  Result[2] := C;
end;

end.