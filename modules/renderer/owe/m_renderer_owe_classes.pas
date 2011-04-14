unit m_renderer_owe_classes;

interface

uses
  SysUtils, Classes, DGLOpenGL, u_vectors, u_math, m_texmng_class, u_scene;

type
  TVBO = class
    protected
      fVBO: GLUInt;
      fFormat: GLEnum;
      fOfsMap: TVector4D;
      fDataSize: Integer;
      fVertexCount: Integer;
      fVBOPointer: Pointer;
      fPolygonType: GLEnum;
      fLastMode: GLEnum;

      procedure Map(Mode: GLEnum);
      procedure UnMap;

      function getVertex(ID: Integer): TVector3D;
      function getColor(ID: Integer): TVector4D;
      function getNormal(ID: Integer): TVector3D;
      function getTexCoord(ID: Integer): TVector2D;

      procedure setVertex(ID: Integer; Vec: TVector3D);
      procedure setColor(ID: Integer; Vec: TVector4D);
      procedure setNormal(ID: Integer; Vec: TVector3D);
      procedure setTexCoord(ID: Integer; Vec: TVector2D);
    public
      property Vertices[ID: Integer]: TVector3D read getVertex write setVertex;
      property Colors[ID: Integer]: TVector4D read getColor write setColor;
      property Normals[ID: Integer]: TVector3D read getNormal write setNormal;
      property TexCoords[ID: Integer]: TVector2D read getTexCoord write setTexCoord;
      procedure Bind;
      procedure Render;
      procedure Unbind;
      constructor Create(VertCount: Integer; Format, PolygonType: GLEnum);
      destructor Free;
    end;

  TObjectVBOVertex = record
    Vertex: TVector3D;
    TexCoord: TVector2D;
    Normal: TVector3D;
    Color: TVector4D;
    end;

  TObjectVBO = class
    protected
      fVertexData: Array of TObjectVBOVertex;
      fIndexData: Array of TTriangleIndexList;
      fMeshVertexIDList: Array of Integer;
      fMeshTextureVertexIDList: Array of Integer;
      fVerticesChanged, fTrianglesChanged: Array of Boolean;
      fChangedVertices, fChangedTriangles: Array of DWord;
      fChangedVerticesCount, fChangedTrianglesCount: DWord;
      fVertices, fTriangles: DWord;
      fVertexBuffer, fIndexBuffer: GLUInt;
      fVBOPointer, fIndexPointer: Pointer;
      fLastMode: GLEnum;
      fMesh: TGeoMesh;
      fRadius: Single;
      procedure Map(Mode: GLEnum);
      procedure UnMap;

      function getVertex(ID: DWord): TVector3D;
      function getColor(ID: DWord): TVector4D;
      function getNormal(ID: DWord): TVector3D;
      function getTexCoord(ID: DWord): TVector2D;

      procedure setVertex(ID: DWord; Vec: TVector3D);
      procedure setColor(ID: DWord; Vec: TVector4D);
      procedure setNormal(ID: DWord; Vec: TVector3D);
      procedure setTexCoord(ID: DWord; Vec: TVector2D);

      function GetIndicies(ID: DWord): TTriangleIndexList;
      procedure SetIndicies(ID: DWord; Indicies: TTriangleIndexList);

      procedure ApplyChanges;
    public
      property Vertices[ID: DWord]: TVector3D read getVertex write setVertex;
      property Colors[ID: DWord]: TVector4D read getColor write setColor;
      property Normals[ID: DWord]: TVector3D read getNormal write setNormal;
      property TexCoords[ID: DWord]: TVector2D read getTexCoord write setTexCoord;
      property Indicies[ID: DWord]: TTriangleIndexList read GetIndicies write SetIndicies;
      property Radius: Single read fRadius;
      procedure LookForChanges;
      procedure Bind;
      procedure Render;
      procedure Unbind;
      constructor Create(Mesh: TGeoMesh);
      constructor Create(VertexCount, FaceCount: DWord; Mesh: TGeoMesh = nil);
      destructor Free;
    end;


  TFBO = class
    protected
      fTextures: Array of TTexture;
      fID, fDepthBuffer: GLUInt;
      fSizeX, fSizeY: Integer;
      Buffers: Array of GLEnum;
      class procedure UnbindCurrent;
      function getTexture(I: Integer): TTexture;
    public
      property Textures[I: Integer]: TTexture read getTexture;
      property Width: Integer read fSizeX;
      property Height: Integer read fSizeY;
      procedure Bind;
      procedure Unbind;
      procedure CopyFrom(Texture: TTexture);
      procedure AddTexture(TexFormat, MinFilter, MagFilter: GLEnum);
      constructor Create(SizeX, SizeY: Integer; DepthBuffer: Boolean);
      destructor Free;
    end;

  TOcclusionQuery = class
    protected
      fResult: GLInt;
      fQuery: GLUInt;
    public
      property Result: GLInt read fResult;
      procedure StartCounter;
      procedure EndCounter;
      constructor Create;
      destructor Free;
    end;

  TDisplayList = class
    protected
      fList: GLUInt;
    public
      procedure StartCompiling;
      procedure EndCompiling;
      procedure Render;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist;

