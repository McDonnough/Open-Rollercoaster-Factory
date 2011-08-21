unit m_renderer_owe_objects;

interface

uses
  SysUtils, Classes, DGLOpenGL, math, u_math, u_vectors, u_scene, u_geometry, m_renderer_owe_frustum, m_renderer_owe_classes, m_shdmng_class,
  u_ase, m_renderer_owe_renderpass, m_texmng_class, m_renderer_owe_cubemaps, u_particles;

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
    ManagedObject: TManagedObject;
    ParticleGroup: TParticleGroup;
    Distance: Single;
    end;

  TMeshClass = record
    InternalMeshName: String;
    VBO: TObjectVBO;
    Meshes: Array of TManagedMesh;
    end;

  TRObjects = class(TThread)
    protected
      fManagedObjects: Array of TManagedObject;
      fOpaqueShadowShader, fTransparentShadowShader: TShader;
      fOpaqueLightShadowShader, fTransparentLightShadowShader: TShader;
      fOpaqueShader, fTransparentShader: TShader;
      fTransparentMaterialShader: TShader;
      fSelectionShader: TShader;
      fLastGeoObject: TGeoObject;
      fLastManagedObject: Integer;
      fReflectionPass: TRenderPass;
      fCurrentShader: TShader;
      fCurrentMaterialCount: Integer;
      fExcludedMeshObject: TManagedObject;
      fExcludedMesh: TManagedMesh;
      fCanWork, fWorking: Boolean;
      fLastBoundReflectionMap, fLastBoundTexture, fLastBoundBumpmap: TTexture;
      fLastBoundVBO: TObjectVBO;
      fTransparentMeshOrder: Array of TMeshDistanceAssoc;
      fMeshClasses: Array of TMeshClass;
      fFirstMesh: Boolean;
      function getWorking: Boolean;
    public
      CurrentGBuffer: TFBO;
      MinY, MaxY: Single;
      ShadowMode, MaterialMode, LightShadowMode: Boolean;
      Uniforms: Array[0..7, 0..15] of GLUInt;
      Shaders: Array[0..7] of TShader;
      property CurrentMaterialCount: Integer read fCurrentMaterialCount;
      property Working: Boolean read getWorking write fCanWork;
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
      procedure AddParticleGroup(Event: String; Data, Result: Pointer);
      procedure DeleteParticleGroup(Event: String; Data, Result: Pointer);
      procedure CheckVisibility;
      procedure BindMaterial(Material: TMaterial);
      procedure Render(Mesh: TManagedMesh);
      procedure RenderReflections;
      procedure RenderSelectable;
      procedure RenderOpaque;
      procedure RenderTransparent;
      procedure QuickSortTransparentMeshes;
      function CalculateLODDistance(D: Single): Single;
      constructor Create;
      procedure Clear;
    end;

implementation

uses
  u_events, m_varlist, g_park;

const
  SHADER_OPAQUE = 0;
  SHADER_TRANSPARENT = 1;
  SHADER_TRANSPARENT_MATERIAL = 2;
  SHADER_SELECTION = 3;
  SHADER_OPAQUE_SHADOW = 4;
  SHADER_OPAQUE_SHADOW_LIGHT = 5;
  SHADER_TRANSPARENT_SHADOW = 6;
  SHADER_TRANSPARENT_SHADOW_LIGHT = 7;

  UNIFORM_ANY_HASNORMALMAP = 0;
  UNIFORM_ANY_HASTEXTURE = 1;
  UNIFORM_ANY_MEDIUMS = 2;
  UNIFORM_ANY_SHADOWSIZE = 3;
  UNIFORM_ANY_SHADOWOFFSET = 4;
  UNIFORM_ANY_FOGCOLOR = 5;
  UNIFORM_ANY_FOGSTRENGTH = 6;
  UNIFORM_ANY_WATERHEIGHT = 7;
  UNIFORM_ANY_WATERREFRACTIONMODE = 8;
  UNIFORM_ANY_TRANSFORMMATRIX = 9;
  UNIFORM_ANY_VIEWPOINT = 10;
  UNIFORM_ANY_SELECTIONMESHID = 11;
  UNIFORM_ANY_MIRROR = 12;
  UNIFORM_ANY_ALPHA = 13;
  UNIFORM_ANY_MASKOFFSET = 14;
  UNIFORM_ANY_MATERIALID = 15;

