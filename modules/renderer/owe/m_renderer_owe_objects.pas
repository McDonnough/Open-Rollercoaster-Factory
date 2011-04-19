unit m_renderer_owe_objects;

interface

uses
  SysUtils, Classes, DGLOpenGL, math, u_math, u_vectors, u_scene, u_geometry, m_renderer_owe_frustum, m_renderer_owe_classes, m_shdmng_class,
  u_ase, m_renderer_owe_renderpass, m_texmng_class, m_renderer_owe_cubemaps;

type
  TManagedObject = class;

  TManagedMesh = class
    GeoMesh: TGeoMesh;
    VBO: TObjectVBO;
    Transparent: Boolean;
    Visible: Boolean;
    Reflection: TCubeMap;
    ReflectionFramesToGo: Integer;
    nFrame: Integer;
    ParentObject: TManagedObject;
    end;

  TManagedObject = class
    GeoObject: TGeoObject;
    Meshes: Array of TManagedMesh;
    end;

  TMeshDistanceAssoc = record
    Mesh: TManagedMesh;
    Distance: Single;
    end;

  TRObjects = class(TThread)
    protected
      fManagedObjects: Array of TManagedObject;
      fOpaqueShadowShader, fTransparentShadowShader: TShader;
      fOpaqueLightShadowShader, fTransparentLightShadowShader: TShader;
      fOpaqueShader, fTransparentShader: TShader;
      fTransparentMaterialShader: TShader;
      fLastGeoObject: TGeoObject;
      fLastManagedObject: Integer;
      fTest: TGeoObject;
      fReflectionPass: TRenderPass;
      fCurrentShader: TShader;
      fCurrentMaterialCount: Integer;
      fExcludedMeshObject: TManagedObject;
      fExcludedMesh: TManagedMesh;
      fCanWork, fWorking: Boolean;
      fTransparentMeshOrder: Array of TMeshDistanceAssoc;
    public
      CurrentGBuffer: TFBO;
      MinY, MaxY: Single;
      ShadowMode, MaterialMode, LightShadowMode: Boolean;
      property Working: Boolean read fWorking write fCanWork;
      property OpaqueShader: TShader read fOpaqueShader;
      property OpaqueShadowShader: TShader read fOpaqueShadowShader;
      property OpaqueLightShadowShader: TShader read fOpaqueLightShadowShader;
      property TransparentShader: TShader read fTransparentShader;
      property TransparentMaterialShader: TShader read fTransparentMaterialShader;
      property TransparentShadowShader: TShader read fTransparentShadowShader;
      property TransparentLightShadowShader: TShader read fTransparentLightShadowShader;
      procedure Execute; override;
      procedure Sync;
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
      procedure UpdateObjects;
      procedure QuickSortTransparentMeshes;
      function CalculateLODDistance(D: Single): Single;
      constructor Create;
      procedure Free;
    end;

implementation

uses
  u_events, m_varlist;

function TRObjects.CalculateLODDistance(D: Single): Single;
begin
  Result := D * ModuleManager.ModRenderer.CurrentLODDistanceFactor + ModuleManager.ModRenderer.CurrentLODDistanceOffset;
end;

procedure TRObjects.AddObject(Event: String; Data, Result: Pointer);
begin
  SetLength(fManagedObjects, length(fManagedObjects) + 1);
  fManagedObjects[high(fManagedObjects)] := TManagedObject.Create;
  fManagedObjects[high(fManagedObjects)].GeoObject := TGeoObject(Data);
  SetLength(fManagedObjects[high(fManagedObjects)].Meshes, 0);
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
  fManagedObjects[fLastManagedObject].Free;
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
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)] := TManagedMesh.Create;
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].GeoMesh := TGeoMesh(Result);
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].VBO := TObjectVBO.Create(TGeoMesh(Result));
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].Transparent := TGeoMesh(Result).Material.Transparent;
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].ReflectionFramesToGo := Round(Random * ModuleManager.ModRenderer.ReflectionUpdateInterval);
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].Reflection := nil;
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].ParentObject := fManagedObjects[fLastManagedObject];
  Sync;
  SetLength(fTransparentMeshOrder, length(fTransparentMeshOrder) + 1);
  fTransparentMeshOrder[high(fTransparentMeshOrder)].Mesh := fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)];
  fTransparentMeshOrder[high(fTransparentMeshOrder)].Distance := 0;
end;

procedure TRObjects.DeleteMesh(Event: String; Data, Result: Pointer);
var
  i, mesh: Integer;