const
  OBJECT_VBO_VERTEX_OFFSET   =  0 * SizeOf(Single);
  OBJECT_VBO_TEXCOORD_OFFSET =  3 * SizeOf(Single);
  OBJECT_VBO_NORMAL_OFFSET   =  5 * SizeOf(Single);
  OBJECT_VBO_COLOR_OFFSET    =  8 * SizeOf(Single);
  OBJECT_VBO_VERTEX_SIZE     = 12 * SizeOf(Single);

var
  fCurrentFBO: TFBO = nil;

procedure TVBO.Map(Mode: GLEnum);
begin
  if (fVBOPointer = nil) or (fLastMode <> Mode) then
    begin
    Bind;
    if fVBOPointer <> nil then
      Unmap;
    fVBOPointer := glMapBuffer(GL_ARRAY_BUFFER, Mode);
    fLastMode := Mode;
    end;
end;

procedure TVBO.UnMap;
begin
  if fVBOPointer <> nil then
    begin
    fVBOPointer := nil;
    glUnMapBuffer(GL_ARRAY_BUFFER);
    end;
end;

function TVBO.getVertex(ID: Integer): TVector3D;
begin
  if (fOfsMap.X = -1) or (ID >= fVertexCount) or (ID < 0) then
    exit(Vector(0, 0, 0));
  Map(GL_READ_ONLY);
  Result := TVector3D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.X)))^);
end;

function TVBO.getColor(ID: Integer): TVector4D;
begin
  if (fOfsMap.X = -1) or (ID >= fVertexCount) or (ID < 0) then
    exit(Vector(0, 0, 0, 0));
  Map(GL_READ_ONLY);
  Result := TVector4D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.Y)))^);
end;

function TVBO.getNormal(ID: Integer): TVector3D;
begin
  if (fOfsMap.X = -1) or (ID >= fVertexCount) or (ID < 0) then
    exit(Vector(0, 0, 0));
  Map(GL_READ_ONLY);
  Result := TVector3D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.Z)))^);
end;

function TVBO.getTexCoord(ID: Integer): TVector2D;
begin
  if (fOfsMap.X = -1) or (ID >= fVertexCount) or (ID < 0) then
    exit(Vector(0, 0));
  Map(GL_READ_ONLY);
  Result := TVector2D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.W)))^);
end;


procedure TVBO.setVertex(ID: Integer; Vec: TVector3D);
begin
  if (fOfsMap.X = -1) or (ID >= fVertexCount) or (ID < 0) then
    exit;
  Map(GL_WRITE_ONLY);
  TVector3D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.X)))^) := Vec;
end;

procedure TVBO.setColor(ID: Integer; Vec: TVector4D);
begin
  if (fOfsMap.X = -1) or (ID >= fVertexCount) or (ID < 0) then
    exit;
  Map(GL_WRITE_ONLY);
  TVector4D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.Y)))^) := Vec;
end;

procedure TVBO.setNormal(ID: Integer; Vec: TVector3D);
begin
  if (fOfsMap.X = -1) or (ID >= fVertexCount) or (ID < 0) then
    exit;
  Map(GL_WRITE_ONLY);
  TVector3D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.Z)))^) := Vec;
end;

procedure TVBO.setTexCoord(ID: Integer; Vec: TVector2D);
begin
  if (fOfsMap.X = -1) or (ID >= fVertexCount) or (ID < 0) then
    exit;
  Map(GL_WRITE_ONLY);
  TVector2D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.W)))^) := Vec;
end;

procedure TVBO.Bind;
begin
  glBindBufferARB(GL_ARRAY_BUFFER, fVBO);
  glEnableClientState(GL_VERTEX_ARRAY);
