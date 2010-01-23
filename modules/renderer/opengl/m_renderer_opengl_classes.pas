unit m_renderer_opengl_classes;

interface

uses
  SysUtils, Classes, DGLOpenGL, u_vectors, u_math;

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

implementation

uses
  m_varlist;

procedure TVBO.Map(Mode: GLEnum);
begin
  if (fVBOPointer = nil) or (fLastMode <> Mode) then
    begin
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
  if fOfsMap.X = -1 then
    exit(Vector(0, 0, 0));
  Map(GL_READ_ONLY);
  Result := TVector3D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.X)))^);
end;

function TVBO.getColor(ID: Integer): TVector4D;
begin
  if fOfsMap.Y = -1 then
    exit(Vector(0, 0, 0, 0));
  Map(GL_READ_ONLY);
  Result := TVector4D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.Y)))^);
end;

function TVBO.getNormal(ID: Integer): TVector3D;
begin
  if fOfsMap.Z = -1 then
    exit(Vector(0, 0, 0));
  Map(GL_READ_ONLY);
  Result := TVector3D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.Z)))^);
end;

function TVBO.getTexCoord(ID: Integer): TVector2D;
begin
  if fOfsMap.W = -1 then
    exit(Vector(0, 0));
  Map(GL_READ_ONLY);
  Result := TVector2D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.W)))^);
end;


procedure TVBO.setVertex(ID: Integer; Vec: TVector3D);
begin
  if fOfsMap.X = -1 then
    exit;
  Map(GL_WRITE_ONLY);
  TVector3D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.X)))^) := Vec;
end;

procedure TVBO.setColor(ID: Integer; Vec: TVector4D);
begin
  if fOfsMap.Y = -1 then
    exit;
  Map(GL_WRITE_ONLY);
  TVector4D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.Y)))^) := Vec;
end;

procedure TVBO.setNormal(ID: Integer; Vec: TVector3D);
begin
  if fOfsMap.Z = -1 then
    exit;
  Map(GL_WRITE_ONLY);
  TVector3D(Pointer(PtrUInt(fVBOPointer) + PtrUInt(ID * fDataSize + Round(fOfsMap.Z)))^) := Vec;
end;

procedure TVBO.setTexCoord(ID: Integer; Vec: TVector2D);
begin
  if fOfsMap.W = -1 then
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
//   Unmap;
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
      ModuleManager.ModLog.AddError('Unknown Vertex Format', 'm_renderer_opengl_classes', 103);
    end;
  Bind;
  glBufferDataARB(GL_ARRAY_BUFFER, fVertexCount * fDataSize, nil, GL_DYNAMIC_DRAW);
end;

destructor TVBO.Free;
begin
  Unbind;
  glDeleteBuffers(1, @fVBO);
end;

end.