begin
  mesh := -1;
  if fManagedObjects[fLastManagedObject].GeoObject <> TGeoObject(Data) then
    for i := 0 to high(fManagedObjects) do
      if fManagedObjects[i].GeoObject = TGeoObject(Data) then
        fLastManagedObject := i;
  for i := 0 to high(fManagedObjects[fLastManagedObject].Meshes) do
    if fManagedObjects[fLastManagedObject].Meshes[i].GeoMesh = TGeoMesh(Result) then
      mesh := i;
  if mesh > -1 then
    begin
    with fManagedObjects[fLastManagedObject].Meshes[mesh] do
      begin
      VBO.Free;
      if Reflection <> nil then
        Reflection.Free;
      end;
    Sync;
    for i := 0 to high(fTransparentMeshOrder) do
      if fTransparentMeshOrder[i].Mesh = fManagedObjects[fLastManagedObject].Meshes[mesh] then
        begin
        fTransparentMeshOrder[i] := fTransparentMeshOrder[high(fTransparentMeshOrder)];
        SetLength(fTransparentMeshOrder, length(fTransparentMeshOrder) - 1);
        break;
        end;
    fManagedObjects[fLastManagedObject].Meshes[mesh].Free;
    fManagedObjects[fLastManagedObject].Meshes[mesh] := fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)];
    SetLength(fManagedObjects[fLastManagedObject].Meshes, length(fManagedObjects[fLastManagedObject].Meshes) - 1);
    end;
end;

procedure TRObjects.BindMaterial(Material: TMaterial);
var
  Spec: TVector4D;
begin
  with Material do
    begin
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
    Spec := Vector(Specularity, Reflectivity, 0, 0);
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
  if MaterialMode then
    begin
    fCurrentShader.UniformF('FogColor', ModuleManager.ModRenderer.FogColor);
    fCurrentShader.UniformF('FogStrength', ModuleManager.ModRenderer.FogStrength);
    fCurrentShader.UniformF('WaterHeight', ModuleManager.ModRenderer.RWater.CurrentHeight);
    fCurrentShader.UniformF('WaterRefractionMode', ModuleManager.ModRenderer.FogRefractMode);
    end;

  BindMaterial(Mesh.GeoMesh.Material);

  if not (MaterialMode or ShadowMode or LightShadowMode) then
    if ((Mesh.GeoMesh.Material.Reflectivity * Power(0.5, ModuleManager.ModRenderer.ReflectionRealtimeDistanceExponent * Max(0, VecLength(ModuleManager.ModCamera.ActiveCamera.Position - Vector3D(Vector(0, 0, 0, 1) * Mesh.GeoMesh.CalculatedMatrix)) - Mesh.VBO.Radius)) > ModuleManager.ModRenderer.ReflectionRealtimeMinimum) and (Mesh.Reflection <> nil)) and not (Mesh.GeoMesh.Material.OnlyEnvironmentMapHint) then
      Mesh.Reflection.Map.Textures[0].Bind(3)
    else
      ModuleManager.ModRenderer.EnvironmentMap.Map.Textures[0].Bind(3);

  MakeOGLCompatibleMatrix(Mesh.GeoMesh.CalculatedMatrix, @Matrix[0]);

  fCurrentShader.UniformMatrix4D('TransformMatrix', @Matrix[0]);
  fCurrentShader.UniformF('ViewPoint', ModuleManager.ModRenderer.ViewPoint.X, ModuleManager.ModRenderer.ViewPoint.Y, ModuleManager.ModRenderer.ViewPoint.Z);

  Mesh.VBO.Bind;
  Mesh.VBO.Render;
  Mesh.VBO.UnBind;

  fCurrentShader.Unbind;
end;

procedure TRObjects.RenderTransparent;
var
  i, j: Integer;
begin
  Sync;
  if MaterialMode then
    begin
    CurrentGBuffer.Textures[1].Bind(5);
    CurrentGBuffer.Textures[3].Bind(6);
    end;
  fCurrentMaterialCount := 1;
  for i := 0 to high(fTransparentMeshOrder) do
