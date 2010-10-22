unit u_scene;

interface

uses
  SysUtils, Classes, u_math, u_vectors, m_texmng_class;

type
  TLightSource = class
    public
      Name: String;
      Position: TVector4D;
      Color: TVector4D;
      Energy, FalloffDistance: Single;
      DiffuseFactor, AmbientFactor: Single;
      CastShadows: Boolean;
      function Duplicate: TLightSource;
      constructor Create;
      destructor Free;
    end;

  TBone = class;

  TBoneEffect = record
    Bone: TBone;
    Weight: Single;
    end;
  PBoneEffect = ^TBoneEffect;

  TVertex = record
    VertexID: Integer;
    Changed: Boolean;
    Color: TVector4D;
    Position, VertexNormal: TVector3D;
    OriginalPosition, OriginalNormal: TVector3D;
    Bones: Array of TBoneEffect;
    FaceIDs: Array of Integer;
    UseFacenormal: Boolean;
    end;
  PVertex = ^TVertex;

  TTextureVertex = record
    Position: TVector2D;
    end;
  PTextureVertex = ^TTextureVertex;

  TTriangleIndexList = Array[0..2] of Integer;

  TFace = record
    FaceID: Integer;
    Vertices, TexCoords: TTriangleIndexList;
    FaceNormal: TVector3D;
    end;
  PFace = ^TFace;

  TBone = class
    protected
      fSourcePosition, fDestinationPosition: TVector3D;
      fMatrix: TMatrix4D;
      procedure SetSourcePosition(S: TVector3D);
      procedure SetDestinationPosition(D: TVector3D);
      procedure SetMatrix(Matrix: TMatrix4D);
    public
      Name: String;
      Updated: Boolean;
      ParentBone: TBone;
      property SourcePosition: TVector3D read fSourcePosition write SetSourcePosition;
      property DestinationPosition: TVector3D read fDestinationPosition write SetDestinationPosition;
      property Matrix: TMatrix4D read fMatrix write SetMatrix;
      function Duplicate: TBone;
    end;

  TBezierPoint = record
    HandleRight, HandleLeft, Position: TVector3D;
    end;
  PBezierPoint = ^TBezierPoint;

  TMotionPath = class
    public
      Name: String;
      BezierPoints: Array of TBezierPoint;
      FrameDuration: Integer;
      Infinite: Boolean;
      function Duplicate: TMotionPath;
      function AddBezierPoint: PBezierPoint;
    end;

  TMotionPathConstraint = record
    MotionPath: TMotionPath;
    Influence: Single;
    MotionProgress: Single;
    end;
  PMotionPathConstraint = ^TMotionPathConstraint;

  TArmature = class
    public
      Name: String;
      Bones: Array of TBone;
      function Duplicate: TArmature;
      function AddBone: TBone;
    end;

  TGeoObject = class;

  TMaterial = class
    public
      Color: TVector4D;
      Reflectivity: Single;
      RefractionValue: Single;
      Specularity: Single;
      BumpMapFactor: Single;
      Texture, BumpMap: TTexture;
      function Duplicate: TMaterial;
      constructor Create;
    end;

  TGeoMesh = class
    public
      Name: String;
      Changed: Boolean;
      MinDistance, MaxDistance: Single;
      Vertices: Array of TVertex;
      TextureVertices: Array of TTextureVertex;
      Faces: Array of TFace;
      MotionPaths: Array of TMotionPathConstraint;
      Parent: TGeoMesh;
      Children: Array of TGeoMesh;
      Matrix, CalculatedMatrix: TMatrix4D;
      ParentObject: TGeoObject;
      Material: TMaterial;
      procedure RecalcFaceNormals;
      procedure RecalcVertexNormals;
      function Duplicate: TGeoMesh;
      function AddVertex: PVertex;
      function AddTextureVertex: PTextureVertex;
      function AddFace: PFace;
      procedure ChangesApplied;
      procedure AddChild(Mesh: TGeoMesh);
      procedure UpdateFaceVertexAssociationForVertexNormalCalculation;
      procedure UpdateMatrix;
      constructor Create;
      destructor Free;
    end;

  TGeoObject = class
    public
      Meshes: Array of TGeoMesh;
      Armatures: Array of TArmature;
      Materials: Array of TMaterial;