function TRObjects.getWorking: Boolean;
begin
  Result := fCanWork or fWorking;
end;

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
  fLastManagedObject := Max(fLastManagedObject, 0);
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
  i, FoundClass: Integer;
  FullMeshName: String;
begin
  fLastManagedObject := Max(fLastManagedObject, 0);
  if fManagedObjects[fLastManagedObject].GeoObject <> TGeoObject(Data) then
    for i := 0 to high(fManagedObjects) do
      if fManagedObjects[i].GeoObject = TGeoObject(Data) then
        fLastManagedObject := i;
  setLength(fManagedObjects[fLastManagedObject].Meshes, length(fManagedObjects[fLastManagedObject].Meshes) + 1);
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)] := TManagedMesh.Create;
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].GeoMesh := TGeoMesh(Result);
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].Transparent := TGeoMesh(Result).Material.Transparent;
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].ReflectionFramesToGo := Round(Random * ModuleManager.ModRenderer.ReflectionUpdateInterval);
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].Reflection := nil;
  fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].ParentObject := fManagedObjects[fLastManagedObject];
  if fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)].Transparent then
    begin
    Sync;
    SetLength(fTransparentMeshOrder, length(fTransparentMeshOrder) + 1);
    fTransparentMeshOrder[high(fTransparentMeshOrder)].Mesh := fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)];
    fTransparentMeshOrder[high(fTransparentMeshOrder)].ManagedObject := fManagedObjects[fLastManagedObject];
    fTransparentMeshOrder[high(fTransparentMeshOrder)].ParticleGroup := nil;
    fTransparentMeshOrder[high(fTransparentMeshOrder)].Distance := 0;
    end;
  FullMeshName := TGeoObject(Data).Name + #10 + TGeoMesh(Result).Name;
  FoundClass := -1;
  if TGeoMesh(Result).StaticMesh then
    for I := 0 to high(fMeshClasses) do
      if fMeshClasses[I].InternalMeshName = FullMeshName then
        begin
        FoundClass := I;
        break;
        end;
  if FoundClass = -1 then
    begin
    SetLength(fMeshClasses, length(fMeshClasses) + 1);
    fMeshClasses[high(fMeshClasses)].InternalMeshName := FullMeshName;
    fMeshClasses[high(fMeshClasses)].VBO := TObjectVBO.Create(TGeoMesh(Result));
    FoundClass := high(fMeshClasses);
    end;
  SetLength(fMeshClasses[FoundClass].Meshes, length(fMeshClasses[FoundClass].Meshes) + 1);
  fMeshClasses[FoundClass].Meshes[high(fMeshClasses[FoundClass].Meshes)] := fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)];
  fMeshClasses[FoundClass].Meshes[high(fMeshClasses[FoundClass].Meshes)].VBO := fMeshClasses[FoundClass].VBO;
end;

procedure TRObjects.AddParticleGroup(Event: String; Data, Result: Pointer);
begin
  Sync;
  SetLength(fTransparentMeshOrder, length(fTransparentMeshOrder) + 1);
  fTransparentMeshOrder[high(fTransparentMeshOrder)].Mesh := nil;
  fTransparentMeshOrder[high(fTransparentMeshOrder)].ManagedObject := nil;
  fTransparentMeshOrder[high(fTransparentMeshOrder)].ParticleGroup := TParticleGroup(Data);
  fTransparentMeshOrder[high(fTransparentMeshOrder)].Distance := 0;
end;

