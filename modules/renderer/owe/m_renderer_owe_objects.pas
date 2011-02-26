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
    Visible: Boolean;
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
      fCurrentShader: TShader;
      fCurrentMaterialCount: Integer;
    public
      MinY, MaxY: Single;
      ShadowMode, MaterialMode: Boolean;
      property OpaqueShader: TShader read fOpaqueShader;
      property OpaqueShadowShader: TShader read fOpaqueShadowShader;
      property TransparentShader: TShader read fTransparentShader;
      property TransparentMaterialShader: TShader read fTransparentMaterialShader;
      property TransparentShadowShader: TShader read fTransparentShadowShader;
      procedure AddObject(Event: String; Data, Result: Pointer);
      procedure DeleteObject(Event: String; Data, Result: Pointer);
      procedure AddMesh(Event: String; Data, Result: Pointer);
      procedure DeleteMesh(Event: String; Data, Result: Pointer);
      procedure CheckVisibility;
      procedure BindMaterial(Material: TMaterial);
      procedure Render(Mesh: TManagedMesh);
      procedure RenderReflections;
      procedure RenderOpaque;
      procedure RenderTransparent;
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
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].Transparent := TGeoMesh(Result).Material.Transparent;
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

procedure TRObjects.BindMaterial(Material: TMaterial);
var
  Spec: TVector4D;
begin
  with Material do
    begin
    if LightFactorMap <> nil then
      begin
      LightFactorMap.Bind(2);
      fCurrentShader.UniformI('HasLightFactorMap', 1);
      end
    else
      begin
      ModuleManager.ModTexMng.ActivateTexUnit(2);
      ModuleManager.ModTexMng.BindTexture(-1);
      fCurrentShader.UniformI('HasLightFactorMap', 0);
      end;
    if BumpMap <> nil then
      begin
      BumpMap.Bind(1);
      fCurrentShader.UniformI('HasNormalMap', 1);
      end
    else
      begin
      ModuleManager.ModTexMng.ActivateTexUnit(1);
      ModuleManager.ModTexMng.BindTexture(-1);
      fCurrentShader.UniformI('HasNormalMap', 0);
      end;
    if Texture <> nil then
      begin
      Texture.Bind(0);
      fCurrentShader.UniformI('HasTexture', 1);
      end
    else
      begin
      ModuleManager.ModTexMng.ActivateTexUnit(0);
      ModuleManager.ModTexMng.BindTexture(-1);
      fCurrentShader.UniformI('HasTexture', 0);
      end;
    Spec := Vector(Specularity, 0, 0, 0);
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, @Color.X);
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, @Emission.X);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, @Spec.X);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, @Hardness);
    end;
end;

procedure TRObjects.Render(Mesh: TManagedMesh);
var
  Matrix: Array[0..15] of Single;
begin
  fCurrentShader.Bind;
  if ShadowMode then
    begin
    fCurrentShader.UniformF('ShadowSize', ModuleManager.ModRenderer.ShadowSize);
    fCurrentShader.UniformF('ShadowOffset', ModuleManager.ModRenderer.ShadowOffset.X, ModuleManager.ModRenderer.ShadowOffset.Y, ModuleManager.ModRenderer.ShadowOffset.Z);
    end;

  BindMaterial(Mesh.GeoMesh.Material);

  MakeOGLCompatibleMatrix(Mesh.GeoMesh.CalculatedMatrix, @Matrix[0]);

  fCurrentShader.UniformMatrix4D('TransformMatrix', @Matrix[0]);

  Mesh.VBO.Bind;
  Mesh.VBO.Render;
  Mesh.VBO.UnBind;

  fCurrentShader.Unbind;
end;

procedure TRObjects.RenderTransparent;
var
  i, j: Integer;
begin
  fCurrentMaterialCount := 1;
  if MaterialMode then
    ModuleManager.ModRenderer.GBuffer.Textures[3].Bind(6);
  for i := 0 to high(fManagedObjects) do
    for j := 0 to high(fManagedObjects[i].Meshes) do
      if fManagedObjects[i].Meshes[j].Transparent then
        begin
        if ShadowMode then
          fCurrentShader := fTransparentShadowShader
        else if MaterialMode then
          fCurrentShader := fTransparentMaterialShader
        else
          begin
          fCurrentShader := fTransparentShader;
          fCurrentShader.UniformF('MaskOffset', Round(16 * Random) / 16, Round(16 * Random) / 16);
          end;
        fCurrentShader.UniformI('MaterialID', (fCurrentMaterialCount shr 16) and $FF, (fCurrentMaterialCount shr 8) and $FF, fCurrentMaterialCount and $FF);
        Render(fManagedObjects[i].Meshes[j]);
        inc(fCurrentMaterialCount);
        end;
end;

procedure TRObjects.RenderOpaque;
var
  i, j: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    for j := 0 to high(fManagedObjects[i].Meshes) do
      if not fManagedObjects[i].Meshes[j].Transparent then
        begin
        if not ShadowMode then
          fCurrentShader := fOpaqueShader
        else
          fCurrentShader := fOpaqueShadowShader;
        Render(fManagedObjects[i].Meshes[j]);
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


  fOpaqueShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadow.vs', 'orcf-world-engine/scene/objects/shadow-opaque.fs');

  fTransparentShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadow.vs', 'orcf-world-engine/scene/objects/shadow-transparent.fs');
  fTransparentShadowShader.UniformI('Texture', 0);

  fOpaqueShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/scene/objects/normal-opaque.fs');
  fOpaqueShader.UniformI('Texture', 0);
  fOpaqueShader.UniformI('NormalMap', 1);
  fOpaqueShader.UniformI('LightFactorMap', 2);

  fTransparentShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/scene/objects/normal-transparent.fs');
  fTransparentShader.UniformI('Texture', 0);
  fTransparentShader.UniformI('NormalMap', 1);
  fTransparentShader.UniformI('LightFactorMap', 2);
  fTransparentShader.UniformI('TransparencyMask', 7);
  fTransparentShader.UniformF('MaskSize', ModuleManager.ModRenderer.TransparencyMask.Width, ModuleManager.ModRenderer.TransparencyMask.Height);

  fTransparentMaterialShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/scene/objects/normal-material.fs');
  fTransparentMaterialShader.UniformI('Texture', 0);
  fTransparentMaterialShader.UniformI('MaterialMap', 6);
  fTransparentMaterialShader.UniformI('LightTexture', 7);

  fTest := ASEFileToMeshArray(LoadASEFile('scenery/untitled.ase'));
  with fTest.AddArmature do
    begin
    with AddBone do
      begin
      SourcePosition := Vector(0, -5, 0);
      DestinationPosition := Vector(0, -6, 0);
      end;
    end;
  fTest.Meshes[1].AddBoneToAll(fTest.Armatures[0].Bones[0]);
  fTest.Armatures[0].Bones[0].Matrix := TranslationMatrix(Vector(2, 10, 4));
  fTest.UpdateArmatures;
  fTest.UpdateVertexPositions;
  fTest.Meshes[1].RecalcFaceNormals;
  fTest.Meshes[1].RecalcVertexNormals;
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