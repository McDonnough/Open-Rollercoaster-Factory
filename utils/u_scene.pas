unit u_scene;

interface

uses
  SysUtils, Classes, u_math, u_vectors, m_texmng_class, u_pathes, u_scripts, m_sound_class;

type
  TLightSource = class
    public
      Name: String;
      OriginalPosition, Position: TVector4D;
      Color: TVector3D;
      Energy, FalloffDistance: Single;
      DiffuseFactor: Single;
      CastShadows: Boolean;
      function Duplicate: TLightSource;
      procedure Register;
      procedure SetIO(Script: TScript);
      class procedure RegisterStruct;
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

  TMotionPathConstraint = record
    Path: TPath;
    Progress: Single;
    FollowBanking, FollowOrientation: Boolean;
    end;
    
  TBone = class
    protected
      fCalculatedMatrix: TMatrix4D;
      fCalculatedSourcePosition: TVector3D;
    public
      BoneID: Integer;
      SourcePosition: TVector3D;
      Matrix: TMatrix4D;
      Name: String;
      Updated: Boolean;
      ParentBone: TBone;
      ParentArmature: TArmature;
      Children: Array of TBone;
      PathConstraint: TMotionPathConstraint;
      property CalculatedMatrix: TMatrix4D read fCalculatedMatrix;
      property CalculatedSourcePosition: TVector3D read fCalculatedSourcePosition;
      procedure AddChild(Bone: TBone);
      procedure UpdateMatrix;
      function Duplicate(TheObject: TGeoObject; TheArmature: TArmature): TBone;
      procedure SetIO(Script: TScript);
      class procedure RegisterStruct;
      constructor Create;
    end;

  TArmature = class
    public
      ArmatureID: Integer;
      Name: String;
      Bones: Array of TBone;
      ParentObject: TGeoObject;
      CalculatedMatrix, Matrix: TMatrix4D;
      function Duplicate(TheObject: TGeoObject): TArmature;
      function AddBone: TBone;
      function GetBoneByName(Bone: String): TBone;
      procedure UpdateMatrix;
      procedure SetIO(Script: TScript);
      class procedure RegisterStruct;
      constructor Create;
    end;

  TMaterial = class
    public
      Name: String;
      MaterialID: Integer;
      Color, Emission: TVector4D;
      Reflectivity: Single;
      Hardness, Specularity: Single;
      RefractiveIndex: Single;
      Texture, BumpMap: TTexture;
      OnlyEnvironmentMapHint: Boolean;
      function Transparent: Boolean;
      function Duplicate: TMaterial;
      procedure SetIO(Script: TScript);
      class procedure RegisterStruct;
      constructor Create;
    end;

  TGeoMesh = class
    public
      MeshID: Integer;
      Name: String;
      Bone: TBone;
      Changed: Boolean;
      Vertices: Array of TVertex;
      TextureVertices: Array of TTextureVertex;
      Faces: Array of TFace;
      Parent: TGeoMesh;
      Children: Array of TGeoMesh;
      MinDistance, MaxDistance: Single;
      Matrix, CalculatedMatrix: TMatrix4D;
      ParentObject: TGeoObject;
      Material: TMaterial;
      LightSources: Array of TLightSource;
      SoundSources: Array of TSoundSource;
      ParticleGroups: Array of Pointer; // Sorry, circular unit reference. Bad class management, I know
      procedure AddBoneToAll(B: TBone);
      procedure AddBone(B: TBone);
      procedure RecalcFaceNormals;
      procedure RecalcVertexNormals;
      function Duplicate(TheObject: TGeoObject): TGeoMesh;
      function AddVertex: PVertex;
      function AddTextureVertex: PTextureVertex;
      function AddFace: PFace;
      procedure AddChild(Mesh: TGeoMesh);
      procedure UpdateFaceVertexAssociationForVertexNormalCalculation;
      procedure UpdateMatrix;
      procedure UpdateVertexPositions;
      procedure Register;
      procedure SetIO(Script: TScript);
      class procedure RegisterStruct;
      constructor Create;
      destructor Free;
    end;

  TGeoObject = class
    private
      Counts: Array[0..5] of PtrUInt;
      Offsets: Array[0..5] of PtrUInt;
      ObjectID: Integer;
    public
      Mirror: TVector3D;
      Meshes: Array of TGeoMesh;
      Armatures: Array of TArmature;
      Materials: Array of TMaterial;
      Script: TScript;
      Matrix: TMatrix4D;
      FirstRun: Boolean;
      property SelectionID: Integer read ObjectID;
      function AddArmature: TArmature;
      function AddMesh: TGeoMesh;
      function AddMaterial: TMaterial;
      function AddMaterial(A: TMaterial): TMaterial;
      function Duplicate: TGeoObject;
      procedure UpdateMatrix;
      procedure Register;
      procedure RecalcFaceNormals;
      procedure RecalcVertexNormals;
      procedure UpdateVertexPositions;
      procedure UpdateArmatures;
      procedure UpdateFaceVertexAssociationForVertexNormalCalculation;
      procedure SetUnchanged;
      function GetBoneByName(Armature, Bone: String): TBone;
      function GetMeshByName(Mesh: String): TGeoMesh;
      function GetMaterialByName(Mat: String): TMaterial;
      procedure ExecuteScript;
      procedure SetIO;
      class procedure RegisterStruct;
      constructor Create;
      destructor Free;
    end;