//       Script: TScript;
      Matrix: TMatrix4D;
      function AddArmature: TArmature;
      function AddMesh: TGeoMesh;
      function AddMaterial: TMaterial;
      function Duplicate: TGeoObject;
      procedure UpdateMatrix;
      procedure Register;
      procedure RecalcFaceNormals;
      procedure RecalcVertexNormals;
      constructor Create;
      destructor Free;
    end;

function TriangleIndexList(A, B, C: Integer): TTriangleIndexList;

implementation

uses
  u_events;

function TriangleIndexList(A, B, C: Integer): TTriangleIndexList;
begin
  Result[0] := A;
  Result[1] := B;
  Result[2] := C;
end;




function TLightSource.Duplicate: TLightSource;
begin
end;

constructor TLightSource.Create;
begin
  EventManager.CallEvent('TLightSource.Deleted', self, self);
end;

destructor TLightSource.Free;
begin
  EventManager.CallEvent('TLightSource.Deleted', self, nil);
end;



procedure TBone.SetSourcePosition(S: TVector3D);
begin
  fSourcePosition := S;
  Updated := true;
end;

procedure TBone.SetDestinationPosition(D: TVector3D);
begin
  fDestinationPosition := D;
  Updated := true;
end;

procedure TBone.SetMatrix(Matrix: TMatrix4D);
begin
  fMatrix := Matrix;
  Updated := true;
end;

function TBone.Duplicate: TBone;
begin
end;




function TMotionPath.Duplicate: TMotionPath;
begin
end;

function TMotionPath.AddBezierPoint: PBezierPoint;
begin
  SetLength(BezierPoints, length(BezierPoints) + 1);
  Result := @BezierPoints[high(BezierPoints)];
end;




function TArmature.Duplicate: TArmature;
begin
end;

function TArmature.AddBone: TBone;
begin
  SetLength(Bones, high(Bones) + 1);
  Bones[high(Bones)] := TBone.Create;
  Result := Bones[high(Bones)];
end;



function TMaterial.Duplicate: TMaterial;
begin
end;

constructor TMaterial.Create;
begin
  Color := Vector(1, 1, 1, 1);
  Reflectivity := 0;
  RefractionValue := 0;
  Specularity := 20;
  BumpMapFactor := 1;
  Texture := nil;
  BumpMap := nil;
end;


procedure TGeoMesh.RecalcFaceNormals;
var
  i: Integer;
begin
  for i := 0 to high(Faces) do
    Faces[i].FaceNormal := Normal(Vertices[Faces[i].Vertices[0]].Position - Vertices[Faces[i].Vertices[1]].Position, Vertices[Faces[i].Vertices[2]].Position - Vertices[Faces[i].Vertices[1]].Position) * -1;
end;

procedure TGeoMesh.RecalcVertexNormals;
var
  i, j: Integer;
begin
  for i := 0 to high(Vertices) do
    if Vertices[i].Changed then
      begin
      Vertices[i].VertexNormal := Vector(0, 0, 0);
      for j := 0 to high(Vertices[i].FaceIDs) do
        Vertices[i].VertexNormal := Vertices[i].VertexNormal + Faces[Vertices[i].FaceIDs[j]].FaceNormal;
      Vertices[i].VertexNormal := Normalize(Vertices[i].VertexNormal);
      end;
end;

function TGeoMesh.Duplicate: TGeoMesh;
begin
end;

function TGeoMesh.AddVertex: PVertex;
begin
  SetLength(Vertices, length(Vertices) + 1);
  Result := @Vertices[high(Vertices)];
  Result^.Changed := True;
  Result^.VertexID := high(Vertices);
end;

function TGeoMesh.AddTextureVertex: PTextureVertex;
begin
  SetLength(TextureVertices, length(TextureVertices) + 1);
  Result := @TextureVertices[high(TextureVertices)];
end;

function TGeoMesh.AddFace: PFace;
begin
  SetLength(Faces, length(Faces) + 1);
  Result := @Faces[high(Faces)];
  Result^.FaceID := high(Faces);
