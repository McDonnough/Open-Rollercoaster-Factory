unit m_renderer_opengl_objects;

interface

uses
  SysUtils, Classes, g_object_base, g_park, m_shdmng_class, m_renderer_opengl_classes, u_geometry, u_arrays, DGLOpenGL, u_vectors, m_texmng_class,
  m_renderer_opengl_frustum, m_renderer_opengl_lights, u_scene;

type
  TManagedMesh = class
    public
      fVBO: TObjectVBO;
      fMesh: TGeoMesh;
      fTriangles: Integer;
      Reflection: TFBO;
      fFrameMod: Integer;
      fStrongestLights: Array[0..6] of TLight;
      constructor Create;
      procedure CreateVBO;
      procedure CreateReflectionFBO;
      destructor Free;
    end;

  TManagedObject = class
    public
      fManagedMeshes: Array of TManagedMesh;
      fObject: TGeoObject;
      destructor Free;
    end;

  TRObjects = class
    protected
      b: Integer;
      fBoundShader: TShader;
      fShader, fShadowShader, fTransformDepthShader, fSunShadowShader: TShader;
      fTest: TGeoObject;
      fFrames: Integer;
      fExcludedMesh: TManagedMesh;
    public
      fManagedObjects: Array of TManagedObject;
      procedure AddObject(Event: String; Data, Result: Pointer);
      procedure DeleteObject(Event: String; Data, Result: Pointer);
      procedure AddMesh(Event: String; Data, Result: Pointer);
      procedure DeleteMesh(Event: String; Data, Result: Pointer);
      procedure Render(O: TManagedObject; Transparent: Boolean);
      procedure Render(Event: String; Data, Result: Pointer);
      procedure RenderReflections(O: TManagedMesh);
      procedure RenderReflections;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, math, m_renderer_opengl_interface, u_ase;

constructor TManagedMesh.Create;
var
  i: Integer;
begin
  fVBO := nil;
  fTriangles := 0;
  Reflection := nil;
  for i := 0 to high(fStrongestLights) do
    fStrongestLights[i] := nil;
end;

procedure TManagedMesh.CreateReflectionFBO;
begin
  Reflection := TFBO.Create(384, 576, true);
  Reflection.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);
  Reflection.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fFrameMod := Round(3 * Random);
end;

procedure TManagedMesh.CreateVBO;
begin
  if fVBO <> nil then
    fVBO.Free;
  fTriangles := length(fMesh.Faces);
  fVBO := TObjectVBO.Create(fMesh);
  fVBO.Unbind;
end;

destructor TManagedMesh.Free;
begin
  if fVBO <> nil then
    fVBO.Free;
  if Reflection <> nil then
    Reflection.Free;
end;

destructor TManagedObject.Free;
var
  i: Integer;
begin
  for i := 0 to high(fManagedMeshes) do
    fManagedMeshes[i].Free;
end;

procedure TRObjects.AddObject(Event: String; Data, Result: Pointer);
begin
  ModuleManager.ModRenderer.LightManager.Sync;
  SetLength(fManagedObjects, 1 + Length(fManagedObjects));
  fManagedObjects[high(fManagedObjects)] := TManagedObject.Create;
  fManagedObjects[high(fManagedObjects)].fObject := TGeoObject(Data);
end;