procedure TRObjects.DeleteParticleGroup(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  Sync;
  for i := 0 to high(fTransparentMeshOrder) do
    if (Pointer(fTransparentMeshOrder[i].ParticleGroup) = Data) and (Data <> nil) then
      begin
      fTransparentMeshOrder[i] := fTransparentMeshOrder[high(fTransparentMeshOrder)];
      SetLength(fTransparentMeshOrder, length(fTransparentMeshOrder) - 1);
      exit;
      end;
end;

procedure TRObjects.DeleteMesh(Event: String; Data, Result: Pointer);
var
  i, j, mesh: Integer;
  fMeshClass, fMeshInClass: Integer;
begin
  mesh := -1;
  fLastManagedObject := Max(fLastManagedObject, 0);
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
      if Reflection <> nil then
        Reflection.Free;
      end;
    Sync;
    for i := 0 to high(fTransparentMeshOrder) do
      if (fTransparentMeshOrder[i].Mesh = fManagedObjects[fLastManagedObject].Meshes[mesh]) and (fTransparentMeshOrder[i].ParticleGroup = nil) then
        begin
        fTransparentMeshOrder[i] := fTransparentMeshOrder[high(fTransparentMeshOrder)];
        SetLength(fTransparentMeshOrder, length(fTransparentMeshOrder) - 1);
        break;
        end;
    fMeshClass := -1;
    fMeshInClass := -1;
    for I := 0 to high(fMeshClasses) do
      begin
      for J := 0 to high(fMeshClasses[i].Meshes) do
        if fMeshClasses[I].Meshes[J] = fManagedObjects[fLastManagedObject].Meshes[mesh] then
          begin
          fMeshClass := I;
          fMeshInClass := J;
          break;
          end;
      if fMeshClass <> -1 then
        break;
      end;
    if not ((fMeshClass = -1) or (fMeshInClass = -1)) then
      begin
      fMeshClasses[fMeshClass].Meshes[fMeshInClass] := fMeshClasses[fMeshClass].Meshes[high(fMeshClasses[fMeshClass].Meshes)];
      SetLength(fMeshClasses[fMeshClass].Meshes, length(fMeshClasses[fMeshClass].Meshes) - 1);
      if length(fMeshClasses[fMeshClass].Meshes) = 0 then
        begin
        fMeshClasses[fMeshClass].VBO.Free;
        fMeshClasses[fMeshClass] := fMeshClasses[high(fMeshClasses)];
        Setlength(fMeshClasses, length(fMeshClasses) - 1);
        end;
      end;
    fManagedObjects[fLastManagedObject].Meshes[mesh].Free;
    fManagedObjects[fLastManagedObject].Meshes[mesh] := fManagedObjects[fLastManagedObject].Meshes[high(fManagedObjects[fLastManagedObject].Meshes)];
    SetLength(fManagedObjects[fLastManagedObject].Meshes, length(fManagedObjects[fLastManagedObject].Meshes) - 1);
    end;
end;

procedure TRObjects.BindMaterial(Material: TMaterial);
var
  Spec: TVector4D;
  MyHardness: Single;
begin
  with Material do
    begin
    if BumpMap <> nil then
      begin
      if (BumpMap <> fLastBoundBumpmap) or (fFirstMesh) then
        begin
        BumpMap.Bind(1);
        fLastBoundBumpmap := BumpMap;
        fCurrentShader.UniformI(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_HASNORMALMAP], 1);
        end;
      end
    else
      begin
      if (fLastBoundBumpmap <> nil) or (fFirstMesh) then
        begin
        ModuleManager.ModTexMng.ActivateTexUnit(1);
        ModuleManager.ModTexMng.BindTexture(-1);
        fCurrentShader.UniformI(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_HASNORMALMAP], 0);
        fLastBoundBumpmap := nil;
        end;
      end;
    if Texture <> nil then
      begin
      if (Texture <> fLastBoundTexture) or (fFirstMesh) then
        begin
        Texture.Bind(0);
        fCurrentShader.UniformI(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_HASTEXTURE], 1);
        fLastBoundTexture := Texture;
        end;
      end
    else
      begin
      if (fLastBoundTexture <> nil) or (fFirstMesh) then
        begin
        ModuleManager.ModTexMng.ActivateTexUnit(0);
        ModuleManager.ModTexMng.BindTexture(-1);
        fCurrentShader.UniformI(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_HASTEXTURE], 0);
        fLastBoundTexture := nil;
        end;
      end;
    fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_MEDIUMS], 1.0, Max(0.001, RefractiveIndex));
    if (RefractiveIndex = 0.0) and (Transparent) then
      fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_MEDIUMS], 1.0, 1.00001);
    Spec := Vector(Specularity, Reflectivity, 0, 0);
    MyHardness := Clamp(Hardness, 0, 128);
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, @Color.X);
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, @Emission.X);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, @Spec.X);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, @MyHardness);
    end;