end;

procedure TVBO.Render;
begin
  Bind;
  glInterleavedArrays(fFormat, fDataSize, nil);
  glDrawArrays(fPolygonType, 0, fVertexCount);
end;

procedure TVBO.Unbind;
begin
  UnMap;
  glDisableClientState(GL_VERTEX_ARRAY);
  glBindBufferARB(GL_ARRAY_BUFFER, 0);
end;

constructor TVBO.Create(VertCount: Integer; Format, PolygonType: GLEnum);
begin
  fFormat := Format;
  fPolygonType := PolygonType;
  fVertexCount := VertCount;
  fVBOPointer := nil;
  glGenBuffers(1, @fVBO);
  case Format of
    GL_V3F:
      begin
      fOfsMap := Vector(0, -1, -1, -1);
      fDataSize := SizeOf(TVector3D);
      end;
    GL_N3F_V3F:
      begin
      fOfsMap := Vector(3 * SizeOf(Single), -1, 0, -1);
      fDataSize := 2 * SizeOf(TVector3D);
      end;
    GL_C4F_N3F_V3F:
      begin
      fOfsMap := Vector(7 * SizeOf(Single), 0, 4 * SizeOf(Single), -1);
      fDataSize := SizeOf(TVector4D) + 2 * SizeOf(TVector3D);
      end;
    GL_T2F_V3F:
      begin
      fOfsMap := Vector(2 * SizeOf(Single), -1, -1, 0);
      fDataSize := SizeOf(TVector2D) + SizeOf(TVector3D);
      end;
    GL_T2F_N3F_V3F:
      begin
      fOfsMap := Vector(5 * SizeOf(Single), -1, 2 * SizeOf(Single), 0);
      fDataSize := SizeOf(TVector2D) + 2 * SizeOf(TVector3D);
      end;
    GL_T2F_C4F_N3F_V3F:
      begin
      fOfsMap := Vector(9 * SizeOf(Single), 2 * SizeOf(Single), 6 * SizeOf(Single), 0);
      fDataSize := SizeOf(TVector2D) + SizeOf(TVector4D) + 2 * SizeOf(TVector3D);
      end;
    else
      ModuleManager.ModLog.AddError('Unknown Vertex Format');
    end;
  Bind;
  glBufferDataARB(GL_ARRAY_BUFFER, fVertexCount * fDataSize, nil, GL_DYNAMIC_DRAW);
end;

destructor TVBO.Free;
begin
  Unbind;
  glDeleteBuffers(1, @fVBO);
end;



procedure TObjectVBO.Map(Mode: GLEnum);
begin
  if (fVBOPointer = nil) or (fLastMode <> Mode) then
    begin
    Bind;
    if fVBOPointer <> nil then
      Unmap;
    fVBOPointer := glMapBuffer(GL_ARRAY_BUFFER, Mode);
    fIndexPointer := glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, Mode);
    fLastMode := Mode;
    end;
end;

procedure TObjectVBO.UnMap;
begin
  if fVBOPointer <> nil then
    begin
    fVBOPointer := nil;
    fIndexPointer := nil;
    glUnMapBuffer(GL_ELEMENT_ARRAY_BUFFER);
    glUnMapBuffer(GL_ARRAY_BUFFER);
    end;
end;

function TObjectVBO.getVertex(ID: DWord): TVector3D;
begin
  Result := fVertexData[ID].Vertex;
end;

function TObjectVBO.getColor(ID: DWord): TVector4D;
begin
  Result := fVertexData[ID].Color;
end;

function TObjectVBO.getNormal(ID: DWord): TVector3D;
begin
  Result := fVertexData[ID].Normal;
end;

function TObjectVBO.getTexCoord(ID: DWord): TVector2D;
begin
  Result := fVertexData[ID].TexCoord;
end;

procedure TObjectVBO.setVertex(ID: DWord; Vec: TVector3D);
begin
  if VecLengthNoRoot(Vec) > fRadius * fRadius then
    fRadius := VecLength(Vec);
  fVertexData[ID].Vertex := Vec;
  if not fVerticesChanged[ID] then
    begin
    fVerticesChanged[ID] := true;
    fChangedVertices[fChangedVerticesCount] := ID;
    inc(fChangedVerticesCount);
    end;
end;

