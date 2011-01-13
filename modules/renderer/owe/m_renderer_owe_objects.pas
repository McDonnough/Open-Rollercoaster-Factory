unit m_renderer_owe_objects;

interface

uses
  SysUtils, Classes, DGLOpenGL, math, u_math, u_vectors, u_scene, u_geometry, m_renderer_owe_frustum, m_renderer_owe_classes, m_shdmng_class, u_ase,
  m_renderer_owe_renderpass, m_texmng_class;

type
  TManagedMesh = record
    GeoMesh: TGeoMesh;
    VBO: TObjectVBO;
    Transparent: Boolean;
    SphereRadius: Single;
    Reflection: TFBO;
    nFrame: Integer;
    end;

  TManagedObject = record
    GeoObject: TGeoObject;
    Meshes: Array of TManagedMesh;
    end;

  TRObjects = class
    protected
      fManagedObjects: Array of TManagedObject;
      fOpaqueShadowShader, fTransparentShadowShader: TShader;
      fOpaqueShader, fTransparentShader: TShader;
      fTransparentMaterialShader: TShader;
      fLastGeoObject: TGeoObject;
      fLastManagedObject: Integer;
      fTest: TGeoObject;
      fReflectionPass: TRenderPass;
    public
      MinY, MaxY: Single;
      ShadowMode: Boolean;
      property OpaqueShader: TShader read fOpaqueShader;
      property OpaqueShadowShader: TShader read fOpaqueShadowShader;
      property TransparentShader: TShader read fTransparentShader;
      property TransparentMaterialShader: TShader read fTransparentMaterialShader;
      property TransparentShadowShader: TShader read fTransparentShadowShader;
      procedure AddObject(Event: String; Data, Result: Pointer);
      procedure DeleteObject(Event: String; Data, Result: Pointer);
      procedure AddMesh(Event: String; Data, Result: Pointer);
      procedure DeleteMesh(Event: String; Data, Result: Pointer);
      procedure RenderTransparent;
      procedure CheckVisibility;
      procedure RenderReflections;
      procedure RenderOpaque;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_events, m_varlist;

procedure TRObjects.AddObject(Event: String; Data, Result: Pointer);
begin
  SetLength(fManagedObjects, length(fManagedObjects) + 1);
  fManagedObjects[high(fManagedObjects)].GeoObject := TGeoObject(Data);
  fLastManagedObject := high(fManagedObjects);
end;

procedure TRObjects.DeleteObject(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  if fManagedObjects[fLastManagedObject].GeoObject <> TGeoObject(Data) then
    for i := 0 to high(fManagedObjects) do
      if fManagedObjects[i].GeoObject = TGeoObject(Data) then
        fLastManagedObject := i;
  for i := 0 to high(fManagedObjects[fLastManagedObject].Meshes) do
    DeleteMesh('', fManagedObjects[fLastManagedObject].GeoObject, fManagedObjects[fLastManagedObject].Meshes[i].GeoMesh);
  fManagedObjects[fLastManagedObject] := fManagedObjects[high(fManagedObjects)];
  setLength(fManagedObjects, length(fManagedObjects) - 1);
  fLastManagedObject := Min(fLastManagedObject, high(fManagedObjects));
end;

procedure TRObjects.AddMesh(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  if fManagedObjects[fLastManagedObject].GeoObject <> TGeoObject(Data) then
    for i := 0 to high(fManagedObjects) do
      if fManagedObjects[i].GeoObject = TGeoObject(Data) then
        fLastManagedObject := i;
  setLength(fManagedObjects[fLastManagedObject].Meshes, length(fManagedObjects[fLastManagedObject].Meshes) + 1);
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].GeoMesh := TGeoMesh(Result);
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].VBO := TObjectVBO.Create(TGeoMesh(Result));
end;

procedure TRObjects.DeleteMesh(Event: String; Data, Result: Pointer);
var
  i, mesh: Integer;
begin
  if fManagedObjects[fLastManagedObject].GeoObject <> TGeoObject(Data) then
    for i := 0 to high(fManagedObjects) do
      if fManagedObjects[i].GeoObject = TGeoObject(Data) then
        fLastManagedObject := i;
  for i := 0 to high(fManagedObjects[fLastManagedObject].Meshes) do
    if fManagedObjects[fLastManagedObject].Meshes[i].GeoMesh = TGeoMesh(Result) then
      mesh := i;
  with fManagedObjects[fLastManagedObject].Meshes[mesh] do
    begin
    VBO.Free;
    if Reflection <> nil then
      Reflection.Free;
    end;
  fManagedObjects[fLastManagedObject].Meshes[mesh] := fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)];
  SetLength(fManagedObjects[fLastManagedObject].Meshes, length(fManagedObjects[fLastManagedObject].Meshes) - 1);
end;

procedure TRObjects.RenderTransparent;
var
  i, j: Integer;
  fCurrentShader: TShader;
begin
  for i := 0 to high(fManagedObjects) do
    for j := 0 to high(fManagedObjects[i].Meshes) do
      if fManagedObjects[i].Meshes[j].Transparent then
        begin
        end;
end;

procedure TRObjects.RenderOpaque;
var
  i, j: Integer;
  Matrix: Array[0..15] of Single;
  fMeshMatrix: TMatrix4D;
  fCurrentShader: TShader;
begin
  for i := 0 to high(fManagedObjects) do
    for j := 0 to high(fManagedObjects[i].Meshes) do
      if not fManagedObjects[i].Meshes[j].Transparent then
        begin
        if not ShadowMode then
          begin
          fCurrentShader := fOpaqueShader;
          fCurrentShader.Bind;
          end
        else
          begin
          fCurrentShader := fOpaqueShadowShader;
          fCurrentShader.Bind;
          end;

        end;
end;

procedure TRObjects.CheckVisibility;
begin

end;

procedure TRObjects.RenderReflections;
begin

end;

constructor TRObjects.Create;
begin
  writeln('Hint; Initializing object renderer');

  EventManager.AddCallback('TGeoObject.Created', @AddObject);
  EventManager.AddCallback('TGeoObject.Deleted', @DeleteObject);
  EventManager.AddCallback('TGeoObject.AddedMesh', @AddMesh);
  EventManager.AddCallback('TGeoObject.DeletedMesh', @DeleteMesh);

  fLastManagedObject := -1;

  fTest := ASEFileToMeshArray(LoadASEFile('scenery/untitled.ase'));
  fTest.Materials[0].Reflectivity := 0.8;
  fTest.Materials[1].Reflectivity := 0.2;
  fTest.Materials[2].Reflectivity := 0.2;
  fTest.Materials[2].BumpMap := TTexture.Create;
  fTest.Materials[2].BumpMap.FromFile('scenery/testbump.tga');
  fTest.Matrix := TranslationMatrix(Vector(160, 70, 160));
  fTest.UpdateMatrix;
  fTest.RecalcFaceNormals;
  fTest.RecalcVertexNormals;
  with fTest.AddArmature do
    begin
    with AddBone do
      begin
      SourcePosition := Vector(0, -5, 0);
      DestinationPosition := Vector(0, -6, 0);
      end;
    end;
  fTest.Meshes[1].AddBoneToAll(fTest.Armatures[0].Bones[0]);
  fTest.Register;
end;

destructor TRObjects.Free;
begin
  fTest.Free;
  EventManager.RemoveCallback(@AddObject);
  EventManager.RemoveCallback(@DeleteMesh);
  EventManager.RemoveCallback(@AddObject);
  EventManager.RemoveCallback(@DeleteMesh);
end;


end.