//   for i := 0 to high(fManagedObjects) do
//     for j := 0 to high(fManagedObjects[i].Meshes) do
      begin
      if ((fTransparentMeshOrder[i].Mesh.Visible) or (ShadowMode)) and ((fTransparentMeshOrder[i].Mesh.ParentObject <> fExcludedMeshObject) or (fTransparentMeshOrder[i].Mesh <> fExcludedMesh)) then
        if fTransparentMeshOrder[i].Mesh.Transparent then
          begin
          if LightShadowMode then
            fCurrentShader := fTransparentLightShadowShader
          else if ShadowMode then
            fCurrentShader := fTransparentShadowShader
          else if MaterialMode then
            fCurrentShader := fTransparentMaterialShader
          else
            begin
            fCurrentShader := fTransparentShader;
            fCurrentShader.UniformF('MaskOffset', Round(16 * Random) / 16, Round(16 * Random) / 16);
            end;
          fCurrentShader.UniformI('MaterialID', (fCurrentMaterialCount shr 16) and $FF, (fCurrentMaterialCount shr 8) and $FF, fCurrentMaterialCount and $FF);
          if not (ShadowMode or LightShadowMode) then
            begin
            // Render back sides first
            ModuleManager.ModRenderer.InvertFrontFace;
            Render(fTransparentMeshOrder[i].Mesh);
            ModuleManager.ModRenderer.InvertFrontFace;
            end;
          // Final render, front sides
          Render(fTransparentMeshOrder[i].Mesh);
          end;
      inc(fCurrentMaterialCount);
      end;
end;

procedure TRObjects.RenderOpaque;
var
  i, j: Integer;
begin
  MaterialMode := False;
  for i := 0 to high(fManagedObjects) do
    for j := 0 to high(fManagedObjects[i].Meshes) do
      if ((fManagedObjects[i].Meshes[j].Visible) or (ShadowMode)) and ((fManagedObjects[i] <> fExcludedMeshObject) or (fManagedObjects[i].Meshes[j] <> fExcludedMesh)) then
        if not fManagedObjects[i].Meshes[j].Transparent then
          begin
          if ShadowMode then
            fCurrentShader := fOpaqueShadowShader
          else if LightShadowMode then
            fCurrentShader := fOpaqueLightShadowShader
          else
            fCurrentShader := fOpaqueShader;
          Render(fManagedObjects[i].Meshes[j]);
          end;
end;

procedure TRObjects.CheckVisibility;
var
  i, j: Integer;
  Pos: TVector3D;
begin
  for i := 0 to high(fManagedObjects) do
    for j := 0 to high(fManagedObjects[i].Meshes) do
      begin
      Pos := Vector3D(Vector(0, 0, 0, 1) * fManagedObjects[i].Meshes[j].GeoMesh.CalculatedMatrix);
      fManagedObjects[i].Meshes[j].Visible := false;
      if VecLengthNoRoot(ModuleManager.ModRenderer.ViewPoint - Pos) - fManagedObjects[i].Meshes[j].VBO.Radius * fManagedObjects[i].Meshes[j].VBO.Radius < ModuleManager.ModRenderer.MaxRenderDistance * ModuleManager.ModRenderer.MaxRenderDistance then
        fManagedObjects[i].Meshes[j].Visible := ModuleManager.ModRenderer.Frustum.IsSphereWithin(Pos.X, Pos.Y, Pos.Z, fManagedObjects[i].Meshes[j].VBO.Radius);
      if (VecLength(ModuleManager.ModRenderer.ViewPoint - Pos) < CalculateLODDistance(fManagedObjects[i].Meshes[j].GeoMesh.MinDistance)) or (VecLength(ModuleManager.ModRenderer.ViewPoint - Pos) >= CalculateLODDistance(fManagedObjects[i].Meshes[j].GeoMesh.MaxDistance)) then
        fManagedObjects[i].Meshes[j].Visible := false;
      end;
end;

procedure TRObjects.RenderReflections;
var
  i, j: Integer;
  MeshPosition: TVector3D;
begin
  for i := 0 to high(fManagedObjects) do
    for j := 0 to high(fManagedObjects[i].Meshes) do
      begin
      MeshPosition := Vector3D(Vector(0, 0, 0, 1) * fManagedObjects[i].Meshes[j].GeoMesh.CalculatedMatrix);
      if fManagedObjects[i].Meshes[j].GeoMesh.Material.Reflectivity * Power(0.5, ModuleManager.ModRenderer.ReflectionRealtimeDistanceExponent * Max(0, VecLength(ModuleManager.ModCamera.ActiveCamera.Position - MeshPosition) - fManagedObjects[i].Meshes[j].VBO.Radius)) > ModuleManager.ModRenderer.ReflectionRealtimeMinimum then
        begin
        if fManagedObjects[i].Meshes[j].ReflectionFramesToGo > 0 then
          dec(fManagedObjects[i].Meshes[j].ReflectionFramesToGo)
        else
          begin
          if fManagedObjects[i].Meshes[j].Visible then
            begin
            if fManagedObjects[i].Meshes[j].Reflection = nil then
              fManagedObjects[i].Meshes[j].Reflection := TCubeMap.Create(ModuleManager.ModRenderer.ReflectionSize, ModuleManager.ModRenderer.ReflectionSize, GL_RGB16F_ARB);
            fExcludedMeshObject := fManagedObjects[i];
            fExcludedMesh := fManagedObjects[i].Meshes[j];
            ModuleManager.ModRenderer.ViewPoint := MeshPosition;
            fManagedObjects[i].Meshes[j].Reflection.Render(fReflectionPass, MeshPosition);
            fManagedObjects[i].Meshes[j].ReflectionFramesToGo := ModuleManager.ModRenderer.ReflectionUpdateInterval - 1;
            end;
          end;
        end
      else if fManagedObjects[i].Meshes[j].GeoMesh.Material.Reflectivity <= ModuleManager.ModRenderer.ReflectionRealtimeMinimum then
        if fManagedObjects[i].Meshes[j].Reflection <> nil then
          begin
          fManagedObjects[i].Meshes[j].Reflection.Free;
          fManagedObjects[i].Meshes[j].Reflection := nil;
          end;
      end;
  fExcludedMeshObject := nil;
  fExcludedMesh := nil;