procedure TObjectVBO.setColor(ID: DWord; Vec: TVector4D);
begin
  fVertexData[ID].Color := Vec;
  if not fVerticesChanged[ID] then
    begin
    fVerticesChanged[ID] := true;
    fChangedVertices[fChangedVerticesCount] := ID;
    inc(fChangedVerticesCount);
    end;
end;

procedure TObjectVBO.setNormal(ID: DWord; Vec: TVector3D);
begin
  fVertexData[ID].Normal := Vec;
  if not fVerticesChanged[ID] then
    begin
    fVerticesChanged[ID] := true;
    fChangedVertices[fChangedVerticesCount] := ID;
    inc(fChangedVerticesCount);
    end;
end;

procedure TObjectVBO.setTexCoord(ID: DWord; Vec: TVector2D);
begin
  fVertexData[ID].TexCoord := Vec;
  if not fVerticesChanged[ID] then
    begin
    fVerticesChanged[ID] := true;
    fChangedVertices[fChangedVerticesCount] := ID;
    inc(fChangedVerticesCount);
    end;
end;

function TObjectVBO.GetIndicies(ID: DWord): TTriangleIndexList;
begin
  Result := TriangleIndexList(fIndexData[ID, 0], fIndexData[ID, 1], fIndexData[ID, 2]);
end;

procedure TObjectVBO.SetIndicies(ID: DWord; Indicies: TTriangleIndexList);
begin
  fIndexData[ID, 0] := Indicies[0];
  fIndexData[ID, 1] := Indicies[1];
  fIndexData[ID, 2] := Indicies[2];
  if not fTrianglesChanged[ID] then
    begin
    fTrianglesChanged[ID] := True;
    fChangedTriangles[fChangedTrianglesCount] := ID;
    inc(fChangedTrianglesCount);
    end;
end;

procedure TObjectVBO.LookForChanges;
var
  i: Integer;
begin
  for i := 0 to high(fVertexData) do
    if fMesh.Vertices[fMeshVertexIDList[i]].Changed then
      begin
      Vertices[i] := fMesh.Vertices[fMeshVertexIDList[i]].Position;
      Colors[i] := fMesh.Vertices[fMeshVertexIDList[i]].Color;
      TexCoords[i] := fMesh.TextureVertices[fMeshTextureVertexIDList[i]].Position;
      if fMesh.Vertices[fMeshVertexIDList[i]].UseFaceNormal then
        Normals[i] := fMesh.Faces[i div 3].FaceNormal // dirty, minor code changes will crash this
      else
        Normals[i] := fMesh.Vertices[fMeshVertexIDList[i]].VertexNormal;
      end;
  for i := 0 to high(fVertexData) do
    fMesh.Vertices[fMeshVertexIDList[i]].Changed := false;
end;

procedure TObjectVBO.ApplyChanges;
var
  i: Integer;
begin
  if (fChangedTrianglesCount = 0) and (fChangedVerticesCount = 0) then
    exit;
  Map(GL_WRITE_ONLY);
  for i := 0 to fChangedVerticesCount - 1 do
    begin
    TVector3D((fVBOPointer + OBJECT_VBO_VERTEX_SIZE * fChangedVertices[i] + OBJECT_VBO_VERTEX_OFFSET)^) := fVertexData[fChangedVertices[i]].Vertex;
    TVector2D((fVBOPointer + OBJECT_VBO_VERTEX_SIZE * fChangedVertices[i] + OBJECT_VBO_TEXCOORD_OFFSET)^) := fVertexData[fChangedVertices[i]].TexCoord;
    TVector3D((fVBOPointer + OBJECT_VBO_VERTEX_SIZE * fChangedVertices[i] + OBJECT_VBO_NORMAL_OFFSET)^) := fVertexData[fChangedVertices[i]].Normal;
    TVector4D((fVBOPointer + OBJECT_VBO_VERTEX_SIZE * fChangedVertices[i] + OBJECT_VBO_COLOR_OFFSET)^) := fVertexData[fChangedVertices[i]].Color;
    fVerticesChanged[fChangedVertices[i]] := false;
    end;
  for i := 0 to fChangedTrianglesCount - 1 do
    begin
    DWord((fIndexPointer + 12 * fChangedTriangles[i] + 0)^) := fIndexData[fChangedTriangles[i], 0];
    DWord((fIndexPointer + 12 * fChangedTriangles[i] + 4)^) := fIndexData[fChangedTriangles[i], 1];
    DWord((fIndexPointer + 12 * fChangedTriangles[i] + 8)^) := fIndexData[fChangedTriangles[i], 2];
    fTrianglesChanged[fChangedTriangles[i]] := false;
    end;
  Unmap;
  fChangedTrianglesCount := 0;
  fChangedVerticesCount := 0;
