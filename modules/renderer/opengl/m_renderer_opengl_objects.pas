unit m_renderer_opengl_objects;

interface

uses
  SysUtils, Classes, g_object_base, g_park, m_shdmng_class, m_renderer_opengl_classes, u_geometry, u_arrays, DGLOpenGL, u_vectors, m_texmng_class;

type
  TManagedMesh = class
    public
      fVBO: TVBO;
      fMesh: TMesh;
      fRadius: Single;
      fChangedVertices, fChangedTriangles: TRow;
      fTriangles: Integer;
      constructor Create;
      procedure CreateVBO;
      procedure UpdateVBO;
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
      fBoundShader: TShader;
      fShader, fTransformDepthShader, fSunShadowShader: TShader;
      fShaderTesselation, fTransformDepthShaderTesselation, fSunShadowShaderTesselation: TShader;
      fManagedObjects: Array of TManagedObject;
      a: Integer;
      fTest: TBasicObject;
    public
      procedure AddObject(Event: String; Data, Result: Pointer);
      procedure DeleteObject(Event: String; Data, Result: Pointer);
      procedure AddMesh(Event: String; Data, Result: Pointer);
      procedure DeleteMesh(Event: String; Data, Result: Pointer);
      procedure ChangeVertex(Event: String; Data, Result: Pointer);
      procedure ChangeTriangle(Event: String; Data, Result: Pointer);
      procedure Render(O: TManagedObject);
      procedure Render(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, math, m_renderer_opengl_interface;

constructor TManagedMesh.Create;
begin
  fVBO := nil;
  fChangedVertices := TRow.Create;
  fChangedTriangles := TRow.Create;
  fTriangles := 0;
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
      fVBO.Colors[3 * i + j] := Vector(fMesh.Vertices[fMesh.Triangles[i][j]].BumpTexCoord, 0.0, 1.0);
      fVBO.Normals[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].Normal;
      fVBO.Vertices[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].Position;
      end;
  fVBO.Unbind;
end;

procedure TManagedMesh.UpdateVBO;
var
  i, j: Integer;
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
          fVBO.Colors[3 * i + j] := Vector(fMesh.Vertices[fMesh.Triangles[i][j]].BumpTexCoord, 0.0, 1.0);
          fVBO.Normals[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].Normal;
          fVBO.Vertices[3 * i + j] := fMesh.Vertices[fMesh.Triangles[i][j]].Position;
          end;
        end;
    fVBO.Unbind;
    end;
end;

destructor TManagedMesh.Free;
begin
  fChangedVertices.Free;
  fChangedTriangles.Free;
  if fVBO <> nil then
    fVBO.Free;
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

procedure TRObjects.Render(O: TManagedObject);
var
  i: Integer;
  fNewBoundShader: TShader;
  tmpMatrix: TMatrix4D;
  Matrix: Array[0..15] of Single;
begin
  glEnable(GL_ALPHA_TEST);
  glEnable(GL_CULL_FACE);
  fNewBoundShader := fShader;
  if fInterface.Options.Items['shader:mode'] = 'transform:depth' then
    fNewBoundShader := fTransformDepthShader
  else if fInterface.Options.Items['shader:mode'] = 'sunshadow:sunshadow' then
    fNewBoundShader := fSunShadowShader
  else
    begin
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    inc(a);
    fTest.Rotate(RotateMatrix(a, Vector(0, 1, 0)));
    fTest.fMeshes[0].RotationMatrix := (RotateMatrix(-5 * a, Vector(0, 1, 0)));
    fTest.fMeshes[1].RotationMatrix := (RotateMatrix(-5 * a, Vector(0, 1, 0)));
    end;
  if fBoundShader <> fNewBoundShader then
    begin
    fBoundShader := fNewBoundShader;
    fBoundShader.Bind;
    end;
  fBoundShader.UniformF('ShadowQuadA', ModuleManager.ModRenderer.ShadowQuad[0].X, ModuleManager.ModRenderer.ShadowQuad[0].Z);
  fBoundShader.UniformF('ShadowQuadB', ModuleManager.ModRenderer.ShadowQuad[1].X, ModuleManager.ModRenderer.ShadowQuad[1].Z);
  fBoundShader.UniformF('ShadowQuadC', ModuleManager.ModRenderer.ShadowQuad[2].X, ModuleManager.ModRenderer.ShadowQuad[2].Z);
  fBoundShader.UniformF('ShadowQuadD', ModuleManager.ModRenderer.ShadowQuad[3].X, ModuleManager.ModRenderer.ShadowQuad[3].Z);

  for i := 0 to high(O.fManagedMeshes) do
    begin
    if O.fManagedMeshes[i].fMesh.BumpMap <> nil then
      begin
      O.fManagedMeshes[i].fMesh.BumpMap.Bind(1);
      fBoundShader.UniformI('UseBumpMap', 1);
      end
    else
      begin
      ModuleManager.ModTexMng.ActivateTexUnit(1);
      ModuleManager.ModTexMng.BindTexture(-1);
      fBoundShader.UniformI('UseBumpMap', 0);
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
    tmpMatrix := TranslateMatrix(O.fManagedMeshes[i].fMesh.StaticOffset) * Matrix4D(O.fManagedMeshes[i].fMesh.StaticRotationMatrix);
    tmpMatrix := tmpMatrix * TranslateMatrix(O.fManagedMeshes[i].fMesh.Offset) * Matrix4D(O.fManagedMeshes[i].fMesh.RotationMatrix);
    MakeOGLCompatibleMatrix(tmpMatrix, @Matrix[0]);
    fBoundShader.UniformMatrix4D('TransformMatrix', @Matrix[0]);
    O.fManagedMeshes[i].UpdateVBO;
    O.fManagedMeshes[i].fVBO.Bind;
    O.fManagedMeshes[i].fVBO.Render;
    O.fManagedMeshes[i].fVBO.UnBind;
    end;
end;

procedure TRObjects.Render(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fManagedObjects) do
    Render(fManagedObjects[i]);
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
  i: Integer;
begin
  writeln('Initializing object renderer');
  try
    fBoundShader := nil;
    fShader := TShader.Create('rendereropengl/glsl/objects/normal.vs', 'rendereropengl/glsl/objects/normal.fs');
    fShader.UniformI('Tex', 0);
    fShader.UniformI('Bump', 1);
    fShader.UniformI('SunShadowMap', 7);
    fTransformDepthShader := TShader.Create('rendereropengl/glsl/objects/normalTransform.vs', 'rendereropengl/glsl/simple.fs');
    fTransformDepthShader.UniformI('Tex', 0);
    fTransformDepthShader.UniformI('Bump', 1);
    fSunShadowShader := TShader.Create('rendereropengl/glsl/objects/normalSunShadowTransform.vs', 'rendereropengl/glsl/shadows/shdGenSun.fs');
    fSunShadowShader.UniformI('Tex', 0);
    fSunShadowShader.UniformI('ModelTexture', 0);
    fSunShadowShader.UniformI('Bump', 1);
    fShaderTesselation := TShader.Create('rendereropengl/glsl/objects/normal.vs', 'rendereropengl/glsl/objects/normal.fs', 'rendereropengl/glsl/objects/normal.gs');
    fShaderTesselation.UniformI('Tex', 0);
    fShaderTesselation.UniformI('Bump', 1);
    fShaderTesselation.UniformI('SunShadowMap', 7);
    fTransformDepthShaderTesselation := TShader.Create('rendereropengl/glsl/objects/normalTransform.vs', 'rendereropengl/glsl/simple.fs', 'rendereropengl/glsl/objects/normal.gs');
    fTransformDepthShaderTesselation.UniformI('Tex', 0);
    fTransformDepthShaderTesselation.UniformI('Bump', 1);
    fSunShadowShaderTesselation := TShader.Create('rendereropengl/glsl/objects/normalSunShadowTransform.vs', 'rendereropengl/glsl/shadows/shdGenSun.fs', 'rendereropengl/glsl/objects/normal.gs');
    fSunShadowShaderTesselation.UniformI('Tex', 0);
    fSunShadowShaderTesselation.UniformI('ModelTexture', 0);
    fSunShadowShaderTesselation.UniformI('Bump', 1);
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
  for i := 0 to 1 do
    with fTest.AddMesh do
      begin
      Offset := Vector(10 - 20 * i, 0, 10 - 20 * i);

      Vertices[0] := MakeExtendedMeshVertex(Vector(-2.5, -2.5, -2.5), Vector(0, -1, 0), Vector(0, 0), Vector(0, 0));
      Vertices[1] := MakeExtendedMeshVertex(Vector(2.5, -2.5, -2.5), Vector(0, -1, 0), Vector(1, 0), Vector(1, 0));
      Vertices[2] := MakeExtendedMeshVertex(Vector(2.5, -2.5, 2.5), Vector(0, -1, 0), Vector(1, 1), Vector(1, 1));
      Vertices[3] := MakeExtendedMeshVertex(Vector(-2.5, -2.5, 2.5), Vector(0, -1, 0), Vector(0, 1), Vector(0, 1));

      Vertices[4] := MakeExtendedMeshVertex(Vector(-2.5, 2.5, 2.5), Vector(0, 1, 0), Vector(0, 1), Vector(0, 1));
      Vertices[5] := MakeExtendedMeshVertex(Vector(2.5, 2.5, 2.5), Vector(0, 1, 0), Vector(1, 1), Vector(1, 1));
      Vertices[6] := MakeExtendedMeshVertex(Vector(2.5, 2.5, -2.5), Vector(0, 1, 0), Vector(1, 0), Vector(1, 0));
      Vertices[7] := MakeExtendedMeshVertex(Vector(-2.5, 2.5, -2.5), Vector(0, 1, 0), Vector(0, 0), Vector(0, 0));

      Vertices[8] := MakeExtendedMeshVertex(Vector(-2.5, -2.5, 2.5), Vector(-1, 0, 0), Vector(0, 1), Vector(0, 1));
      Vertices[9] := MakeExtendedMeshVertex(Vector(-2.5, 2.5, 2.5), Vector(-1, 0, 0), Vector(1, 1), Vector(1, 1));
      Vertices[10] := MakeExtendedMeshVertex(Vector(-2.5, 2.5, -2.5), Vector(-1, 0, 0), Vector(1, 0), Vector(1, 0));
      Vertices[11] := MakeExtendedMeshVertex(Vector(-2.5, -2.5, -2.5), Vector(-1, 0, 0), Vector(0, 0), Vector(0, 0));

      Vertices[12] := MakeExtendedMeshVertex(Vector(2.5, -2.5, -2.5), Vector(1, 0, 0), Vector(0, 0), Vector(0, 0));
      Vertices[13] := MakeExtendedMeshVertex(Vector(2.5, 2.5, -2.5), Vector(1, 0, 0), Vector(1, 0), Vector(1, 0));
      Vertices[14] := MakeExtendedMeshVertex(Vector(2.5, 2.5, 2.5), Vector(1, 0, 0), Vector(1, 1), Vector(1, 1));
      Vertices[15] := MakeExtendedMeshVertex(Vector(2.5, -2.5, 2.5), Vector(1, 0, 0), Vector(0, 1), Vector(0, 1));

      Vertices[16] := MakeExtendedMeshVertex(Vector(-2.5, -2.5, -2.5), Vector(0, 0, -1), Vector(0, 0), Vector(0, 0));
      Vertices[17] := MakeExtendedMeshVertex(Vector(-2.5, 2.5, -2.5), Vector(0, 0, -1), Vector(1, 0), Vector(1, 0));
      Vertices[18] := MakeExtendedMeshVertex(Vector(2.5, 2.5, -2.5), Vector(0, 0, -1), Vector(1, 1), Vector(1, 1));
      Vertices[19] := MakeExtendedMeshVertex(Vector(2.5, -2.5, -2.5), Vector(0, 0, -1), Vector(0, 1), Vector(0, 1));

      Vertices[20] := MakeExtendedMeshVertex(Vector(2.5, -2.5, 2.5), Vector(1, 0, 1), Vector(0, 1), Vector(0, 1));
      Vertices[21] := MakeExtendedMeshVertex(Vector(2.5, 2.5, 2.5), Vector(1, 0, 1), Vector(1, 1), Vector(1, 1));
      Vertices[22] := MakeExtendedMeshVertex(Vector(-2.5, 2.5, 2.5), Vector(1, 0, 1), Vector(1, 0), Vector(1, 0));
      Vertices[23] := MakeExtendedMeshVertex(Vector(-2.5, -2.5, 2.5), Vector(1, 0, 1), Vector(0, 0), Vector(0, 0));

      Triangles[0] := MakeTriangleVertexArray(0, 1, 2);
      Triangles[1] := MakeTriangleVertexArray(0, 2, 3);
      Triangles[2] := MakeTriangleVertexArray(4, 5, 6);
      Triangles[3] := MakeTriangleVertexArray(4, 6, 7);
      Triangles[4] := MakeTriangleVertexArray(8, 9, 10);
      Triangles[5] := MakeTriangleVertexArray(8, 10, 11);
      Triangles[6] := MakeTriangleVertexArray(12, 13, 14);
      Triangles[7] := MakeTriangleVertexArray(12, 14, 15);
      Triangles[8] := MakeTriangleVertexArray(16, 17, 18);
      Triangles[9] := MakeTriangleVertexArray(16, 18, 19);
      Triangles[10] := MakeTriangleVertexArray(20, 21, 22);
      Triangles[11] := MakeTriangleVertexArray(20, 22, 23);

      if i = 0 then
        begin
        Texture := TTexture.Create;
        Texture.FromFile('scenery/test.tga');
        BumpMap := TTexture.Create;
        BumpMap.FromFile('scenery/testbump.tga');
        end;
      end;
end;

destructor TRObjects.Free;
var
  i: Integer;
begin
  fTest.fMeshes[0].BumpMap.Free;
  fTest.fMeshes[0].Texture.Free;
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
  fShaderTesselation.Free;
  fTransformDepthShaderTesselation.Free;
  fSunShadowShaderTesselation.Free;
end;

end.