end;

procedure TRObjects.Render(Mesh: TManagedMesh);
var
  Matrix: Array[0..15] of Single;
  ReflectionMapToBind: TTexture;
begin
// fCurrentShader.Bind;
  if ShadowMode then
    begin
    fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_SHADOWSIZE], ModuleManager.ModRenderer.ShadowSize);
    fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_SHADOWOFFSET], ModuleManager.ModRenderer.ShadowOffset.X, ModuleManager.ModRenderer.ShadowOffset.Y, ModuleManager.ModRenderer.ShadowOffset.Z);
    end;
  if MaterialMode then
    begin
    fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_FOGCOLOR], ModuleManager.ModRenderer.FogColor);
    fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_FOGSTRENGTH], ModuleManager.ModRenderer.FogStrength);
    fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_WATERHEIGHT], ModuleManager.ModRenderer.RWater.CurrentHeight);
    fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_WATERREFRACTIONMODE], ModuleManager.ModRenderer.FogRefractMode);
    end;

  BindMaterial(Mesh.GeoMesh.Material);

  if fCurrentShader <> fTransparentMaterialShader then
    begin
    if Mesh.GeoMesh.Material.Reflectivity > 0.01 then
      begin
      if not (MaterialMode or ShadowMode or LightShadowMode) then
        begin
        if ((Mesh.GeoMesh.Material.Reflectivity * Power(0.5, ModuleManager.ModRenderer.ReflectionRealtimeDistanceExponent * Max(0, VecLength(ModuleManager.ModCamera.ActiveCamera.Position - Vector3D(Vector(0, 0, 0, 1) * Mesh.GeoMesh.CalculatedMatrix)) - Mesh.VBO.Radius)) > ModuleManager.ModRenderer.ReflectionRealtimeMinimum) and (Mesh.Reflection <> nil)) and not (Mesh.GeoMesh.Material.OnlyEnvironmentMapHint) then
          ReflectionMapToBind := Mesh.Reflection.Map.Textures[0]
        else
          ReflectionMapToBind := ModuleManager.ModRenderer.EnvironmentMap.Map.Textures[0];
        if (ReflectionMapToBind <> fLastBoundReflectionMap) or (fFirstMesh) then
          begin
          ReflectionMapToBind.Bind(3);
          fLastBoundReflectionMap := ReflectionMapToBind;
          end;
        end
      else
        fLastBoundReflectionMap := nil;
      end
    else
      begin
      if (fLastBoundReflectionMap <> nil) or (fFirstMesh) then
        begin
        ModuleManager.ModTexMng.ActivateTexUnit(3);
        ModuleManager.ModTexMng.BindTexture(-1);
        fLastBoundReflectionMap := nil;
        end;
      end;
    end;

  MakeOGLCompatibleMatrix(Mesh.GeoMesh.CalculatedMatrix, @Matrix[0]);

  fCurrentShader.UniformMatrix4D(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_TRANSFORMMATRIX], @Matrix[0]);
  fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_VIEWPOINT], ModuleManager.ModRenderer.ViewPoint.X, ModuleManager.ModRenderer.ViewPoint.Y, ModuleManager.ModRenderer.ViewPoint.Z);

  if Mesh.VBO <> fLastBoundVBO then
    begin
    if fLastBoundVBO <> nil then
      fLastBoundVBO.Unbind;
    fLastBoundVBO := Mesh.VBO;
    end;
  if fLastBoundVBO <> nil then
    begin
    fLastBoundVBO.Bind;
    fLastBoundVBO.Render;
    fLastBoundVBO.Unbind;
    end;

// fCurrentShader.Unbind;

  fFirstMesh := False;
end;

procedure TRObjects.RenderSelectable;
var
  i, j, k: Integer;
  Color: DWord;
  CurrO: TGeoObject;
  CurrMO: TManagedObject;
  CurrMM: TManagedMesh;
  Matrix: Array[0..15] of Single;