function TriangleIndexList(A, B, C: Integer): TTriangleIndexList;

implementation

uses
  u_events, u_particles, main, m_varlist;

var
  ObjectCount: Integer = 2;

function TriangleIndexList(A, B, C: Integer): TTriangleIndexList;
begin
  Result[0] := A;
  Result[1] := B;
  Result[2] := C;
end;




function TLightSource.Duplicate: TLightSource;
begin
  Result := TLightSource.Create;
  Result.Name := Name;
  Result.OriginalPosition := OriginalPosition;
  Result.Position := Position;
  Result.Color := Color;
  Result.Energy := Energy;
  Result.FalloffDistance := FalloffDistance;
  Result.DiffuseFactor := DiffuseFactor;
  Result.CastShadows := CastShadows;
end;

procedure TLightSource.Register;
begin
  EventManager.CallEvent('TLightSource.Added', self, nil);
end;

procedure TLightSource.SetIO(Script: TScript);
const
  SIZE: Integer = SizeOf(TVector4D) + SizeOf(TVector3D) + 3 * SizeOf(Single);
begin
  Script.SetIO(@Self.Position, SIZE, true);
end;

class procedure TLightSource.RegisterStruct;
begin
  ModuleManager.ModScriptManager.SetDataStructure('Lamp',
   'vec4 position' + #10 +
   'vec3 color' + #10 +
   'float energy' + #10 +
   'float falloff' + #10 +
   'float factor');
end;

constructor TLightSource.Create;
begin
  Energy := 1;
  FalloffDistance := 1;
  Color := Vector(1, 1, 1);
  DiffuseFactor := 1;
  Name := '';
  CastShadows := True;
  Position := Vector(0, 0, 0, 1);
  OriginalPosition := Vector(0, 0, 0, 1);
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
  fTempMatrix: TMatrix4D;
  pp: TPathPointData;
begin
  if PathConstraint.Path <> nil then
    begin
    pp := PathConstraint.Path.DataAtT(PathConstraint.Progress);

    fTempMatrix := TranslationMatrix(pp.Position);

    if PathConstraint.FollowOrientation then
      fTempMatrix := fTempMatrix * RotationMatrix(pp.Tangent);

    if PathConstraint.FollowBanking then
      fTempMatrix := fTempMatrix * RotationMatrix(pp.Banking, Vector(0, 0, 1));

    fTempMatrix := fTempMatrix * Matrix;
    end
  else
    fTempMatrix := Matrix;
  
  if ParentBone <> nil then
    fCalculatedMatrix := ParentBone.CalculatedMatrix * fTempMatrix
  else
    fCalculatedMatrix := ParentArmature.CalculatedMatrix * fTempMatrix;
  fCalculatedSourcePosition := Vector3D(Vector(SourcePosition, 1) * fCalculatedMatrix);
  for i := 0 to high(Children) do
    Children[i].UpdateMatrix;
