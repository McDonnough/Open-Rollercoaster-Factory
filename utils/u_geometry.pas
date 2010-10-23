unit u_geometry;

interface

uses
  SysUtils, Classes, u_math, u_vectors, m_texmng_class, u_scene;

type
  TTriangle = Array[0..2] of TVector3D;
  TRay = Array[0..1] of TVector3D;

function MakeRay(A, B: TVector3D): TRay;
function MakeTriangle(A, B, C: TVector3D): TTriangle;
function RayTriangleIntersection(Ray: TRay; Tri: TTriangle; var I: TVector3D): Boolean;
function MakeTriangleFromFace(Mesh: TGeoMesh; A: TFace): TTriangle;

implementation

uses
  u_selection, u_events, u_ase;


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



function MakeTriangleFromFace(Mesh: TGeoMesh; A: TFace): TTriangle;
begin
  Result[0] := Mesh.Vertices[A.Vertices[0]].Position;
  Result[1] := Mesh.Vertices[A.Vertices[1]].Position;
  Result[2] := Mesh.Vertices[A.Vertices[2]].Position;
end;

end.