begin
//   exit;
  fSelectionShader.Bind;
  fCurrentShader := fSelectionShader;

  glEnable(GL_CULL_FACE);
  for i := 0 to high(Park.SelectionEngine.fSelectableObjects) do
    begin
    CurrO := Park.SelectionEngine.fSelectableObjects[i].O;
    if CurrO = nil then
      continue;
    CurrMO := nil;
    for j := 0 to high(fManagedObjects) do
      if fManagedObjects[j].GeoObject = CurrO then
        CurrMO := fManagedObjects[j];
    if CurrMO = nil then
      continue;
    Color := CurrO.SelectionID;
    fCurrentShader.UniformI(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_SELECTIONMESHID], ((Color and $00FF0000) shr 16), ((Color and $0000FF00) shr 8), ((Color and $000000FF)));
    fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_MIRROR], CurrO.Mirror);
    with CurrO.Mirror do
      if X * Y * Z < 0 then
        ModuleManager.ModRenderer.InvertFrontFace;
    for j := 0 to high(CurrO.Meshes) do
      begin
      fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_ALPHA], CurrO.Meshes[j].Material.Color.W);
      CurrMM := nil;
      for k := 0 to high(CurrMO.Meshes) do
        if CurrMO.Meshes[k].GeoMesh = CurrO.Meshes[j] then
          CurrMM := CurrMO.Meshes[k];
      if CurrMM = nil then
        continue;
      if not CurrMM.Visible then
        continue;
//       if CurrO.Meshes[j].Material.Texture <> nil then
//         CurrO.Meshes[j].Material.Texture.Bind(0)
//       else
//         begin
//         ModuleManager.ModTexMng.ActivateTexUnit(0);
//         ModuleManager.ModTexMng.BindTexture(-1);
//         end;
      MakeOGLCompatibleMatrix(CurrO.Meshes[j].CalculatedMatrix, @Matrix[0]);

      fCurrentShader.UniformMatrix4D(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_TRANSFORMMATRIX], @Matrix[0]);

      CurrMM.VBO.Bind;
      CurrMM.VBO.Render;
      CurrMM.VBO.UnBind;
      end;
    with CurrO.Mirror do
      if X * Y * Z < 0 then
        ModuleManager.ModRenderer.InvertFrontFace;
    end;

  fSelectionShader.Unbind;
end;

procedure TRObjects.RenderTransparent;
var
  i, j: Integer;
begin
  Sync;
  fFirstMesh := True;
  fLastBoundReflectionMap := nil;
  fLastBoundBumpmap := nil;
  fLastBoundTexture := nil;
  fLastBoundVBO := nil;
  if (ModuleManager.ModRenderer.RenderParticles) and not ((ShadowMode) or (LightShadowMode)) then
    ModuleManager.ModRenderer.RParticles.Prepare;
  if MaterialMode then
    begin
    CurrentGBuffer.Textures[1].Bind(5);
    CurrentGBuffer.Textures[3].Bind(6);
    end;
  fCurrentMaterialCount := 1;
  if LightShadowMode then
    fCurrentShader := fTransparentLightShadowShader
  else if ShadowMode then
    fCurrentShader := fTransparentShadowShader
  else if MaterialMode then
    fCurrentShader := fTransparentMaterialShader
  else
    fCurrentShader := fTransparentShader;
  fCurrentShader.Bind;
  for i := 0 to high(fTransparentMeshOrder) do
    begin
    if fTransparentMeshOrder[i].Mesh <> nil then
      begin
      fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_MIRROR], fTransparentMeshOrder[i].ManagedObject.GeoObject.Mirror);
      with fTransparentMeshOrder[i].ManagedObject.GeoObject.Mirror do
        if X * Y * Z < 0 then
          ModuleManager.ModRenderer.InvertFrontFace;
      if ((fTransparentMeshOrder[i].Mesh.Visible) or (ShadowMode)) and ((fTransparentMeshOrder[i].Mesh.ParentObject <> fExcludedMeshObject) or (fTransparentMeshOrder[i].Mesh <> fExcludedMesh)) then
        if fTransparentMeshOrder[i].Mesh.Transparent then
          begin
          if fCurrentShader = fTransparentShader then
            fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_MASKOFFSET], fCurrentMaterialCount / 16, 0);
          fCurrentShader.UniformI(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_MATERIALID], (fCurrentMaterialCount shr 16) and $FF, (fCurrentMaterialCount shr 8) and $FF, fCurrentMaterialCount and $FF);
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
      with fTransparentMeshOrder[i].ManagedObject.GeoObject.Mirror do
        if X * Y * Z < 0 then
          ModuleManager.ModRenderer.InvertFrontFace;
      end
    else if (fTransparentMeshOrder[i].ParticleGroup <> nil) and (ModuleManager.ModRenderer.RenderParticles) and not ((ShadowMode) or (LightShadowMode)) then
      begin
      ModuleManager.ModRenderer.RParticles.Render(fTransparentMeshOrder[i].ParticleGroup);