end;

function TBone.Duplicate(TheObject: TGeoObject; TheArmature: TArmature): TBone;
begin
  Result := TBone.Create;
  Result.fCalculatedMatrix := fCalculatedMatrix;
  Result.fCalculatedSourcePosition := fCalculatedSourcePosition;
  Result.BoneID := BoneID;
  Result.SourcePosition := SourcePosition;
  Result.Matrix := Matrix;
  Result.Name := Name;
  Result.Updated := Updated;
  Result.ParentArmature := TheArmature;
  if PathConstraint.Path <> nil then
    Result.PathConstraint.Path := PathConstraint.Path.Duplicate
  else
    Result.PathConstraint.Path := nil;
  Result.PathConstraint.Progress := PathConstraint.Progress;
  Result.PathConstraint.FollowBanking := PathConstraint.FollowBanking;
  Result.PathConstraint.FollowOrientation := PathConstraint.FollowOrientation;
  if ParentBone = nil then
    Result.ParentBone := nil
  else
    TheArmature.Bones[ParentBone.BoneID].AddChild(Result);
end;

procedure TBone.SetIO(Script: TScript);
const
  SIZE: Integer = SizeOf(TVector3D) + SizeOf(TMatrix4D);
begin
  Script.SetIO(@Self.SourcePosition, SIZE, true);
  Script.SetIO(@Self.PathConstraint.Progress, SizeOf(Single), true);
end;

class procedure TBone.RegisterStruct;
begin
  ModuleManager.ModScriptManager.SetDataStructure('Bone',
   'vec3 position' + #10 +
   'mat4 matrix' + #10 +
   'float progress');
end;

constructor TBone.Create;
begin
  fCalculatedMatrix := Identity4D;
  BoneID := -1;
  Matrix := Identity4D;
  ParentBone := nil;
  ParentArmature := nil;
  SourcePosition := Vector(0, 0, 0);
  PathConstraint.Path := nil;
  PathConstraint.Progress := 0;
  PathConstraint.FollowBanking := False;
  PathConstraint.FollowOrientation := False;
end;



function TArmature.Duplicate(TheObject: TGeoObject): TArmature;
var
  i: Integer;
begin
  Result := TArmature.Create;
  Result.ParentObject := TheObject;
  Result.ArmatureID := ArmatureID;
  Result.Name := Name;
  Result.CalculatedMatrix := CalculatedMatrix;
  Result.Matrix := Matrix;
  SetLength(Result.Bones, length(Bones));
  for i := 0 to high(Bones) do
    Result.Bones[i] := Bones[i].Duplicate(TheObject, Result);
end;

function TArmature.AddBone: TBone;
begin
  SetLength(Bones, Length(Bones) + 1);
  Bones[high(Bones)] := TBone.Create;
  Result := Bones[high(Bones)];
  Result.ParentArmature := Self;
  Result.BoneID := high(Bones);
end;

function TArmature.GetBoneByName(Bone: String): TBone;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(Bones) do
    if Bones[i].Name = Bone then
      Result := Bones[i];
end;

procedure TArmature.UpdateMatrix;
var
  i: Integer;
begin
  CalculatedMatrix := Matrix;
  for i := 0 to high(Bones) do
    if Bones[i].ParentBone = nil then
      Bones[i].UpdateMatrix;
end;

procedure TArmature.SetIO(Script: TScript);
const
  SIZE: Integer = SizeOf(TMatrix4D);
begin
  Script.SetIO(@Self.Matrix, SIZE, true);
end;

class procedure TArmature.RegisterStruct;
begin
  ModuleManager.ModScriptManager.SetDataStructure('Armature',
   'mat4 matrix');
end;

constructor TArmature.Create;
begin
  ArmatureID := -1;
  ParentObject := nil;
  CalculatedMatrix := Identity4D;
  Matrix := Identity4D;
end;


