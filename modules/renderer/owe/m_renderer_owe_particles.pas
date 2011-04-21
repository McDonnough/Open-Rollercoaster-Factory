unit m_renderer_owe_particles;

interface

uses
  SysUtils, Classes, dglOpenGL, math, u_vectors, u_math, u_particles, u_scene, m_shdmng_class;

type
  TParticleGroupVBO = class
    protected
      fMaxParticlesInGroup: Integer;
      fVertexBuffer: GLUInt;
      fVBOPointer: Pointer;
      fGroup: TParticleGroup;
    public
      procedure Render;
      procedure Update;
      constructor Create(Group: TParticleGroup);
      destructor Free;
    end;

  TParticleGroupVBOAssoc = record
    Group: TParticleGroup;
    VBO: TParticleGroupVBO;
    end;

  TRParticles = class
    protected
      fParticleVBOs: Array of TParticleGroupVBOAssoc;
      fGeometryShader, fMaterialShader: TShader;
    public
      CurrentShader: TShader;
      property GeometryShader: TShader read fGeometryShader;
      property MaterialShader: TShader read fMaterialShader;
      procedure BindMaterial(Material: TMaterial);
      procedure Render(Group: TParticleGroup);
      procedure Prepare;
      procedure UpdateVBOs;
      procedure AddParticleGroup(Event: String; Data, Result: Pointer);
      procedure DeleteParticleGroup(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park, g_particles, m_varlist, u_events;

procedure TParticleGroupVBO.Update;
var
  CurrentParticle: TParticle;
  i: Integer;
begin
  glBindBufferARB(GL_ARRAY_BUFFER, fVertexBuffer);
  fVBOPointer := glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

  CurrentParticle := TParticle(fGroup.First);

  for i := 0 to Min(fGroup.Count, fMaxParticlesInGroup) - 1 do
    begin
    TVector4D((fVBOPointer + 240 * i + 00 + 000)^) := Vector(CurrentParticle.Position.X, CurrentParticle.Position.Y, CurrentParticle.Position.Z, CurrentParticle.Rotation);
    TVector4D((fVBOPointer + 240 * i + 16 + 000)^) := Vector(0, 0, -CurrentParticle.Size.X, -CurrentParticle.Size.Y);
    TVector3D((fVBOPointer + 240 * i + 32 + 000)^) := CurrentParticle.Velocity;
    TVector4D((fVBOPointer + 240 * i + 44 + 000)^) := CurrentParticle.Color;

    TVector4D((fVBOPointer + 240 * i + 00 + 060)^) := Vector(CurrentParticle.Position.X, CurrentParticle.Position.Y, CurrentParticle.Position.Z, CurrentParticle.Rotation);
    TVector4D((fVBOPointer + 240 * i + 16 + 060)^) := Vector(0, 1, -CurrentParticle.Size.X,  CurrentParticle.Size.Y);
    TVector3D((fVBOPointer + 240 * i + 32 + 060)^) := CurrentParticle.Velocity;
    TVector4D((fVBOPointer + 240 * i + 44 + 060)^) := CurrentParticle.Color;

    TVector4D((fVBOPointer + 240 * i + 00 + 120)^) := Vector(CurrentParticle.Position.X, CurrentParticle.Position.Y, CurrentParticle.Position.Z, CurrentParticle.Rotation);
    TVector4D((fVBOPointer + 240 * i + 16 + 120)^) := Vector(1, 1,  CurrentParticle.Size.X,  CurrentParticle.Size.Y);
    TVector3D((fVBOPointer + 240 * i + 32 + 120)^) := CurrentParticle.Velocity;
    TVector4D((fVBOPointer + 240 * i + 44 + 120)^) := CurrentParticle.Color;

    TVector4D((fVBOPointer + 240 * i + 00 + 180)^) := Vector(CurrentParticle.Position.X, CurrentParticle.Position.Y, CurrentParticle.Position.Z, CurrentParticle.Rotation);
    TVector4D((fVBOPointer + 240 * i + 16 + 180)^) := Vector(1, 0,  CurrentParticle.Size.X, -CurrentParticle.Size.Y);
    TVector3D((fVBOPointer + 240 * i + 32 + 180)^) := CurrentParticle.Velocity;
    TVector4D((fVBOPointer + 240 * i + 44 + 180)^) := CurrentParticle.Color;

    CurrentParticle := TParticle(CurrentParticle.Next);
    end;
  glUnMapBuffer(GL_ARRAY_BUFFER);

  glBindBufferARB(GL_ARRAY_BUFFER, 0);
end;

procedure TParticleGroupVBO.Render;
begin
  glBindBufferARB(GL_ARRAY_BUFFER, fVertexBuffer);

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glVertexPointer(4, GL_FLOAT, 60, Pointer(0));
  glTexCoordPointer(4, GL_FLOAT, 60, Pointer(16));
  glNormalPointer(GL_FLOAT, 60, Pointer(32));
  glColorPointer(4, GL_FLOAT, 60, Pointer(44));

  glDrawArrays(GL_QUADS, 0, 4 * Min(fGroup.Count, fMaxParticlesInGroup));

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);

  glBindBufferARB(GL_ARRAY_BUFFER, 0);