end;

procedure TObjectVBO.Bind;
begin
  if fMesh <> nil then
    LookForChanges;
  glBindBufferARB(GL_ARRAY_BUFFER, fVertexBuffer);
  glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER, fIndexBuffer);
end;

procedure TObjectVBO.Render;
begin
  ApplyChanges;
  Bind;
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glVertexPointer(3, GL_FLOAT, OBJECT_VBO_VERTEX_SIZE, Pointer(OBJECT_VBO_VERTEX_OFFSET));
  glTexCoordPointer(2, GL_FLOAT, OBJECT_VBO_VERTEX_SIZE, Pointer(OBJECT_VBO_TEXCOORD_OFFSET));
  glNormalPointer(GL_FLOAT, OBJECT_VBO_VERTEX_SIZE, Pointer(OBJECT_VBO_NORMAL_OFFSET));
  glColorPointer(4, GL_FLOAT, OBJECT_VBO_VERTEX_SIZE, Pointer(OBJECT_VBO_COLOR_OFFSET));

  glDrawElements(GL_TRIANGLES, 3 * fTriangles, GL_UNSIGNED_INT, nil);

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
end;

procedure TObjectVBO.Unbind;
begin
  UnMap;
  glBindBufferARB(GL_ARRAY_BUFFER, 0);
  glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER, 0);
end;

constructor TObjectVBO.Create(Mesh: TGeoMesh);
var
  i, j, k, l, VC: Integer;
begin
  SetLength(fMeshVertexIDList, 3 * Length(Mesh.Faces));
  SetLength(fMeshTextureVertexIDList, 3 * Length(Mesh.Faces));


  Create(3 * Length(Mesh.Faces), Length(Mesh.Faces), Mesh);
  for i := 0 to high(Mesh.Faces) do
    begin
    Indicies[i] := TriangleIndexList(3 * i, 3 * i + 1, 3 * i + 2);
    for j := 0 to 2 do
      begin
      fMeshVertexIDList[3 * i + j] := Mesh.Faces[i].Vertices[j];
      fMeshTextureVertexIDList[3 * i + j] := Mesh.Faces[i].TexCoords[j];
      Vertices[3 * i + j] := Mesh.Vertices[Mesh.Faces[i].Vertices[j]].Position;
      if Mesh.Vertices[Mesh.Faces[i].Vertices[j]].UseFaceNormal then
        Normals[3 * i + j] := Mesh.Faces[i].FaceNormal
      else
        Normals[3 * i + j] := Mesh.Vertices[Mesh.Faces[i].Vertices[j]].VertexNormal;
      Colors[3 * i + j] := Mesh.Vertices[Mesh.Faces[i].Vertices[j]].Color;
      TexCoords[3 * i + j] := Mesh.TextureVertices[Mesh.Faces[i].TexCoords[j]].Position;
      end;
    end;
end;

constructor TObjectVBO.Create(VertexCount, FaceCount: DWord; Mesh: TGeoMesh = nil);
var
  i: Integer;
begin
  fRadius := 0;
  fMesh := Mesh;
  fVertices := VertexCount;
  fTriangles := FaceCount;
  SetLength(fVertexData, VertexCount);
  SetLength(fVerticesChanged, VertexCount);
  setLength(fChangedVertices, VertexCount);
  SetLength(fIndexData, FaceCount);
  SetLength(fTrianglesChanged, FaceCount);
  SetLength(fChangedTriangles, FaceCount);
  glGenBuffers(1, @fVertexBuffer);
  glGenBuffers(1, @fIndexBuffer);
  Bind;
  glBufferData(GL_ARRAY_BUFFER, fVertices * OBJECT_VBO_VERTEX_SIZE, nil, GL_DYNAMIC_DRAW);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, 3 * fTriangles * 4, nil, GL_DYNAMIC_DRAW);
  for i := 0 to VertexCount - 1 do
    begin
    Vertices[i] := Vector(0, 0, 0);
    TexCoords[i] := Vector(0, 0);
    Normals[i] := Vector(0, 0, 0);
    Colors[i] := Vector(0, 0, 0, 0);
    end;
  for i := 0 to FaceCount - 1 do
    Indicies[i] := TriangleIndexList(0, 0, 0);
  ApplyChanges;