function TMaterial.Duplicate: TMaterial;
begin
  Result := TMaterial.Create;
  Result.Name := Name;
  Result.MaterialID := MaterialID;
  Result.Color := Color;
  Result.Emission := Emission;
  Result.Reflectivity := Reflectivity;
  Result.Hardness := Hardness;
  Result.Specularity := Specularity;
  Result.RefractiveIndex := RefractiveIndex;
  Result.Texture := Texture;
  Result.BumpMap := BumpMap;
  Result.OnlyEnvironmentMapHint := OnlyEnvironmentMapHint;
end;

function TMaterial.Transparent: Boolean;
begin
  Result := False;
  if Color.w < 1 then
    exit(true);
  if Texture <> nil then
    Result := Texture.BPP = 4;
end;

procedure TMaterial.SetIO(Script: TScript);
const
  SIZE: Integer = 2 * SizeOf(TVector4D) + 3 * SizeOf(Single);
begin
  Script.SetIO(@Self.Color, SIZE, true);
end;

class procedure TMaterial.RegisterStruct;
begin
  ModuleManager.ModScriptManager.SetDataStructure('Material',
   'vec4 color' + #10 +
   'vec4 emission' + #10 +
   'float reflectivity' + #10 +
   'float hardness' + #10 +
   'float specularity' + #10 +
   'float refractiveIndex');
end;

constructor TMaterial.Create;
begin
  MaterialID := -1;
  Name := '';
  Color := Vector(1, 1, 1, 1);
  Emission := Vector(0, 0, 0, 1);
  Reflectivity := 0;
  Specularity := 0;
  RefractiveIndex := 0;
  Hardness := 20;
  OnlyEnvironmentMapHint := false;
  Texture := nil;
  BumpMap := nil;
end;


procedure TGeoMesh.RecalcFaceNormals;
var
  i: Integer;
begin
  if Changed  then
    for i := 0 to high(Faces) do
      Faces[i].FaceNormal := Normal(Vertices[Faces[i].Vertices[0]].Position - Vertices[Faces[i].Vertices[1]].Position, Vertices[Faces[i].Vertices[2]].Position - Vertices[Faces[i].Vertices[1]].Position) * -1;
end;

procedure TGeoMesh.RecalcVertexNormals;
var
  i, j: Integer;
begin
  if Changed then
    for i := 0 to high(Vertices) do
      if Vertices[i].Changed then
        begin
        Vertices[i].VertexNormal := Vector(0, 0, 0);
        for j := 0 to high(Vertices[i].FaceIDs) do
          Vertices[i].VertexNormal := Vertices[i].VertexNormal + Faces[Vertices[i].FaceIDs[j]].FaceNormal;
        Vertices[i].VertexNormal := Normalize(Vertices[i].VertexNormal);
        end;
end;

function TGeoMesh.Duplicate(TheObject: TGeoObject): TGeoMesh;
var
  i, j: Integer;