end;

procedure TRObjects.UpdateObjects;
begin
//   fTest.Armatures[0].Bones[0].Matrix := fTest.Armatures[0].Bones[0].Matrix * RotationMatrix(1, Vector(0, 1, 0));
//   fTest.UpdateArmatures;
//   fTest.UpdateMatrix;
//   fTest.UpdateVertexPositions;
//   fTest.RecalcFaceNormals;
//   fTest.RecalcVertexNormals;
end;

constructor TRObjects.Create;
begin
  inherited Create(false);
  
  writeln('Hint: Initializing object renderer');

  MaterialMode := False;
  ShadowMode := False;
  LightShadowMode := False;

  EventManager.AddCallback('TGeoObject.Created', @AddObject);
  EventManager.AddCallback('TGeoObject.Deleted', @DeleteObject);
  EventManager.AddCallback('TGeoObject.AddedMesh', @AddMesh);
  EventManager.AddCallback('TGeoObject.DeletedMesh', @DeleteMesh);

  fLastManagedObject := -1;

  fOpaqueShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadow.vs', 'orcf-world-engine/scene/objects/shadow-opaque.fs');

  fTransparentShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadow.vs', 'orcf-world-engine/scene/objects/shadow-transparent.fs');
  fTransparentShadowShader.UniformI('Texture', 0);

  fOpaqueLightShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadowLight.vs', 'orcf-world-engine/scene/objects/shadowLight-opaque.fs');

  fTransparentLightShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadowLight.vs', 'orcf-world-engine/scene/objects/shadowLight-transparent.fs');
  fTransparentLightShadowShader.UniformI('Texture', 0);

  fOpaqueShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/scene/objects/normal-opaque.fs');
  fOpaqueShader.UniformI('Texture', 0);
  fOpaqueShader.UniformI('NormalMap', 1);
  fOpaqueShader.UniformI('ReflectionMap', 3);

  fTransparentShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/scene/objects/normal-transparent.fs');
  fTransparentShader.UniformI('Texture', 0);
  fTransparentShader.UniformI('NormalMap', 1);
  fTransparentShader.UniformI('ReflectionMap', 3);
  fTransparentShader.UniformI('TransparencyMask', 7);
  fTransparentShader.UniformF('MaskSize', ModuleManager.ModRenderer.TransparencyMask.Width, ModuleManager.ModRenderer.TransparencyMask.Height);

  fTransparentMaterialShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/scene/objects/normal-material.fs');
  fTransparentMaterialShader.UniformI('Texture', 0);
  fTransparentMaterialShader.UniformI('NormalMap', 5);
  fTransparentMaterialShader.UniformI('ReflectionMap', 3);
  fTransparentMaterialShader.UniformI('MaterialMap', 6);
  fTransparentMaterialShader.UniformI('LightTexture', 7);

  fReflectionPass := TRenderPass.Create(ModuleManager.ModRenderer.ReflectionSize, ModuleManager.ModRenderer.ReflectionSize);
  fReflectionPass.RenderTerrain := ModuleManager.ModRenderer.ReflectionRenderTerrain;
  fReflectionPass.RenderObjects := ModuleManager.ModRenderer.ReflectionRenderObjects;
  fReflectionPass.RenderParticles := ModuleManager.ModRenderer.ReflectionRenderParticles;
  fReflectionPass.RenderAutoplants := ModuleManager.ModRenderer.ReflectionRenderAutoplants;

  fExcludedMeshObject := nil;
  fExcludedMesh := nil;
  CurrentGBuffer := ModuleManager.ModRenderer.GBuffer;

  fTest := ASEFileToMeshArray(LoadASEFile('scenery/untitled.ase'));
  with fTest.AddArmature do
    begin
    with AddBone do
      begin
      SourcePosition := Vector(-1, -5, 0);
      DestinationPosition := Vector(-1, -6, 0);
      Matrix := TranslationMatrix(Vector(2, 10, 4));
      end;
    with AddBone do
      begin
      SourcePosition := Vector(0, 0, 0);
      DestinationPosition := Vector(0, 1, 0);
      Matrix := TranslationMatrix(Vector(0, 4, 0));
      end;
    end;
  fTest.Meshes[0].AddBone(fTest.Armatures[0].Bones[1]);
  fTest.Meshes[0].MinDistance := 20;
  fTest.Meshes[1].AddBone(fTest.Armatures[0].Bones[0]);
  fTest.Meshes[1].MaxDistance := 20;
  fTest.Materials[3].Reflectivity := 0.8;
  fTest.Materials[0].Reflectivity := 0.8;
  fTest.Materials[1].Reflectivity := 0.7;
  fTest.Materials[2].Reflectivity := 0.6;
  fTest.Materials[2].BumpMap := TTexture.Create;
  fTest.Materials[2].BumpMap.FromFile('scenery/testbump.tga');
  fTest.Materials[2].Emission := Vector(1, 1, 1, 5);
  fTest.Matrix := TranslationMatrix(Vector(160, 70, 160));
  fTest.UpdateArmatures;
  fTest.UpdateVertexPositions;
  fTest.UpdateMatrix;
  fTest.RecalcFaceNormals;
  fTest.RecalcVertexNormals;
  fTest.Register;
