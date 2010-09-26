unit m_renderer_opengl_objects;

interface

uses
  SysUtils, Classes, g_object_base, g_park, m_shdmng_class, m_renderer_opengl_classes, u_geometry, u_arrays, DGLOpenGL, u_vectors, m_texmng_class,
  m_renderer_opengl_frustum;

type
  TManagedMesh = class
    public
      fVBO: TVBO;
      fMesh: TMesh;
      fRadius: Single;
      fChangedVertices, fChangedTriangles: TRow;
      fTriangles: Integer;
      Reflection: TFBO;
      fFrameMod: Integer;
      constructor Create;
      procedure CreateVBO;
      procedure UpdateVBO;
      procedure CreateReflectionFBO;
      destructor Free;
    end;

  TManagedObject = class
    public
      fManagedMeshes: Array of TManagedMesh;
      fObject: TBasicObject;
      destructor Free;
    end;

  TRObjects = class
    protected
      b: Integer;
      fBoundShader: TShader;
      fShader, fTransformDepthShader, fSunShadowShader: TShader;
      fManagedObjects: Array of TManagedObject;
      fTest: TBasicObject;
      fFrames: Integer;
      fExcludedMesh: TManagedMesh;
    public
      procedure AddObject(Event: String; Data, Result: Pointer);
      procedure DeleteObject(Event: String; Data, Result: Pointer);
      procedure AddMesh(Event: String; Data, Result: Pointer);
      procedure DeleteMesh(Event: String; Data, Result: Pointer);
      procedure ChangeVertex(Event: String; Data, Result: Pointer);
      procedure ChangeTriangle(Event: String; Data, Result: Pointer);
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
begin
  fVBO := nil;
  fChangedVertices := TRow.Create;
  fChangedTriangles := TRow.Create;
  fTriangles := 0;
  fRadius := 0;
  Reflection := nil;
end;

procedure TManagedMesh.CreateReflectionFBO;
begin
  Reflection := TFBO.Create(384, 576, true);
  Reflection.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);
  Reflection.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fFrameMod := Round(3 * Random);
end;

procedure TManagedMesh.CreateVBO;
var
  i, j: Integer;
begin
  if fVBO <> nil then
    fVBO.Free;
  fTriangles := fMesh.TriangleCount;
  fVBO := TVBO.Create(3 * fMesh.TriangleCount, GL_T2F_C4F_N3F_V3F, GL_TRIANGLES);
  fVBO.Bind;
  for i := 0 to fTriangles - 1 do
    for j := 0 to 2 do
      begin
      fVBO.TexCoords[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].TexCoord;
      fVBO.Colors[3 * i + j] := Vector(fMesh.Vertices[fMesh.Triangles[i][j]].BumpTexCoordFactor, Vector(0, 0, 0));
      fVBO.Normals[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].Normal;
      fVBO.Vertices[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].Position;
      fRadius := Max(fRadius, VecLength(fMesh.Vertices[fMesh.Triangles[i][j]].Position));
      end;
  fVBO.Unbind;
end;

procedure TManagedMesh.UpdateVBO;
var
  i, j, k, l: Integer;
  fMap: Array of Boolean;
begin
  if (fMesh.TriangleCount <> fTriangles) or (fVBO = nil) then
    CreateVBO
  else
    begin
    if fChangedTriangles.Length + fChangedVertices.Length = 0 then
      exit;
    fVBO.Bind;
     for i := 0 to fMesh.TriangleCount - 1 do
      for j := 0 to 2 do
        begin
        if (fChangedTriangles.HasValue(i)) or (fChangedVertices.HasValue(fMesh.Triangles[i][j])) then
          begin
          fVBO.TexCoords[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].TexCoord;
          fVBO.Colors[3 * i + j] := Vector(fMesh.Vertices[fMesh.Triangles[i][j]].BumpTexCoordFactor, Vector(0, 0, 0));
          fVBO.Normals[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].Normal;
          fVBO.Vertices[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].Position;
          fRadius := Max(fRadius, VecLength(fMesh.Vertices[fMesh.Triangles[i][j]].Position));
          end;
        end;
    fVBO.Unbind;
    end;
  fChangedTriangles.Resize(0);
  fChangedVertices.Resize(0);
end;

destructor TManagedMesh.Free;
begin
  fChangedVertices.Free;
  fChangedTriangles.Free;
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
  SetLength(fManagedObjects, 1 + Length(fManagedObjects));
  fManagedObjects[high(fManagedObjects)] := TManagedObject.Create;
  fManagedObjects[high(fManagedObjects)].fObject := TBasicObject(Data);