end;

procedure TGeoMesh.ChangesApplied;
begin
end;

procedure TGeoMesh.AddChild(Mesh: TGeoMesh);
begin
  Mesh.Parent := Self;
  SetLength(Children, length(Children) + 1);
  Children[high(Children)] := Mesh;
end;

procedure TGeoMesh.UpdateFaceVertexAssociationForVertexNormalCalculation;
var
  i, j: Integer;
begin
  for i := 0 to high(Vertices) do
    SetLength(Vertices[i].FaceIDs, 0);
  for i := 0 to high(Faces) do
    for j := 0 to 2 do
      with Vertices[Faces[i].Vertices[j]] do
        begin
        SetLength(FaceIDs, Length(FaceIDs) + 1);
        FaceIDs[high(FaceIDs)] := i;
        end;
end;

procedure TGeoMesh.UpdateMatrix;
var
  i: Integer;
begin
  if Parent <> nil then
    CalculatedMatrix := Parent.CalculatedMatrix * Matrix
  else
    CalculatedMatrix := ParentObject.Matrix * Matrix;
  for i := 0 to high(Children) do
    Children[i].UpdateMatrix;
end;

constructor TGeoMesh.Create;
begin
  ParentObject := nil;
  Parent := nil;
  Name := '';
  Changed := true;
  MinDistance := 0;
  MaxDistance := 10000;
  Matrix := Identity4D;
  CalculatedMatrix := Identity4D;
  Material := nil;
end;

destructor TGeoMesh.Free;
begin
//   SetLength(Faces, 0);
//   SetLength(Vertices, 0);
//   SetLength(TextureVertices, 0);
  EventManager.CallEvent('TGeoObject.DeletedMesh', ParentObject, Self);
end;




function TGeoObject.AddArmature: TArmature;
begin
  SetLength(Armatures, length(Armatures) + 1);
  Armatures[high(Armatures)] := TArmature.Create;
  Result := Armatures[high(Armatures)];
end;

function TGeoObject.AddMesh: TGeoMesh;
begin
  SetLength(Meshes, length(Meshes) + 1);
  Meshes[high(Meshes)] := TGeoMesh.Create;
  Result := Meshes[high(Meshes)];
  Result.ParentObject := Self;
  EventManager.CallEvent('TGeoObject.AddedMesh', Self, Result);
end;

function TGeoObject.AddMaterial: TMaterial;
begin
  SetLength(Materials, length(Materials) + 1);
  Materials[high(Materials)] := TMaterial.Create;
  Result := Materials[high(Materials)];
end;

function TGeoObject.Duplicate: TGeoObject;
begin
end;

procedure TGeoObject.UpdateMatrix;
var
  i: Integer;
begin
  for i := 0 to high(Meshes) do
    if Meshes[i].Parent = nil then
      Meshes[i].UpdateMatrix;
end;

procedure TGeoObject.Register;
var
  i: Integer;
begin
  EventManager.CallEvent('TGeoObject.Created', Self, nil);
  for i := 0 to high(Meshes) do
    EventManager.CallEvent('TGeoObject.AddedMesh', Self, Meshes[i]);
end;

procedure TGeoObject.RecalcFaceNormals;
var
  i: Integer;
begin
  for i := 0 to high(Meshes) do
    Meshes[i].RecalcFaceNormals;
end;

procedure TGeoObject.RecalcVertexNormals;
var
  i: Integer;
begin
  for i := 0 to high(Meshes) do
    Meshes[i].RecalcVertexNormals;
end;

constructor TGeoObject.Create;
begin
  Matrix := Identity4D;
end;

destructor TGeoObject.Free;
var
  i: Integer;
begin
// Do not uncomment - seems to be an annoying bug in freepascal
//   for i := 0 to high(Meshes) do
//     Meshes[i].Free;
  for i := 0 to high(Materials) do
    Materials[i].Free;
  for i := 0 to high(Armatures) do
    Armatures[i].Free;
  EventManager.CallEvent('TGeoObject.Deleted', Self, nil);
end;


end.