end;

constructor TParticleGroupVBO.Create(Group: TParticleGroup);
var
  i: Integer;
begin
  fGroup := Group;

  glGenBuffers(1, @fVertexBuffer);

  fMaxParticlesInGroup := Ceil(Group.Lifetime * Power(2, Group.LifetimeVariance) / (Group.GenerationTime * Power(2, -Group.GenerationTimeVariance)));
  glBindBufferARB(GL_ARRAY_BUFFER, fVertexBuffer);
  glBufferData(GL_ARRAY_BUFFER, 4 * fMaxParticlesInGroup * 60, nil, GL_DYNAMIC_DRAW);
  glBindBufferARB(GL_ARRAY_BUFFER, 0);
  Update;
end;

destructor TParticleGroupVBO.Free;
begin
  glDeleteBuffers(1, @fVertexBuffer);
end;



procedure TRParticles.UpdateVBOs;
var
  i, j: Integer;
begin
  for i := 0 to high(fParticleVBOs) do
    fParticleVBOs[i].VBO.Update;
end;

procedure TRParticles.BindMaterial(Material: TMaterial);
var
  Spec: TVector4D;
begin
  with Material do
    begin
    if Texture <> nil then
      Texture.Bind(0)
    else
      begin
      ModuleManager.ModTexMng.ActivateTexUnit(0);
      ModuleManager.ModTexMng.BindTexture(-1);
      end;
    Spec := Vector(Specularity, Reflectivity, 0, 0);
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, @Color.X);
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, @Emission.X);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, @Spec.X);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, @Hardness);
    end;
end;

procedure TRParticles.Render(Group: TParticleGroup);
var
  i: Integer;
  CurrentParticle: TParticle;
begin
  glDisable(GL_CULL_FACE);
  glDepthMask(false);

  CurrentShader.Bind;
  CurrentShader.UniformF('MaskOffset', ModuleManager.ModRenderer.RObjects.CurrentMaterialCount / 16, 0);
  CurrentShader.UniformI('MaterialID', (ModuleManager.ModRenderer.RObjects.CurrentMaterialCount shr 16) and $FF, (ModuleManager.ModRenderer.RObjects.CurrentMaterialCount shr 8) and $FF, ModuleManager.ModRenderer.RObjects.CurrentMaterialCount and $FF);

  for i := 0 to high(fParticleVBOs) do
    if fParticleVBOs[i].Group = Group then
      begin
      BindMaterial(Group.Material);
      fParticleVBOs[i].VBO.Render;
      end;
  
  CurrentShader.Unbind;

  glDepthMask(true);
  glColor4f(1, 1, 1, 1);
  glEnable(GL_CULL_FACE);
end;