end;

destructor TObjectVBO.Free;
begin
  Unbind;
  glDeleteBuffers(1, @fVertexBuffer);
  glDeleteBuffers(1, @fIndexBuffer);
end;



class procedure TFBO.UnbindCurrent;
begin
  if fCurrentFBO <> nil then
    fCurrentFBO.Unbind;
end;

function TFBO.getTexture(I: Integer): TTexture;
begin
  Result := nil;
  if (i >= 0) and (i <= high(fTextures)) then
    Result := fTextures[i];
end;

procedure TFBO.Bind;
begin
  UnbindCurrent;
  fCurrentFBO := self;
  glPushAttrib(GL_VIEWPORT_BIT or GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, Width, Height);
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fID);
  if length(Buffers) > 1 then
    glDrawBuffers(length(Buffers), @Buffers[0]);
end;

procedure TFBO.UnBind;
begin
  if fCurrentFBO <> nil then
    begin
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glPopAttrib;
    end;
  fCurrentFBO := nil;
end;

procedure TFBO.CopyFrom(Texture: TTexture);
begin
  Bind;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  Texture.Bind(0);
  ModuleManager.ModRenderer.FullscreenShader.Bind;
  glBegin(GL_QUADS);
    glVertex2f(-1, -1);
    glVertex2f( 1, -1);
    glVertex2f( 1,  1);
    glVertex2f(-1,  1);
  glEnd;
  Texture.UnBind;
  ModuleManager.ModRenderer.FullscreenShader.UnBind;
  UnBind;
end;

procedure TFBO.AddTexture(TexFormat, MinFilter, MagFilter: GLEnum);
var
  i: Integer;
begin
  Bind;
  setLength(fTextures, length(fTextures) + 1);
  i := high(fTextures);
  fTextures[i] := TTexture.Create;
  fTextures[i].CreateNew(fSizeX, fSizeY, TexFormat);
  fTextures[i].SetFilter(MinFilter, MagFilter);
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT + i, GL_TEXTURE_2D, fTextures[i].GetRealTexID, 0);
  fTextures[i].Unbind;
  SetLength(Buffers, length(Buffers) + 1);
  Buffers[high(Buffers)] := GL_COLOR_ATTACHMENT0_EXT + i;
end;

constructor TFBO.Create(SizeX, SizeY: Integer; DepthBuffer: Boolean);
begin
  fSizeX := SizeX;
  fSizeY := SizeY;
  glGenFramebuffersEXT(1, @fID);
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fID);
  fDepthBuffer := 0;
  if DepthBuffer then
    begin
    glGenRenderbuffersEXT(1, @fDepthBuffer);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, fDepthBuffer);
    glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, {GL_DEPTH_STENCIL_EXT}GL_DEPTH_COMPONENT, SizeX, SizeY);
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, fDepthBuffer);
//     glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_STENCIL_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, fDepthBuffer);
    end;
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
end;

destructor TFBO.Free;
var
  i: Integer;
begin
  for i := 0 to high(fTextures) do
    fTextures[i].Free;
  glDeleteFramebuffersEXT(1, @fID);
  if fDepthBuffer <> 0 then
    glDeleteRenderbuffersEXT(1, @fDepthBuffer);
end;



procedure TOcclusionQuery.StartCounter;
begin
  glBeginQueryARB(GL_SAMPLES_PASSED_ARB, fQuery)
end;

procedure TOcclusionQuery.EndCounter;
begin
  glEndQueryARB(GL_SAMPLES_PASSED_ARB);
  glGetQueryObjectivARB(fQuery, GL_QUERY_RESULT_ARB, @fResult);
end;

constructor TOcclusionQuery.Create;
begin
  glGenQueriesARB(1, @fQuery);
end;

destructor TOcclusionQuery.Free;
begin
  glDeleteQueries(1, @fQuery);
end;


procedure TDisplayList.StartCompiling;
begin
  glNewList(fList, GL_COMPILE);
end;

procedure TDisplayList.EndCompiling;
begin
  glEndList;
end;

procedure TDisplayList.Render;
begin
  glCallList(fList);
end;

constructor TDisplayList.Create;
begin
  fList := glGenLists(1);
end;

destructor TDisplayList.Free;
begin
  glDeleteLists(1, fList);
end;

end.