end;

procedure TRObjects.DeleteObject(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    if fManagedObjects[i].fObject = TBasicObject(Data) then
      begin
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
    if fManagedObjects[i].fObject = TBasicObject(Data) then
      begin
      SetLength(fManagedObjects[i].fManagedMeshes, Integer(Result^) + 1);
      fManagedObjects[i].fManagedMeshes[Integer(Result^)] := TManagedMesh.Create;
      fManagedObjects[i].fManagedMeshes[Integer(Result^)].fMesh := fManagedObjects[i].fObject.fMeshes[Integer(Result^)];
      exit;
      end;
end;

procedure TRObjects.DeleteMesh(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    if fManagedObjects[i].fObject = TBasicObject(Data) then
      begin
      fManagedObjects[i].fManagedMeshes[Integer(Result^)].Free;
      fManagedObjects[i].fManagedMeshes[Integer(Result^)] := fManagedObjects[i].fManagedMeshes[high(fManagedObjects[i].fManagedMeshes)];
      SetLength(fManagedObjects[i].fManagedMeshes, Length(fManagedObjects[i].fManagedMeshes) - 1);
      exit;
      end;
end;

procedure TRObjects.ChangeVertex(Event: String; Data, Result: Pointer);
var
  i, j: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    if fManagedObjects[i].fObject = TBasicObject(TMesh(Data).Parent) then
      for j := 0 to high(fManagedObjects[i].fManagedMeshes) do
        if fManagedObjects[i].fManagedMeshes[j].fMesh = TMesh(Data) then
          begin
          if not fManagedObjects[i].fManagedMeshes[j].fChangedVertices.HasValue(Integer(Result^)) then
            fManagedObjects[i].fManagedMeshes[j].fChangedVertices.Insert(fManagedObjects[i].fManagedMeshes[j].fChangedVertices.Length, Integer(Result^));
          exit;
          end;
end;

procedure TRObjects.ChangeTriangle(Event: String; Data, Result: Pointer);
var
  i, j: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    if fManagedObjects[i].fObject = TBasicObject(TMesh(Data).Parent) then
      for j := 0 to high(fManagedObjects[i].fManagedMeshes) do
        if fManagedObjects[i].fManagedMeshes[j].fMesh = TMesh(Data) then
          begin
          if not fManagedObjects[i].fManagedMeshes[j].fChangedTriangles.HasValue(Integer(Result^)) then
            fManagedObjects[i].fManagedMeshes[j].fChangedTriangles.Insert(fManagedObjects[i].fManagedMeshes[j].fChangedTriangles.Length, Integer(Result^));
          exit;
          end;
end;

procedure TRObjects.RenderReflections(O: TManagedMesh);
begin
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
  glTranslatef(-O.fMesh.StaticOffset.X - O.fMesh.Offset.X, -O.fMesh.StaticOffset.Y - O.fMesh.Offset.Y, -O.fMesh.StaticOffset.Z - O.fMesh.Offset.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // BACK
  glViewport(2 * O.Reflection.Width div 3, 0, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(180, 0, 1, 0);
  glTranslatef(-O.fMesh.StaticOffset.X - O.fMesh.Offset.X, -O.fMesh.StaticOffset.Y - O.fMesh.Offset.Y, -O.fMesh.StaticOffset.Z - O.fMesh.Offset.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // LEFT
  glViewport(0, O.Reflection.Height div 2, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(270, 0, 1, 0);
  glTranslatef(-O.fMesh.StaticOffset.X - O.fMesh.Offset.X, -O.fMesh.StaticOffset.Y - O.fMesh.Offset.Y, -O.fMesh.StaticOffset.Z - O.fMesh.Offset.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // RIGHT
  glViewport(O.Reflection.Width div 3, 0, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(90, 0, 1, 0);
  glTranslatef(-O.fMesh.StaticOffset.X - O.fMesh.Offset.X, -O.fMesh.StaticOffset.Y - O.fMesh.Offset.Y, -O.fMesh.StaticOffset.Z - O.fMesh.Offset.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // DOWN
  glViewport(O.Reflection.Width div 3, O.Reflection.Height div 2, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(90, 1, 0, 0);
  glTranslatef(-O.fMesh.StaticOffset.X - O.fMesh.Offset.X, -O.fMesh.StaticOffset.Y - O.fMesh.Offset.Y, -O.fMesh.StaticOffset.Z - O.fMesh.Offset.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, false);
  ModuleManager.ModRenderer.RTerrain.RenderWaterSurfaces;
  ModuleManager.ModRenderer.RenderParts(false, true);

  // UP
  glViewport(2 * O.Reflection.Width div 3, O.Reflection.Height div 2, O.Reflection.Width div 3, O.Reflection.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(270, 1, 0, 0);
  glTranslatef(-O.fMesh.StaticOffset.X - O.fMesh.Offset.X, -O.fMesh.StaticOffset.Y - O.fMesh.Offset.Y, -O.fMesh.StaticOffset.Z - O.fMesh.Offset.Z);
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
  tmpMatrix: TMatrix4D;
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
        tmpMatrix := TranslateMatrix(fManagedObjects[i].fManagedMeshes[j].fMesh.StaticOffset) * Matrix4D(fManagedObjects[i].fManagedMeshes[j].fMesh.StaticRotationMatrix);
        tmpMatrix := tmpMatrix * TranslateMatrix(fManagedObjects[i].fManagedMeshes[j].fMesh.Offset) * Matrix4D(fManagedObjects[i].fManagedMeshes[j].fMesh.RotationMatrix);
        A := Vector(0, 0, 0, 1) * tmpMatrix;
        D := VecLengthNoRoot(ModuleManager.ModCamera.ActiveCamera.Position - Vector3D(A));
        if (D < fManagedObjects[i].fManagedMeshes[j].fMesh.MaxDistance * fManagedObjects[i].fManagedMeshes[j].fMesh.MaxDistance) and (D >= fManagedObjects[i].fManagedMeshes[j].fMesh.MinDistance * fManagedObjects[i].fManagedMeshes[j].fMesh.MinDistance) and (X.IsSphereWithin(A.X, A.Y, A.Z, fManagedObjects[i].fManagedMeshes[j].fRadius)) then
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
  i: Integer;
  tmpMatrix: TMatrix4D;
  Matrix: Array[0..15] of Single;
  A: TVector4D;
  D: Single;
  IsTransparent: Boolean;
begin
  glEnable(GL_ALPHA_TEST);
  glEnable(GL_CULL_FACE);
  fBoundShader := fShader;
  if fInterface.Options.Items['shader:mode'] = 'transform:depth' then
    fBoundShader := fTransformDepthShader
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
    O.fManagedMeshes[2].fMesh.Offset := Vector(3 - 3 * Sin(DegToRad(b / 20)), 3 + 3 * Sin(DegToRad(b / 20)), 3 + 3 * Cos(DegToRad(b / 20)));
    O.fManagedMeshes[0].fMesh.RotationMatrix := RotateMatrix(b / 50, Normalize(Vector(0, 1, 0)));
    end;
  for i := 0 to high(O.fManagedMeshes) do
    begin
    if O.fManagedMeshes[i] = fExcludedMesh then
      continue;
    IsTransparent := false;
    if O.fManagedMeshes[i].fMesh.Texture <> nil then
      begin
      if (O.fManagedMeshes[i].fMesh.Texture.BPP = 4) or (O.fManagedMeshes[i].fMesh.Color.W < 1.0) then
        IsTransparent := true;
      end
    else
      if O.fManagedMeshes[i].fMesh.Color.W < 1.0 then
        IsTransparent := true;
    if IsTransparent <> Transparent then
      continue;
    tmpMatrix := TranslateMatrix(O.fManagedMeshes[i].fMesh.StaticOffset) * Matrix4D(O.fManagedMeshes[i].fMesh.StaticRotationMatrix);
    tmpMatrix := tmpMatrix * TranslateMatrix(O.fManagedMeshes[i].fMesh.Offset) * Matrix4D(O.fManagedMeshes[i].fMesh.RotationMatrix);
    A := Vector(0, 0, 0, 1) * tmpMatrix;
    D := VecLengthNoRoot(ModuleManager.ModCamera.ActiveCamera.Position - Vector3D(A));
    if (D < O.fManagedMeshes[i].fMesh.MaxDistance * O.fManagedMeshes[i].fMesh.MaxDistance) and (D >= O.fManagedMeshes[i].fMesh.MinDistance * O.fManagedMeshes[i].fMesh.MinDistance) and (ModuleManager.ModRenderer.Frustum.IsSphereWithin(A.X, A.Y, A.Z, O.fManagedMeshes[i].fRadius)) then
      begin
      MakeOGLCompatibleMatrix(tmpMatrix, @Matrix[0]);
      if O.fManagedMeshes[i].fMesh.BumpMap <> nil then
        begin
        O.fManagedMeshes[i].fMesh.BumpMap.Bind(1);
        fBoundShader.Bind;
        fBoundShader.UniformI('UseBumpMap', 1);
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
      if O.fManagedMeshes[i].fMesh.Reflective <> 0 then
        begin
        if O.fManagedMeshes[i].Reflection = nil then
          O.fManagedMeshes[i].CreateReflectionFBO;
        O.fManagedMeshes[i].Reflection.Textures[0].Bind(2);
        fBoundShader.UniformI('UseReflections', 1);
        fBoundShader.UniformF('Reflective', O.fManagedMeshes[i].fMesh.Reflective);
        end
      else
        begin
        ModuleManager.ModTexMng.ActivateTexUnit(2);
        ModuleManager.ModTexMng.BindTexture(-1);
        fBoundShader.UniformI('UseReflections', 0);
        fBoundShader.UniformF('Reflective', 0);
        end;
      if O.fManagedMeshes[i].fMesh.Texture <> nil then
        begin
        O.fManagedMeshes[i].fMesh.Texture.Bind(0);
        fBoundShader.UniformI('UseTexture', 1);
        end
      else
        begin
        ModuleManager.ModTexMng.ActivateTexUnit(0);
        ModuleManager.ModTexMng.BindTexture(-1);
        fBoundShader.UniformI('UseTexture', 0);
        end;
      glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, @O.fManagedMeshes[i].fMesh.Shininess);
      fBoundShader.UniformF('MeshColor', O.fManagedMeshes[i].fMesh.Color.X, O.fManagedMeshes[i].fMesh.Color.Y, O.fManagedMeshes[i].fMesh.Color.Z, O.fManagedMeshes[i].fMesh.Color.W);
      O.fManagedMeshes[i].UpdateVBO;
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
  Meshes: AMesh;
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
    fShader.UniformI('SunShadowMap', 7);
    fTransformDepthShader := TShader.Create('rendereropengl/glsl/objects/normalTransform.vs', 'rendereropengl/glsl/simple.fs');
    fTransformDepthShader.UniformI('Tex', 0);
    fSunShadowShader := TShader.Create('rendereropengl/glsl/objects/normalSunShadowTransform.vs', 'rendereropengl/glsl/shadows/shdGenSun.fs');
    fSunShadowShader.UniformI('Tex', 0);
    fSunShadowShader.UniformI('ModelTexture', 0);
    EventManager.AddCallback('TBasicObject.Created', @AddObject);
    EventManager.AddCallback('TBasicObject.Deleted', @DeleteObject);
    EventManager.AddCallback('TBasicObject.AddedMesh', @AddMesh);
    EventManager.AddCallback('TBasicObject.DeletedMesh', @DeleteMesh);
    EventManager.AddCallback('TMesh.ChangedVertex', @ChangeVertex);
    EventManager.AddCallback('TMesh.ChangedTriangle', @ChangeTriangle);
  except
    ModuleManager.ModLog.AddError('Failed to create object renderer in OpenGL rendering module: Internal error');
  end;
  fTest := TBasicObject.Create;
  fTest.Move(Vector(160, 70, 160));
  Meshes := ASEFileToMeshArray(LoadASEFile('scenery/untitled.ase'));
  for i := 0 to high(Meshes) do
    with fTest.AddMesh(Meshes[i]) do
      begin
      FinishedVertexCreation;
      SmoothNormals;
      if i = 2 then
        begin
        Reflective := 0.8;
        Offset := Vector(0, 5, 5);
//         BumpMap := TTexture.Create;
//         BumpMap.FromFile('scenery/testbump.tga');
        end;
      if i = 1 then
        begin
        Reflective := 0.2;
        Offset := Vector(0, 0, 0);
        BumpMap := TTexture.Create;
        BumpMap.FromFile('scenery/testbump.tga');
        end;
      if i = 0 then
        begin
        Reflective := 0.2;
        Offset := Vector(0, 7, 5);
        end;
      end;
end;

destructor TRObjects.Free;
var
  i: Integer;
begin
  fTest.Free;
  for i := 0 to high(fManagedObjects) do
    fManagedObjects[i].Free;
  EventManager.RemoveCallback(@AddObject);
  EventManager.RemoveCallback(@DeleteObject);
  EventManager.RemoveCallback(@AddMesh);
  EventManager.RemoveCallback(@DeleteMesh);
  EventManager.RemoveCallback(@ChangeVertex);
  EventManager.RemoveCallback(@ChangeTriangle);
  fShader.Free;
  fTransformDepthShader.Free;
  fSunShadowShader.Free;
end;

end.