begin
  Result := TGeoMesh.Create;
  Result.MeshID := MeshID;
  Result.Name := Name;
  if Bone <> nil then
    Result.Bone := TheObject.Armatures[Bone.ParentArmature.ArmatureID].Bones[Bone.BoneID]
  else
    Result.Bone := nil;
  Result.Changed := Changed;
  Result.MinDistance := MinDistance;
  Result.MaxDistance := MaxDistance;
  Result.ParentObject := TheObject;
  
  setLength(Result.Vertices, length(Vertices));
  setLength(Result.TextureVertices, length(TextureVertices));
  setLength(Result.Faces, length(Faces));

  for i := 0 to high(Vertices) do
    begin
    Result.Vertices[i].VertexID := Vertices[i].VertexID;
    Result.Vertices[i].Changed := True;
    Result.Vertices[i].ParentMesh := Self;
    Result.Vertices[i].Color := Vertices[i].Color;
    Result.Vertices[i].Position := Vertices[i].Position;
    Result.Vertices[i].VertexNormal := Vertices[i].VertexNormal;
    Result.Vertices[i].OriginalPosition := Vertices[i].OriginalPosition;
    Result.Vertices[i].UseFacenormal := Vertices[i].UseFacenormal;
    SetLength(Result.Vertices[i].FaceIDs, length(Vertices[i].FaceIDs));
    for j := 0 to high(Result.Vertices[i].FaceIDs) do
      Result.Vertices[i].FaceIDs[j] := Vertices[i].FaceIDs[j];
    SetLength(Result.Vertices[i].Bones, length(Vertices[i].Bones));
    for j := 0 to high(Result.Vertices[i].Bones) do
      begin
      Result.Vertices[i].Bones[j].Weight := Vertices[i].Bones[j].Weight;
      Result.Vertices[i].Bones[j].Bone := TheObject.Armatures[Vertices[i].Bones[j].Bone.ParentArmature.ArmatureID].Bones[Vertices[i].Bones[j].Bone.BoneID];
      end;
    end;

  for i := 0 to high(TextureVertices) do
    Result.TextureVertices[i].Position := TextureVertices[i].Position;

  for i := 0 to high(Faces) do
    begin
    Result.Faces[i].FaceID := Faces[i].FaceID;
    Result.Faces[i].FaceNormal := Faces[i].FaceNormal;
    Result.Faces[i].ParentMesh := Self;
    for j := 0 to 2 do
      begin
      Result.Faces[i].Vertices[j] := Faces[i].Vertices[j];
      Result.Faces[i].TexCoords[j] := Faces[i].TexCoords[j];
      end;
    end;
  
  if Parent = nil then
    Result.Parent := nil
  else
    TheObject.Meshes[Parent.MeshID].AddChild(Result);

  Result.Matrix := Matrix;
  Result.CalculatedMatrix := CalculatedMatrix;
  if Material = nil then
    Result.Material := nil
  else
    Result.Material := TheObject.Materials[Material.MaterialID];

  SetLength(Result.LightSources, length(LightSources));
  for i := 0 to high(LightSources) do
    Result.LightSources[i] := LightSources[i].Duplicate;

  SetLength(Result.ParticleGroups, length(ParticleGroups));
  for i := 0 to high(ParticleGroups) do
    Result.ParticleGroups[i] := TParticleGroup(ParticleGroups[i]).Duplicate;

  setLength(Result.SoundSources, length(SoundSources));
  for i := 0 to high(SoundSources) do
    Result.SoundSources[i] := SoundSources[i].Duplicate;
end;

function TGeoMesh.AddVertex: PVertex;
begin
  Changed := True;
  SetLength(Vertices, length(Vertices) + 1);
  Result := @Vertices[high(Vertices)];
  Result^.Changed := True;
  Result^.VertexID := high(Vertices);
  Result^.ParentMesh := Self;
  Result^.Color := Vector(1, 1, 1, 1);
  Result^.Position := Vector(0, 0, 0);
  Result^.VertexNormal := Vector(0, 0, 0);
  Result^.OriginalPosition := Vector(0, 0, 0);
  Result^.UseFacenormal := True;
end;

function TGeoMesh.AddTextureVertex: PTextureVertex;
begin
  Changed := True;
  SetLength(TextureVertices, length(TextureVertices) + 1);
  Result := @TextureVertices[high(TextureVertices)];
  Result^.Position := Vector(0, 0);
end;

function TGeoMesh.AddFace: PFace;
begin
  Changed := True;
  SetLength(Faces, length(Faces) + 1);
  Result := @Faces[high(Faces)];
  Result^.FaceID := high(Faces);
  Result^.ParentMesh := Self;
  Result^.Vertices[0] := 0;
  Result^.Vertices[1] := 1;
  Result^.Vertices[2] := 2;
  Result^.TexCoords[0] := 0;
  Result^.TexCoords[1] := 1;
  Result^.TexCoords[2] := 2;
  Result^.FaceNormal := Vector(0, 0, 0);
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