procedure TRParticles.Prepare;
var
  Matrix: Array[0..15] of Single;
  BillboardMatrix: TMatrix4D;
begin
  BillboardMatrix := RotationMatrix(-ModuleManager.ModCamera.ActiveCamera.Rotation.Y, Vector(0, 1, 0));
  BillboardMatrix := BillboardMatrix * RotationMatrix(-ModuleManager.ModCamera.ActiveCamera.Rotation.X, Vector(1, 0, 0));
  BillboardMatrix := BillboardMatrix * RotationMatrix(-ModuleManager.ModCamera.ActiveCamera.Rotation.Z, Vector(0, 0, 1));

  MakeOGLCompatibleMatrix(BillboardMatrix, @Matrix[0]);

  CurrentShader.Bind;
  CurrentShader.UniformF('FogColor', ModuleManager.ModRenderer.FogColor);
  CurrentShader.UniformF('FogStrength', ModuleManager.ModRenderer.FogStrength);
  CurrentShader.UniformF('WaterHeight', ModuleManager.ModRenderer.RWater.CurrentHeight);
  CurrentShader.UniformF('WaterRefractionMode', ModuleManager.ModRenderer.FogRefractMode);
  CurrentShader.UniformMatrix4D('BillboardMatrix', @Matrix[0]);
  CurrentShader.UniformF('ViewPoint', ModuleManager.ModRenderer.ViewPoint.X, ModuleManager.ModRenderer.ViewPoint.Y, ModuleManager.ModRenderer.ViewPoint.Z);
  CurrentShader.Unbind;
end;

procedure TRParticles.AddParticleGroup(Event: String; Data, Result: Pointer);
begin
  SetLength(fParticleVBOs, length(fParticleVBOs) + 1);
  fParticleVBOs[high(fParticleVBOs)].Group := TParticleGroup(Data);
  fParticleVBOs[high(fParticleVBOs)].VBO := TParticleGroupVBO.Create(TParticleGroup(Data));
end;

procedure TRParticles.DeleteParticleGroup(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fParticleVBOs) do
    if Pointer(fParticleVBOs[i].Group) = Data then
      begin
      fParticleVBOs[i].VBO.Free;
      fParticleVBOs[i] := fParticleVBOs[high(fParticleVBOs)];
      SetLength(fParticleVBOs, length(fParticleVBOs) - 1);
      exit;
      end;
end;

constructor TRParticles.Create;
begin
  writeln('Hint: Initializing particle renderer');

  EventManager.AddCallback('TParticleManager.AddGroup', @AddParticleGroup);
  EventManager.AddCallback('TParticleManager.DeleteGroup', @DeleteParticleGroup);

  fGeometryShader := TShader.Create('orcf-world-engine/scene/particles/particles.vs', 'orcf-world-engine/scene/particles/particles-geometry.fs');
  fGeometryShader.UniformI('Texture', 0);
  fGeometryShader.UniformI('TransparencyMask', 7);
  fGeometryShader.UniformF('MaskSize', ModuleManager.ModRenderer.TransparencyMask.Width, ModuleManager.ModRenderer.TransparencyMask.Height);

  fMaterialShader := TShader.Create('orcf-world-engine/scene/particles/particles.vs', 'orcf-world-engine/scene/particles/particles-material.fs');
  fMaterialShader.UniformI('Texture', 0);
  fMaterialShader.UniformI('NormalMap', 5);
  fMaterialShader.UniformI('ReflectionMap', 3);
  fMaterialShader.UniformI('MaterialMap', 6);
  fMaterialShader.UniformI('LightTexture', 7);
end;

destructor TRParticles.Free;
var
  i: Integer;
begin
  fMaterialShader.Free;
  fGeometryShader.Free;

  EventManager.RemoveCallback(@AddParticleGroup);
  EventManager.RemoveCallback(@DeleteParticleGroup);

  for i := 0 to high(fParticleVBOs) do
    fParticleVBOs[i].VBO.Free;
end;

end.