end;

procedure TRObjects.QuickSortTransparentMeshes;
  procedure DoQuicksort(First, Last: Integer);
    procedure Swap(X, Y: Integer);
    var
      Z: TMeshDistanceAssoc;
    begin
      Z := fTransparentMeshOrder[X];
      fTransparentMeshOrder[X] := fTransparentMeshOrder[Y];
      fTransparentMeshOrder[Y] := Z;
    end;
  var
    PivotID, i, j: Integer;
    Pivot: Single;
  begin
    if First >= Last then
      exit;
    PivotID := (First + Last) div 2;
    Pivot := fTransparentMeshOrder[PivotID].Distance;

    Swap(PivotID, Last);

    i := First;
    j := Last - 1;

    repeat
      while (fTransparentMeshOrder[i].Distance >= Pivot) and (i < Last) do
        inc(i);

      while (fTransparentMeshOrder[j].Distance <= Pivot) and (j > First) do
        dec(j);

      if i < j then
        Swap(i, j);
    until
      i >= j;
    if fTransparentMeshOrder[i].Distance < Pivot then
      Swap(i, Last);

    DoQuicksort(First, i - 1);
    DoQuicksort(i + 1, Last);
  end;
begin
  DoQuicksort(0, high(fTransparentMeshOrder));
end;

procedure TRObjects.Execute;
var
  i: Integer;
begin
  fWorking := False;
  fCanWork := False;

  while not Terminated do
    begin
    if fCanWork then
      begin
      fWorking := True;
      fCanWork := False;

      for i := 0 to high(fTransparentMeshOrder) do
        fTransparentMeshOrder[i].Distance := VecLengthNoRoot(ModuleManager.ModRenderer.ViewPoint - Vector3D(Vector(0, 0, 0, 1) * fTransparentMeshOrder[i].Mesh.GeoMesh.CalculatedMatrix));

      QuickSortTransparentMeshes;

      fWorking := False;
      end
    else
      sleep(1);
    end;

  writeln('Hint: Terminated object renderer thread');
end;

procedure TRObjects.Sync;
begin
  while Working do
    sleep(1);
end;

procedure TRObjects.Free;
begin
  Terminate;
  fTest.Free;
  fReflectionPass.Free;
  fOpaqueLightShadowShader.Free;
  fOpaqueShader.Free;
  fOpaqueShadowShader.Free;
  fTransparentLightShadowShader.Free;
  fTransparentMaterialShader.Free;
  fTransparentShader.Free;
  fTransparentShadowShader.Free;
  EventManager.RemoveCallback(@AddObject);
  EventManager.RemoveCallback(@DeleteObject);
  EventManager.RemoveCallback(@AddMesh);
  EventManager.RemoveCallback(@DeleteMesh);
  Sync;
  inherited Free;
end;


end.