procedure TGeoMesh.AddBone(B: TBone);
begin
  Bone := B;
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
  if Bone <> nil then
    begin
    CalculatedMatrix := CalculatedMatrix * TranslationMatrix(Bone.SourcePosition);
    CalculatedMatrix := CalculatedMatrix * Bone.CalculatedMatrix;
    CalculatedMatrix := CalculatedMatrix * TranslationMatrix(Bone.SourcePosition * -1);
    end;
  for i := 0 to high(LightSources) do
    LightSources[i].Position := LightSources[i].OriginalPosition * CalculatedMatrix;
  for i := 0 to high(ParticleGroups) do
    begin
    TParticleGroup(ParticleGroups[i]).InitialPosition := Vector3D(Vector(TParticleGroup(ParticleGroups[i]).OriginalPosition, 1.0) * CalculatedMatrix);
    TParticleGroup(ParticleGroups[i]).PositionVariance := Vector3D(Vector(TParticleGroup(ParticleGroups[i]).OriginalVariance, 0.0) * CalculatedMatrix);
    TParticleGroup(ParticleGroups[i]).InitialVelocity := Vector3D(Vector(TParticleGroup(ParticleGroups[i]).OriginalVelocity, 0.0) * CalculatedMatrix);
    TParticleGroup(ParticleGroups[i]).VelocityVariance := Vector3D(Vector(TParticleGroup(ParticleGroups[i]).OriginalVelocityVariance, 0.0) * CalculatedMatrix);
    end;
  for I := 0 to high(SoundSources) do
    SoundSources[I].ApplyMatrix(CalculatedMatrix);
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
      if VecLengthNoRoot(CalculatedVertexPosition - RelativeMeshOffset) > 0.001 then
        begin
        Vertices[i].Position := CalculatedVertexPosition - RelativeMeshOffset;
        Vertices[i].Changed := True;
        Changed := True;
        end;
      end;
end;

procedure TGeoMesh.Register;
var
  i: Integer;
begin
  EventManager.CallEvent('TGeoObject.AddedMesh', ParentObject, self);
  for i := 0 to high(LightSources) do
    LightSources[i].Register;
  for i := 0 to high(ParticleGroups) do
    TParticleGroup(ParticleGroups[i]).Register;
  for i := 0 to high(SoundSources) do
    SoundSources[i].Play;
end;

procedure TGeoMesh.SetIO(Script: TScript);
const
  SIZE: Integer = 2 * SizeOf(Single) + SizeOf(TMatrix4D);
var
  Mat: SInt;
begin
  Script.SetIO(@Self.MinDistance, SIZE, true);
  Mat := Material.MaterialID;
  Script.SetIO(@Mat, SizeOf(SInt), false);
end;

class procedure TGeoMesh.RegisterStruct;
begin
  ModuleManager.ModScriptManager.SetDataStructure('Mesh',
   'float minDist' + #10 +
   'float maxDist' + #10 +
   'mat4 matrix' + #10 +
   'int material');
end;

constructor TGeoMesh.Create;
begin
  MeshID := -1;
  ParentObject := nil;
  Parent := nil;
  Name := '';
  Changed := true;
  MinDistance := -10000;
  MaxDistance := 10000;
  Matrix := Identity4D;
  CalculatedMatrix := Identity4D;
  Bone := nil;
  Material := nil;
end;

destructor TGeoMesh.Free;
var
  i: Integer;
begin
  SetLength(Faces, 0);
  SetLength(Vertices, 0);
  SetLength(TextureVertices, 0);
  for i := 0 to high(LightSources) do
    LightSources[i].Free;
  for i := 0 to high(ParticleGroups) do
    TParticleGroup(ParticleGroups[i]).Free;
  for i := 0 to high(SoundSources) do
    SoundSources[i].Free;
  EventManager.CallEvent('TGeoObject.DeletedMesh', ParentObject, Self);
end;




function TGeoObject.AddArmature: TArmature;
begin
  SetLength(Armatures, length(Armatures) + 1);
  Armatures[high(Armatures)] := TArmature.Create;
  Result := Armatures[high(Armatures)];
  Result.ParentObject := Self;
  Result.ArmatureID := high(Armatures);
end;

