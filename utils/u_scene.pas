unit u_scene;

interface

uses
  SysUtils, Classes, u_math, u_vectors, m_texmng_class;

type
  TLightSource = class
    public
      Name: String;
      Position: TVector4D;
      Color: TVector3D;
      Energy, FalloffDistance: Single;
      DiffuseFactor, AmbientFactor: Single;
      CastShadows: Boolean;
      function Duplicate: TLightSource;
      constructor Create;
      destructor Free;
    end;

  TBone = class;
  TArmature = class;
  TGeoObject = class;
  TGeoMesh = class;

  TBoneEffect = record
    Bone: TBone;
    Weight: Single;
    end;
  PBoneEffect = ^TBoneEffect;

  TVertex = record
    VertexID: Integer;
    Changed: Boolean;
    ParentMesh: TGeoMesh;
    Color: TVector4D;
    Position, VertexNormal: TVector3D;
    OriginalPosition: TVector3D;
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
    ParentMesh: TGeoMesh;
    end;
  PFace = ^TFace;

  TBone = class
    protected
      fCalculatedMatrix: TMatrix4D;
      fCalculatedSourcePosition: TVector3D;
    public
      SourcePosition, DestinationPosition: TVector3D;
      Matrix: TMatrix4D;
      Name: String;
      Updated: Boolean;
      ParentBone: TBone;
      ParentArmature: TArmature;
      Children: Array of TBone;
      property CalculatedMatrix: TMatrix4D read fCalculatedMatrix;
      property CalculatedSourcePosition: TVector3D read fCalculatedSourcePosition;
      procedure AddChild(Bone: TBone);
      procedure UpdateMatrix;
      function Duplicate: TBone;
      constructor Create;
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
      ParentArmature: TArmature;
      ParentObject: TGeoObject;
      CalculatedMatrix, Matrix: TMatrix4D;
      Children: Array of TArmature;
      function Duplicate: TArmature;
      function AddBone: TBone;
      procedure UpdateMatrix;
      procedure AddChild(A: TArmature);
      constructor Create;
    end;

  TMaterial = class
    public
      Color, Emission: TVector4D;
      Reflectivity: Single;
      RefractionValue: Single;
      Hardness, Specularity: Single;
      BumpMapFactor: Single;
      Texture, BumpMap, LightFactorMap: TTexture;
      function Transparent: Boolean;
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
      procedure AddBoneToAll(B: TBone);
      procedure RecalcFaceNormals;
      procedure RecalcVertexNormals;
      function Duplicate: TGeoMesh;
      function AddVertex: PVertex;
      function AddTextureVertex: PTextureVertex;
      function AddFace: PFace;
      procedure AddChild(Mesh: TGeoMesh);
      procedure UpdateFaceVertexAssociationForVertexNormalCalculation;
      procedure UpdateMatrix;
      procedure UpdateVertexPositions;
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
      procedure UpdateVertexPositions;
      procedure UpdateArmatures;
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



procedure TBone.AddChild(Bone: TBone);
begin
  Bone.ParentBone := Self;
  SetLength(Children, Length(Children) + 1);
  Children[high(Children)] := Bone;
end;

procedure TBone.UpdateMatrix;
var
  i: Integer;
begin
  if ParentBone <> nil then
    fCalculatedMatrix := ParentBone.CalculatedMatrix * Matrix
  else
    fCalculatedMatrix := ParentArmature.CalculatedMatrix * Matrix;
  fCalculatedSourcePosition := Vector3D(Vector(SourcePosition, 1) * fCalculatedMatrix);
  for i := 0 to high(Children) do
    Children[i].UpdateMatrix;
end;

function TBone.Duplicate: TBone;
begin
end;

constructor TBone.Create;
begin
  fCalculatedMatrix := Identity4D;
  Matrix := Identity4D;
  ParentBone := nil;
  ParentArmature := nil;
  SourcePosition := Vector(0, 0, 0);
  DestinationPosition := Vector(0, 1, 0);
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
  SetLength(Bones, Length(Bones) + 1);
  Bones[high(Bones)] := TBone.Create;
  Result := Bones[high(Bones)];
  Result.ParentArmature := Self;
end;

procedure TArmature.UpdateMatrix;
var
  i: Integer;
begin
  if ParentArmature <> nil then
    CalculatedMatrix := ParentArmature.CalculatedMatrix * Matrix
  else
    CalculatedMatrix := Matrix;
  for i := 0 to high(Bones) do
    if Bones[i].ParentBone = nil then
      Bones[i].UpdateMatrix;
  for i := 0 to high(Children) do
    Children[i].UpdateMatrix;
end;

procedure TArmature.AddChild(A: TArmature);
begin
  SetLength(Children, length(Children) + 1);
  Children[high(Children)] := A;
  A.ParentArmature := Self;
end;

constructor TArmature.Create;
begin
  ParentArmature := nil;
  ParentObject := nil;
  CalculatedMatrix := Identity4D;
  Matrix := Identity4D;