procedure TRObjects.DeleteObject(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    if fManagedObjects[i].fObject = TGeoObject(Data) then
      begin
      ModuleManager.ModRenderer.LightManager.Sync;
      fManagedObjects[i].Free;
      fManagedObjects[i] := fManagedObjects[high(fManagedObjects)];
      SetLength(fManagedObjects, length(fManagedObjects) - 1);
      exit;
      end;
end;

procedure TRObjects.AddMesh(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    if fManagedObjects[i].fObject = TGeoObject(Data) then
      begin
      ModuleManager.ModRenderer.LightManager.Sync;
      SetLength(fManagedObjects[i].fManagedMeshes, length(fManagedObjects[i].fManagedMeshes) + 1);
      fManagedObjects[i].fManagedMeshes[high(fManagedObjects[i].fManagedMeshes)] := TManagedMesh.Create;
      fManagedObjects[i].fManagedMeshes[high(fManagedObjects[i].fManagedMeshes)].fMesh := TGeoMesh(Result);
      EventManager.CallEvent('TRObjects.MeshAdded', fManagedObjects[i].fManagedMeshes[high(fManagedObjects[i].fManagedMeshes)], nil);
      exit;
      end;
end;

procedure TRObjects.DeleteMesh(Event: String; Data, Result: Pointer);
var
  i, j: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    if fManagedObjects[i].fObject = TGeoObject(Data) then
      for j := 0 to high(fManagedObjects[i].fManagedMeshes) do
        begin
        ModuleManager.ModRenderer.LightManager.Sync;
        EventManager.CallEvent('TRObjects.MeshDeleted', fManagedObjects[i].fManagedMeshes[j], nil);
        fManagedObjects[i].fManagedMeshes[j].Free;
        fManagedObjects[i].fManagedMeshes[j] := fManagedObjects[i].fManagedMeshes[high(fManagedObjects[i].fManagedMeshes)];
        SetLength(fManagedObjects[i].fManagedMeshes, Length(fManagedObjects[i].fManagedMeshes) - 1);
        exit;
        end;
end;

procedure TRObjects.RenderReflections(O: TManagedMesh);
var
  Pos: TVector4D;
begin
  Pos := Vector(0, 0, 0, 1) * O.fMesh.CalculatedMatrix;

  fExcludedMesh := O;
  ModuleManager.ModRenderer.DynamicLODBias := 8;

  if O.Reflection = nil then
    O.CreateReflectionFBO;
  O.Reflection.Bind;
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);

  // FRONT
  glViewport(0, 0, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glTranslatef(-Pos.X, -Pos.Y, -Pos.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // BACK
  glViewport(2 * O.Reflection.Width div 3, 0, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(180, 0, 1, 0);
  glTranslatef(-Pos.X, -Pos.Y, -Pos.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // LEFT
  glViewport(0, O.Reflection.Height div 2, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(270, 0, 1, 0);
  glTranslatef(-Pos.X, -Pos.Y, -Pos.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // RIGHT
  glViewport(O.Reflection.Width div 3, 0, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(90, 0, 1, 0);
  glTranslatef(-Pos.X, -Pos.Y, -Pos.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // DOWN
  glViewport(O.Reflection.Width div 3, O.Reflection.Height div 2, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(90, 1, 0, 0);
  glTranslatef(-Pos.X, -Pos.Y, -Pos.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // UP
  glViewport(2 * O.Reflection.Width div 3, O.Reflection.Height div 2, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(270, 1, 0, 0);
  glTranslatef(-Pos.X, -Pos.Y, -Pos.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  O.Reflection.Unbind;

  ModuleManager.ModRenderer.DynamicLODBias := 0;
end;

procedure TRObjects.RenderReflections;
var
  i, j: Integer;
  x: TFrustum;
  A: TVector4D;
  D: Single;
  FrameMod: Integer;
begin
  inc(fFrames);
  FrameMod := fFrames mod 4;
  x := TFrustum.Create;
  x.Calculate;
  fInterface.PushOptions;
  fInterface.Options.Items['water:reflection'] := 'off';
  fInterface.Options.Items['water:refraction'] := 'off';
  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glLoadIdentity;
  gluPerspective(90, 1, 0.1, 10000);
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  for i := 0 to high(fManagedObjects) do
    for j := 0 to high(fManagedObjects[i].fManagedMeshes) do
      if FrameMod = fManagedObjects[i].fManagedMeshes[j].fFrameMod then
        begin
        A := Vector(0, 0, 0, 1) * fManagedObjects[i].fManagedMeshes[j].fMesh.CalculatedMatrix;
        D := VecLengthNoRoot(ModuleManager.ModCamera.ActiveCamera.Position - Vector3D(A));
        if (D < fManagedObjects[i].fManagedMeshes[j].fMesh.MaxDistance * fManagedObjects[i].fManagedMeshes[j].fMesh.MaxDistance) and (D >= fManagedObjects[i].fManagedMeshes[j].fMesh.MinDistance * fManagedObjects[i].fManagedMeshes[j].fMesh.MinDistance) and (X.IsSphereWithin(A.X, A.Y, A.Z, fManagedObjects[i].fManagedMeshes[j].fVBO.Radius)) then
          RenderReflections(fManagedObjects[i].fManagedMeshes[j]);
        end;
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix;
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
  fInterface.PopOptions;
  fExcludedMesh := nil;
  x.Free;
end;

procedure TRObjects.Render(O: TManagedObject; Transparent: Boolean);
var
  i, j: Integer;
  Matrix: Array[0..15] of Single;
  A: TVector4D;
  D: Single;
  IsTransparent: Boolean;
  tmpMatrix: TMatrix4D;
begin
  glEnable(GL_ALPHA_TEST);
  glEnable(GL_CULL_FACE);
  fBoundShader := fShader;
  if fInterface.Options.Items['shader:mode'] = 'transform:depth' then
    fBoundShader := fTransformDepthShader
  else if fInterface.Options.Items['shader:mode'] = 'shadow:shadow' then
    fBoundShader := fShadowShader
  else if fInterface.Options.Items['shader:mode'] = 'sunshadow:sunshadow' then
    fBoundShader := fSunShadowShader
  else
    begin
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    end;
  fBoundShader.Bind;
  fBoundShader.UniformF('ShadowQuadA', ModuleManager.ModRenderer.ShadowQuad[0].X, ModuleManager.ModRenderer.ShadowQuad[0].Z);
  fBoundShader.UniformF('ShadowQuadB', ModuleManager.ModRenderer.ShadowQuad[1].X, ModuleManager.ModRenderer.ShadowQuad[1].Z);
  fBoundShader.UniformF('ShadowQuadC', ModuleManager.ModRenderer.ShadowQuad[2].X, ModuleManager.ModRenderer.ShadowQuad[2].Z);
  fBoundShader.UniformF('ShadowQuadD', ModuleManager.ModRenderer.ShadowQuad[3].X, ModuleManager.ModRenderer.ShadowQuad[3].Z);
  if O.fObject = fTest then
    begin
    inc(b);
    O.fManagedMeshes[3].fMesh.Matrix := TranslationMatrix(Vector(3 - 3 * Sin(DegToRad(b / 20)), 3 + 3 * Sin(DegToRad(b / 20)), 3 + 3 * Cos(DegToRad(b / 20))));
    O.fManagedMeshes[0].fMesh.Matrix := TranslationMatrix(Vector(5 - 3 * Sin(DegToRad(b / 25)), 3 + 3 * Sin(DegToRad(b / 25)), 1 + 3 * Cos(DegToRad(b / 25))));
    O.fManagedMeshes[1].fMesh.Matrix := RotationMatrix(b / 40, Normalize(Vector(0, 1, 0))) * TranslationMatrix(Vector(2, 10, 4));
    O.fManagedMeshes[2].fMesh.Matrix := RotationMatrix(b / 50, Normalize(Vector(0.422618, -0.9659258, -0.258819)));
    O.fObject.UpdateMatrix;
    end;
  for i := 0 to high(O.fManagedMeshes) do
    begin
    if O.fManagedMeshes[i] = fExcludedMesh then
      continue;
    IsTransparent := false;
    if O.fManagedMeshes[i].fMesh.Material.Texture <> nil then
      begin
      if (O.fManagedMeshes[i].fMesh.Material.Texture.BPP = 4) or (O.fManagedMeshes[i].fMesh.Material.Color.W < 1.0) then
        IsTransparent := true;
      end
    else
      if O.fManagedMeshes[i].fMesh.Material.Color.W < 1.0 then
        IsTransparent := true;
    if IsTransparent <> Transparent then
      continue;
    A := Vector(0, 0, 0, 1) * O.fManagedMeshes[i].fMesh.CalculatedMatrix;
    D := VecLengthNoRoot(ModuleManager.ModCamera.ActiveCamera.Position - Vector3D(A));
    if O.fManagedMeshes[i].fVBO = nil then
      O.fManagedMeshes[i].CreateVBO;
    if (D < O.fManagedMeshes[i].fMesh.MaxDistance * O.fManagedMeshes[i].fMesh.MaxDistance) and (D >= O.fManagedMeshes[i].fMesh.MinDistance * O.fManagedMeshes[i].fMesh.MinDistance) and (ModuleManager.ModRenderer.Frustum.IsSphereWithin(A.X, A.Y, A.Z, O.fManagedMeshes[i].fVBO.Radius)) then
      begin
      tmpMatrix := O.fManagedMeshes[i].fMesh.CalculatedMatrix;
      MakeOGLCompatibleMatrix(tmpMatrix, @Matrix[0]);
      if O.fManagedMeshes[i].fMesh.Material.BumpMap <> nil then
        begin
        O.fManagedMeshes[i].fMesh.Material.BumpMap.Bind(1);
        fBoundShader.Bind;
        fBoundShader.UniformI('UseBumpMap', 1);
        fBoundShader.UniformF('BumpMapFactor', O.fManagedMeshes[i].fMesh.Material.BumpMapFactor);
        fBoundShader.UniformMatrix4D('TransformMatrix', @Matrix[0]);
        end
      else
        begin
        ModuleManager.ModTexMng.ActivateTexUnit(1);
        ModuleManager.ModTexMng.BindTexture(-1);
        fBoundShader.Bind;
        fBoundShader.UniformI('UseBumpMap', 0);
        fBoundShader.UniformMatrix4D('TransformMatrix', @Matrix[0]);
        end;
      if O.fManagedMeshes[i].fMesh.Material.Reflectivity <> 0 then
        begin
        if O.fManagedMeshes[i].Reflection = nil then
          O.fManagedMeshes[i].CreateReflectionFBO;
        O.fManagedMeshes[i].Reflection.Textures[0].Bind(2);
        fBoundShader.UniformI('UseReflections', 1);
        fBoundShader.UniformF('Reflective', O.fManagedMeshes[i].fMesh.Material.Reflectivity);
        end
      else
        begin
        ModuleManager.ModTexMng.ActivateTexUnit(2);
        ModuleManager.ModTexMng.BindTexture(-1);
        fBoundShader.UniformI('UseReflections', 0);
        fBoundShader.UniformF('Reflective', 0);
        end;
      if O.fManagedMeshes[i].fMesh.Material.Texture <> nil then
        begin
        O.fManagedMeshes[i].fMesh.Material.Texture.Bind(0);
        fBoundShader.UniformI('UseTexture', 1);
        end
      else
        begin
        ModuleManager.ModTexMng.ActivateTexUnit(0);
        ModuleManager.ModTexMng.BindTexture(-1);
        fBoundShader.UniformI('UseTexture', 0);
        end;
      if fInterface.Options.Items['shader:mode'] = 'normal:normal' then
        begin
        ModuleManager.ModRenderer.LightManager.StartBinding;
        for j := 0 to high(O.fManagedMeshes[i].fStrongestLights) do
          if O.fManagedMeshes[i].fStrongestLights[j] <> nil then
            O.fManagedMeshes[i].fStrongestLights[j].Bind(j + 1)
          else
            ModuleManager.ModRenderer.LightManager.NoLight.Bind(j + 1);
        ModuleManager.ModRenderer.LightManager.EndBinding;
        end;
      glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, @O.fManagedMeshes[i].fMesh.Material.Specularity);
      fBoundShader.UniformF('MeshColor', O.fManagedMeshes[i].fMesh.Material.Color.X, O.fManagedMeshes[i].fMesh.Material.Color.Y, O.fManagedMeshes[i].fMesh.Material.Color.Z, O.fManagedMeshes[i].fMesh.Material.Color.W);
      O.fManagedMeshes[i].fVBO.Bind;
      if IsTransparent then
        begin
        glCullFace(GL_FRONT);
        O.fManagedMeshes[i].fVBO.Render;
        glCullFace(GL_BACK);
        end;
      O.fManagedMeshes[i].fVBO.Render;
      O.fManagedMeshes[i].fVBO.UnBind;
      end;
    end;

end;

procedure TRObjects.Render(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    Render(fManagedObjects[i], Byte(Data^) = 2);
  if fBoundShader <> nil then
    begin
    fBoundShader.Unbind;
    fBoundShader := nil;
    end;
  ModuleManager.ModTexMng.ActivateTexUnit(1);
  ModuleManager.ModTexMng.BindTexture(-1);
  ModuleManager.ModTexMng.ActivateTexUnit(0);
  ModuleManager.ModTexMng.BindTexture(-1);
end;

constructor TRObjects.Create;
var
  i, j, k: Integer;
begin
  writeln('Initializing object renderer');
  try
    fExcludedMesh := nil;
    fFrames := 0;
    fBoundShader := nil;
    fShader := TShader.Create('rendereropengl/glsl/objects/normal.vs', 'rendereropengl/glsl/objects/normal.fs');
    fShader.UniformI('Tex', 0);
    fShader.UniformI('Bump', 1);
    fShader.UniformI('Reflections', 2);
    fShader.UniformI('ShadowMap1', 4);
    fShader.UniformI('ShadowMap2', 5);
    fShader.UniformI('ShadowMap3', 6);
    fShader.UniformI('SunShadowMap', 7);
    fShadowShader := TShader.Create('rendereropengl/glsl/objects/normalTransform.vs', 'rendereropengl/glsl/shadows/shdGen.fs');
    fShadowShader.UniformI('ModelTexture', 0);
    fTransformDepthShader := TShader.Create('rendereropengl/glsl/objects/normalTransform.vs', 'rendereropengl/glsl/simple.fs');
    fTransformDepthShader.UniformI('Tex', 0);
    fSunShadowShader := TShader.Create('rendereropengl/glsl/objects/normalSunShadowTransform.vs', 'rendereropengl/glsl/shadows/shdGenSun.fs');
    fSunShadowShader.UniformI('ModelTexture', 0);
    EventManager.AddCallback('TGeoObject.Created', @AddObject);
    EventManager.AddCallback('TGeoObject.Deleted', @DeleteObject);
    EventManager.AddCallback('TGeoObject.AddedMesh', @AddMesh);
    EventManager.AddCallback('TGeoObject.DeletedMesh', @DeleteMesh);
  except
    ModuleManager.ModLog.AddError('Failed to create object renderer in OpenGL rendering module: Internal error');
  end;

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
  fTest.Register;
end;

destructor TRObjects.Free;
var
  i: Integer;
begin
  fTest.Materials[2].BumpMap.Free;
  fTest.Free;
  for i := 0 to high(fManagedObjects) do
    fManagedObjects[i].Free;
  EventManager.RemoveCallback(@AddObject);
  EventManager.RemoveCallback(@DeleteObject);
  EventManager.RemoveCallback(@AddMesh);
  EventManager.RemoveCallback(@DeleteMesh);
  fShader.Free;
  fShadowShader.Free;
  fTransformDepthShader.Free;
  fSunShadowShader.Free;
end;

end.