function TGeoObject.AddMesh: TGeoMesh;
begin
  SetLength(Meshes, length(Meshes) + 1);
  Meshes[high(Meshes)] := TGeoMesh.Create;
  Meshes[high(Meshes)].MeshID := high(Meshes);
  Meshes[high(Meshes)].ParentObject := Self;
  Result := Meshes[high(Meshes)];
end;

function TGeoObject.AddMaterial: TMaterial;
begin
  SetLength(Materials, length(Materials) + 1);
  Materials[high(Materials)] := TMaterial.Create;
  Materials[high(Materials)].MaterialID := high(Materials);
  Result := Materials[high(Materials)];
end;

function TGeoObject.AddMaterial(A: TMaterial): TMaterial;
begin
  SetLength(Materials, length(Materials) + 1);
  Materials[high(Materials)] := A;
  Materials[high(Materials)].MaterialID := high(Materials);
  Result := Materials[high(Materials)];
end;

function TGeoObject.Duplicate: TGeoObject;
var
  i: Integer;
begin
  Result := TGeoObject.Create;

  Result.Mirror := Mirror;

  if Script <> nil then
    Result.Script := Script.Code.CreateInstance
  else
    Result.Script := nil;

  setLength(Result.Materials, length(Materials));
  for i := 0 to high(Materials) do
    Result.Materials[i] := Materials[i].Duplicate;

  setLength(Result.Armatures, length(Armatures));
  for i := 0 to high(Armatures) do
    Result.Armatures[i] := Armatures[i].Duplicate(Result);

  setLength(Result.Meshes, length(Meshes));
  for i := 0 to high(Meshes) do
    Result.Meshes[i] := Meshes[i].Duplicate(Result);
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
    Armatures[i].UpdateMatrix;
end;

procedure TGeoObject.Register;
var
  i: Integer;
begin
  EventManager.CallEvent('TGeoObject.Created', Self, nil);
  for i := 0 to high(Meshes) do
    Meshes[i].Register;
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

procedure TGeoObject.SetUnchanged;
var
  i: Integer;
begin
  for i := 0 to high(Meshes) do
    Meshes[i].Changed := False;
end;

procedure TGeoObject.UpdateFaceVertexAssociationForVertexNormalCalculation;
var
  i: Integer;
begin
  for i := 0 to high(Meshes) do
    Meshes[i].UpdateFaceVertexAssociationForVertexNormalCalculation;
end;

function TGeoObject.GetBoneByName(Armature, Bone: String): TBone;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(Armatures) do
    if Armatures[i].Name = Armature then
      Result := Armatures[i].GetBoneByName(Bone);
end;

function TGeoObject.GetMeshByName(Mesh: String): TGeoMesh;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(Meshes) do
    if Meshes[i].Name = Mesh then
      Result := Meshes[i];
end;
procedure TGeoObject.ExecuteScript;
begin
  if Script <> nil then
    begin
    SetIO;
    Script.Execute;
    FirstRun := False;
    end;
end;

procedure TGeoObject.SetIO;
var
  i, j, k: SInt;
begin
  if FirstRun then
    begin
    Counts[0] := Length(Meshes);
    Counts[1] := Length(Armatures);
    Counts[2] := Length(Materials);
    Counts[3] := 0;
    Counts[4] := 0;
    Counts[5] := 0;

    for i := 0 to high(Armatures) do
      inc(Counts[3], length(Armatures[i].Bones));

    for i := 0 to high(Meshes) do
      begin
      inc(Counts[4], length(Meshes[i].LightSources));
      inc(Counts[5], length(Meshes[i].ParticleGroups));
      end;

    Offsets[0] := ModuleManager.ModScriptManager.DataStructureSize('Object');
    Offsets[1] := Offsets[0] + Counts[0] * ModuleManager.ModScriptManager.DataStructureSize('Mesh');
    Offsets[2] := Offsets[1] + Counts[1] * ModuleManager.ModScriptManager.DataStructureSize('Armature');
    Offsets[3] := Offsets[2] + Counts[2] * ModuleManager.ModScriptManager.DataStructureSize('Material');
    Offsets[4] := Offsets[3] + Counts[3] * ModuleManager.ModScriptManager.DataStructureSize('Bone');
    Offsets[5] := Offsets[4] + Counts[4] * ModuleManager.ModScriptManager.DataStructureSize('Lamp');
    end;

  Script.SetIO(@FPSDisplay.ms, SizeOf(Single), False);
  Script.SetIO(@Matrix, SizeOf(TMatrix4D), True);
  Script.SetIO(@Counts[0], 6 * SizeOf(PtrUInt), False);
  Script.SetIO(@Offsets[0], 6 * SizeOf(PtrUInt), False);

  for i := 0 to high(Meshes) do
    Meshes[i].SetIO(Script);

  for i := 0 to high(Armatures) do
    Armatures[i].SetIO(Script);

  for i := 0 to high(Materials) do
    Materials[i].SetIO(Script);

  for i := 0 to high(Armatures) do
    for j := 0 to high(Armatures[i].Bones) do
      Armatures[i].Bones[j].SetIO(Script);

  for i := 0 to high(Meshes) do
    for j := 0 to high(Meshes[i].LightSources) do
      Meshes[i].LightSources[j].SetIO(Script);