end;


function TMaterial.Duplicate: TMaterial;
begin
end;

function TMaterial.Transparent: Boolean;
begin
  if Color.w < 1 then
    exit(true);
  if Texture <> nil then
    Result := Texture.BPP = 4;
end;

constructor TMaterial.Create;
begin
  Color := Vector(1, 1, 1, 1);
  Emission := Vector(0, 0, 0, 1);
  Reflectivity := 0;
  RefractionValue := 0;
  Specularity := 1;
  Hardness := 20;
  BumpMapFactor := 1;
  Texture := nil;
  BumpMap := nil;
  LightFactorMap := nil;
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
  Result^.ParentMesh := Self;
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
  Result^.ParentMesh := Self;
end;

procedure TGeoMesh.AddBoneToAll(B: TBone);
var
  i: Integer;
begin
  for i := 0 to high(Vertices) do
    begin
    SetLength(Vertices[i].Bones, length(Vertices[i].Bones) + 1);
    with Vertices[i].Bones[high(Vertices[i].Bones)] do
      begin
      Bone := B;
      Weight := 1;
      end;
    end;
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
    begin
    SetLength(Vertices[i].FaceIDs, 0);
    Vertices[i].OriginalPosition := Vertices[i].Position;
    end;
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
  else if ParentObject <> nil then
    CalculatedMatrix := ParentObject.Matrix * Matrix
  else
    CalculatedMatrix := Matrix;
  for i := 0 to high(Children) do
    Children[i].UpdateMatrix;
end;

procedure TGeoMesh.UpdateVertexPositions;
var
  i, j: Integer;
  CalculatedVertexPosition: TVector3D;
  TotalMeshOffset, ObjectOffset, RelativeMeshOffset: TVector3D;
begin
  TotalMeshOffset := Vector3D(Vector(0, 0, 0, 1) * CalculatedMatrix);
  ObjectOffset := Vector3D(Vector(0, 0, 0, 1) * ParentObject.Matrix);
  RelativeMeshOffset := TotalMeshOffset - ObjectOffset;
  for i := 0 to high(Vertices) do
    if length(Vertices[i].Bones) > 0 then
      begin
      CalculatedVertexPosition := Vector3D(Vector(Vertices[i].OriginalPosition, 1)) + RelativeMeshOffset;
      for j := 0 to high(Vertices[i].Bones) do
        CalculatedVertexPosition := MixVec(CalculatedVertexPosition, Vector3D(Vector(CalculatedVertexPosition - Vertices[i].Bones[j].Bone.SourcePosition, 1) * Vertices[i].Bones[j].Bone.CalculatedMatrix) + Vertices[i].Bones[j].Bone.SourcePosition, Vertices[i].Bones[j].Weight);
      Vertices[i].Position := CalculatedVertexPosition - RelativeMeshOffset;
      Vertices[i].Changed := True;
      end;
end;

constructor TGeoMesh.Create;
begin
  ParentObject := nil;
  Parent := nil;
  Name := '';
  Changed := true;
  MinDistance := -10000;
  MaxDistance := 10000;
  Matrix := Identity4D;
  CalculatedMatrix := Identity4D;
  Material := nil;
end;

destructor TGeoMesh.Free;
begin
  SetLength(Faces, 0);
  SetLength(Vertices, 0);
  SetLength(TextureVertices, 0);
  EventManager.CallEvent('TGeoObject.DeletedMesh', ParentObject, Self);
end;




function TGeoObject.AddArmature: TArmature;
begin
  SetLength(Armatures, length(Armatures) + 1);
  Armatures[high(Armatures)] := TArmature.Create;
  Result := Armatures[high(Armatures)];
  Result.ParentObject := Self;
end;

function TGeoObject.AddMesh: TGeoMesh;
begin
  SetLength(Meshes, length(Meshes) + 1);
  Meshes[high(Meshes)] := TGeoMesh.Create;
  Result := Meshes[high(Meshes)];
  Result.ParentObject := Self;
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

procedure TGeoObject.UpdateArmatures;
var
  i: Integer;
begin
  for i := 0 to high(Armatures) do
    if Armatures[i].ParentArmature = nil then
      Armatures[i].UpdateMatrix;
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

procedure TGeoObject.UpdateVertexPositions;
var
  i: Integer;
begin
  for i := 0 to high(Meshes) do
    Meshes[i].UpdateVertexPositions;
end;

constructor TGeoObject.Create;
begin
  Matrix := Identity4D;
end;

destructor TGeoObject.Free;
var
  i: Integer;
begin
  for i := 0 to high(Meshes) do
    Meshes[i].Free;
  for i := 0 to high(Materials) do
    Materials[i].Free;
  for i := 0 to high(Armatures) do
    Armatures[i].Free;
  EventManager.CallEvent('TGeoObject.Deleted', Self, nil);
end;


end.