//       fFirstMesh := True;
//       fLastBoundReflectionMap := nil;
//       fLastBoundBumpmap := nil;
//       fLastBoundTexture := nil;
//       fLastBoundVBO := nil;
      fCurrentShader.Bind;
      end;
    inc(fCurrentMaterialCount);
    end;
  if fLastBoundVBO <> nil then
    fLastBoundVBO.Unbind;
  fCurrentShader.Unbind;
end;

procedure TRObjects.RenderOpaque;
var
  i, j: Integer;
begin
  fFirstMesh := True;
  fLastBoundReflectionMap := nil;
  fLastBoundBumpmap := nil;
  fLastBoundTexture := nil;
  fLastBoundVBO := nil;
  MaterialMode := False;
  if ShadowMode then
    fCurrentShader := fOpaqueShadowShader
  else if LightShadowMode then
    fCurrentShader := fOpaqueLightShadowShader
  else
    fCurrentShader := fOpaqueShader;
  fCurrentShader.Bind;
  for i := 0 to high(fMeshClasses) do
    begin
    for j := 0 to high(fMeshClasses[i].Meshes) do
      begin
      fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_MIRROR], fMeshClasses[i].Meshes[j].ParentObject.GeoObject.Mirror);
//       fCurrentShader.UniformF(Uniforms[fCurrentShader.Tag, UNIFORM_ANY_VIRTSCALE], fMeshClasses[i].Meshes[j].ParentObject.GeoObject.VirtualScale);
      with fMeshClasses[i].Meshes[j].ParentObject.GeoObject.Mirror do
        if X * Y * Z < 0 then
          ModuleManager.ModRenderer.InvertFrontFace;
      if ((fMeshClasses[i].Meshes[j].Visible) or (ShadowMode)) and ((fMeshClasses[i].Meshes[j].ParentObject <> fExcludedMeshObject) or (fMeshClasses[i].Meshes[j] <> fExcludedMesh)) then
        if not fMeshClasses[i].Meshes[j].Transparent then
          Render(fMeshClasses[i].Meshes[j]);
      with fMeshClasses[i].Meshes[j].ParentObject.GeoObject.Mirror do
        if X * Y * Z < 0 then
          ModuleManager.ModRenderer.InvertFrontFace;
      end;
    end;
  fCurrentShader.Unbind;
  if fLastBoundVBO <> nil then
    fLastBoundVBO.Unbind;
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
        fManagedObjects[i].Meshes[j].Visible := ModuleManager.ModRenderer.Frustum.IsSphereWithin(Pos.X, Pos.Y, Pos.Z, fManagedObjects[i].Meshes[j].VBO.Radius * Max(fManagedObjects[i].GeoObject.VirtualScale.X, Max(fManagedObjects[i].GeoObject.VirtualScale.Y, fManagedObjects[i].GeoObject.VirtualScale.Z)));
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
      if (fManagedObjects[i].Meshes[j].GeoMesh.Material.Reflectivity * Power(0.5, ModuleManager.ModRenderer.ReflectionRealtimeDistanceExponent * Max(0, VecLength(ModuleManager.ModCamera.ActiveCamera.Position - MeshPosition) - fManagedObjects[i].Meshes[j].VBO.Radius)) > ModuleManager.ModRenderer.ReflectionRealtimeMinimum) and not (fManagedObjects[i].Meshes[j].GeoMesh.Material.OnlyEnvironmentMapHint) then
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