//   for i := 0 to high(Meshes) do
//     for j := 0 to high(Meshes[i].ParticleGroups) do
//       Meshes[i].ParticleGroups[j].SetIO(Script);

  

  if FirstRun then
    begin
    for i := 0 to high(Materials) do
      Script.SetGlobal(Materials[i].Name, @i, SizeOf(Sint));

    for i := 0 to high(Meshes) do
      Script.SetGlobal(Meshes[i].Name, @i, SizeOf(Sint));

    k := 0;
    for i := 0 to high(Meshes) do
      for j := 0 to high(Meshes[i].LightSources) do
        begin
        Script.SetGlobal(Meshes[i].LightSources[j].Name, @k, SizeOf(Sint));
        inc(k);
        end;

    k := 0;
    for i := 0 to high(Meshes) do
      for j := 0 to high(Meshes[i].ParticleGroups) do
        begin
        Script.SetGlobal(TParticleGroup(Meshes[i].ParticleGroups[j]).Name, @k, SizeOf(Sint));
        inc(k);
        end;

    for i := 0 to high(Armatures) do
      Script.SetGlobal(Armatures[i].Name, @i, SizeOf(Sint));

    k := 0;
    for i := 0 to high(Armatures) do
      for j := 0 to high(Armatures[i].Bones) do
        begin
        Script.SetGlobal(Armatures[i].Bones[j].Name, @k, SizeOf(Sint));
        inc(k);
        end;
    end;
end;

function TGeoObject.GetMaterialByName(Mat: String): TMaterial;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to high(Materials) do
    if Materials[I].Name = Mat then
      exit(Materials[I]);
end;

class procedure TGeoObject.RegisterStruct;
begin
  ModuleManager.ModScriptManager.SetDataStructure('Object',
   'float ms' + #10 +
   'mat4 matrix' + #10 +
   'int meshCount' + #10 +
   'int armatureCount' + #10 +
   'int materialCount' + #10 +
   'int boneCount' + #10 +
   'int lampCount' + #10 +
   'int particleCount' + #10 +
   'int firstMeshOffset' + #10 + 
   'int firstArmatureOffset' + #10 + 
   'int firstMaterialOffset' + #10 + 
   'int firstBoneOffset' + #10 + 
   'int firstLampOffset' + #10 + 
   'int firstParticleOffset');
end;

constructor TGeoObject.Create;
begin
  Mirror := Vector(1, 1, 1);
  Matrix := Identity4D;
  Script := nil;
  FirstRun := True;
  ObjectID := ObjectCount;
  inc(ObjectCount);
end;

destructor TGeoObject.Free;
var
  i: Integer;
begin
  if Script <> nil then
    Script.Free;
  for i := 0 to high(Meshes) do
    Meshes[i].Free;
  for i := 0 to high(Materials) do
    Materials[i].Free;
  for i := 0 to high(Armatures) do
    Armatures[i].Free;
  EventManager.CallEvent('TGeoObject.Deleted', Self, nil);
end;


end.