constructor TRObjects.Create;
var
  I: Integer;
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
  EventManager.AddCallback('TParticleManager.AddGroup', @AddParticleGroup);
  EventManager.AddCallback('TParticleManager.DeleteGroup', @DeleteParticleGroup);

  fLastManagedObject := -1;

  fOpaqueShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadow.vs', 'orcf-world-engine/scene/objects/shadow-opaque.fs');
  fOpaqueShadowShader.Tag := SHADER_OPAQUE_SHADOW;
  Shaders[SHADER_OPAQUE_SHADOW] := fOpaqueShadowShader;

  fTransparentShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadow.vs', 'orcf-world-engine/scene/objects/shadow-transparent.fs');
  fTransparentShadowShader.UniformI('Texture', 0);
  fTransparentShadowShader.Tag := SHADER_TRANSPARENT_SHADOW;
  Shaders[SHADER_TRANSPARENT_SHADOW] := fTransparentShadowShader;

  fOpaqueLightShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadowLight.vs', 'orcf-world-engine/scene/objects/shadowLight-opaque.fs');
  fOpaqueLightShadowShader.Tag := SHADER_OPAQUE_SHADOW_LIGHT;
  Shaders[SHADER_OPAQUE_SHADOW_LIGHT] := fOpaqueLightShadowShader;

  fTransparentLightShadowShader := TShader.Create('orcf-world-engine/scene/objects/shadowLight.vs', 'orcf-world-engine/scene/objects/shadowLight-transparent.fs');
  fTransparentLightShadowShader.UniformI('Texture', 0);
  fTransparentLightShadowShader.Tag := SHADER_TRANSPARENT_SHADOW_LIGHT;
  Shaders[SHADER_TRANSPARENT_SHADOW_LIGHT] := fTransparentLightShadowShader;

  fOpaqueShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/scene/objects/normal-opaque.fs', 'orcf-world-engine/scene/objects/normal.gs', 3);
  fOpaqueShader.UniformI('Texture', 0);
  fOpaqueShader.UniformI('NormalMap', 1);
  fOpaqueShader.UniformI('ReflectionMap', 3);
  fOpaqueShader.Tag := SHADER_OPAQUE;
  Shaders[SHADER_OPAQUE] := fOpaqueShader;

  fTransparentShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/scene/objects/normal-transparent.fs', 'orcf-world-engine/scene/objects/normal.gs', 3);
  fTransparentShader.UniformI('Texture', 0);
  fTransparentShader.UniformI('NormalMap', 1);
  fTransparentShader.UniformI('ReflectionMap', 3);
  fTransparentShader.UniformI('TransparencyMask', 7);
  fTransparentShader.UniformF('MaskSize', ModuleManager.ModRenderer.TransparencyMask.Width, ModuleManager.ModRenderer.TransparencyMask.Height);
  fTransparentShader.Tag := SHADER_TRANSPARENT;
  Shaders[SHADER_TRANSPARENT] := fTransparentShader;

  fTransparentMaterialShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/scene/objects/normal-material.fs', 'orcf-world-engine/scene/objects/normal.gs', 3);
  fTransparentMaterialShader.UniformI('Texture', 0);
  fTransparentMaterialShader.UniformI('NormalMap', 5);
  fTransparentMaterialShader.UniformI('ReflectionMap', 3);
  fTransparentMaterialShader.UniformI('MaterialMap', 6);
  fTransparentMaterialShader.UniformI('LightTexture', 7);
  fTransparentMaterialShader.UniformI('SpecularTexture', 4);
  fTransparentMaterialShader.Tag := SHADER_TRANSPARENT_MATERIAL;
  Shaders[SHADER_TRANSPARENT_MATERIAL] := fTransparentMaterialShader;

  fSelectionShader := TShader.Create('orcf-world-engine/scene/objects/normal.vs', 'orcf-world-engine/inferred/selection.fs', 'orcf-world-engine/scene/objects/normal.gs', 3);
  fSelectionShader.UniformI('Texture', 0);
  fSelectionShader.Tag := SHADER_SELECTION;
  Shaders[SHADER_SELECTION] := fSelectionShader;

  fReflectionPass := TRenderPass.Create(ModuleManager.ModRenderer.ReflectionSize, ModuleManager.ModRenderer.ReflectionSize);
  fReflectionPass.RenderTerrain := ModuleManager.ModRenderer.ReflectionRenderTerrain;
  fReflectionPass.RenderObjects := ModuleManager.ModRenderer.ReflectionRenderObjects;
  fReflectionPass.RenderParticles := ModuleManager.ModRenderer.ReflectionRenderParticles;
  fReflectionPass.RenderAutoplants := ModuleManager.ModRenderer.ReflectionRenderAutoplants;

  fExcludedMeshObject := nil;
  fExcludedMesh := nil;
  CurrentGBuffer := ModuleManager.ModRenderer.GBuffer;

  for I := 0 to high(Shaders) do
    begin
    Uniforms[I, UNIFORM_ANY_HASNORMALMAP] := Shaders[i].GetUniformLocation('HasNormalMap');
    Uniforms[I, UNIFORM_ANY_HASTEXTURE] := Shaders[i].GetUniformLocation('HasTexture');
    Uniforms[I, UNIFORM_ANY_MEDIUMS] := Shaders[i].GetUniformLocation('Mediums');
    Uniforms[I, UNIFORM_ANY_SHADOWSIZE] := Shaders[i].GetUniformLocation('ShadowSize');
    Uniforms[I, UNIFORM_ANY_SHADOWOFFSET] := Shaders[i].GetUniformLocation('ShadowOffset');
    Uniforms[I, UNIFORM_ANY_FOGCOLOR] := Shaders[i].GetUniformLocation('FogColor');
    Uniforms[I, UNIFORM_ANY_FOGSTRENGTH] := Shaders[i].GetUniformLocation('FogStrength');
    Uniforms[I, UNIFORM_ANY_WATERHEIGHT] := Shaders[i].GetUniformLocation('WaterHeight');
    Uniforms[I, UNIFORM_ANY_WATERREFRACTIONMODE] := Shaders[i].GetUniformLocation('WaterRefractionMode');
    Uniforms[I, UNIFORM_ANY_TRANSFORMMATRIX] := Shaders[i].GetUniformLocation('TransformMatrix');
    Uniforms[I, UNIFORM_ANY_VIEWPOINT] := Shaders[i].GetUniformLocation('ViewPoint');
    Uniforms[I, UNIFORM_ANY_SELECTIONMESHID] := Shaders[i].GetUniformLocation('SelectionMeshID');
    Uniforms[I, UNIFORM_ANY_MIRROR] := Shaders[i].GetUniformLocation('Mirror');
    Uniforms[I, UNIFORM_ANY_ALPHA] := Shaders[i].GetUniformLocation('Alpha');
    Uniforms[I, UNIFORM_ANY_MASKOFFSET] := Shaders[i].GetUniformLocation('MaskOffset');
    Uniforms[I, UNIFORM_ANY_MATERIALID] := Shaders[i].GetUniformLocation('MaterialID');
    end;
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
        if fTransparentMeshOrder[i].Mesh <> nil then
          fTransparentMeshOrder[i].Distance := VecLengthNoRoot(ModuleManager.ModRenderer.ViewPoint - Vector3D(Vector(0, 0, 0, 1) * fTransparentMeshOrder[i].Mesh.GeoMesh.CalculatedMatrix))
        else if fTransparentMeshOrder[i].ParticleGroup <> nil then
          fTransparentMeshOrder[i].Distance := VecLengthNoRoot(ModuleManager.ModRenderer.ViewPoint - fTransparentMeshOrder[i].ParticleGroup.InitialPosition)
        else
          fTransparentMeshOrder[i].Distance := 20000;

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

procedure TRObjects.Clear;
var
  I, J: Integer;
begin
  Terminate;
  fReflectionPass.Free;
  fSelectionShader.Free;
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
  EventManager.RemoveCallback(@AddParticleGroup);
  EventManager.RemoveCallback(@DeleteParticleGroup);
  Sync;
  for I := 0 to high(fManagedObjects) do
    begin
    for J := 0 to high(fManagedObjects[i].Meshes) do
      fManagedObjects[i].Meshes[j].Free;
    fManagedObjects[i].Free;
    end;
  for I := 0 to high(fMeshClasses) do
    fMeshClasses[i].VBO.Free;
  sleep(10);
end;


end.