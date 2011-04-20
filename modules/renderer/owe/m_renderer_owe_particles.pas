unit m_renderer_owe_particles;

interface

uses
  SysUtils, Classes, dglOpenGL, math, u_vectors, u_math, u_particles, u_scene, m_shdmng_class;

type
  TRParticles = class
    protected
      fGeometryShader, fMaterialShader: TShader;
    public
      CurrentShader: TShader;
      property GeometryShader: TShader read fGeometryShader;
      property MaterialShader: TShader read fMaterialShader;
      procedure BindMaterial(Material: TMaterial);
      procedure Render(Group: TParticleGroup);
      procedure Render;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park, g_particles, m_varlist;

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
  CurrentParticle: TParticle;
begin
  BindMaterial(Group.Material);
  glBegin(GL_QUADS);
  CurrentParticle := TParticle(Group.Last);
  while CurrentParticle <> nil do
    begin
    glColor4f(CurrentParticle.Color.X, CurrentParticle.Color.Y, CurrentParticle.Color.Z, CurrentParticle.Color.W);
    glNormal3f(CurrentParticle.Velocity.X, CurrentParticle.Velocity.Y, CurrentParticle.Velocity.Z);
    glTexCoord4f(0, 0, -CurrentParticle.Size.X, -CurrentParticle.Size.Y); glVertex4f(CurrentParticle.Position.X, CurrentParticle.Position.Y, CurrentParticle.Position.Z, CurrentParticle.Rotation);
    glTexCoord4f(0, 1, -CurrentParticle.Size.X,  CurrentParticle.Size.Y); glVertex4f(CurrentParticle.Position.X, CurrentParticle.Position.Y, CurrentParticle.Position.Z, CurrentParticle.Rotation);
    glTexCoord4f(1, 1,  CurrentParticle.Size.X,  CurrentParticle.Size.Y); glVertex4f(CurrentParticle.Position.X, CurrentParticle.Position.Y, CurrentParticle.Position.Z, CurrentParticle.Rotation);
    glTexCoord4f(1, 0,  CurrentParticle.Size.X, -CurrentParticle.Size.Y); glVertex4f(CurrentParticle.Position.X, CurrentParticle.Position.Y, CurrentParticle.Position.Z, CurrentParticle.Rotation);

    CurrentParticle := TParticle(CurrentParticle.Previous);
    end;
  
  glEnd;
end;

procedure TRParticles.Render;
var
  CurrentParticleGroup: TParticleGroupItem;
  Matrix: Array[0..15] of Single;
  BillboardMatrix: TMatrix4D;
  fCurrentMaterialCount: Integer;
begin
  BillboardMatrix := RotationMatrix(-ModuleManager.ModCamera.ActiveCamera.Rotation.Y, Vector(0, 1, 0));
  BillboardMatrix := BillboardMatrix * RotationMatrix(-ModuleManager.ModCamera.ActiveCamera.Rotation.X, Vector(1, 0, 0));
  BillboardMatrix := BillboardMatrix * RotationMatrix(-ModuleManager.ModCamera.ActiveCamera.Rotation.Z, Vector(0, 0, 1));

  MakeOGLCompatibleMatrix(BillboardMatrix, @Matrix[0]);

  fCurrentMaterialCount := 5;

  glDisable(GL_CULL_FACE);

  CurrentShader.Bind;
  if CurrentShader = MaterialShader then
    begin
    ModuleManager.ModRenderer.RObjects.CurrentGBuffer.Textures[1].Bind(5);
    ModuleManager.ModRenderer.RObjects.CurrentGBuffer.Textures[3].Bind(6);
    end;
  CurrentShader.UniformF('FogColor', ModuleManager.ModRenderer.FogColor);
  CurrentShader.UniformF('FogStrength', ModuleManager.ModRenderer.FogStrength);
  CurrentShader.UniformF('WaterHeight', ModuleManager.ModRenderer.RWater.CurrentHeight);
  CurrentShader.UniformF('WaterRefractionMode', ModuleManager.ModRenderer.FogRefractMode);
  CurrentShader.UniformMatrix4D('BillboardMatrix', @Matrix[0]);
  CurrentShader.UniformF('ViewPoint', ModuleManager.ModRenderer.ViewPoint.X, ModuleManager.ModRenderer.ViewPoint.Y, ModuleManager.ModRenderer.ViewPoint.Z);
  CurrentShader.UniformF('MaskOffset', 0, 0);

  CurrentParticleGroup := TParticleGroupItem(Park.pParticles.Emitters.First);
  while CurrentParticleGroup <> nil do
    begin
    CurrentShader.UniformI('MaterialID', (fCurrentMaterialCount shr 16) and $FF, (fCurrentMaterialCount shr 8) and $FF, fCurrentMaterialCount and $FF);
    Render(CurrentParticleGroup.Group);
    CurrentParticleGroup := TParticleGroupItem(CurrentParticleGroup.Next);
    inc(fCurrentMaterialCount);
    end;
  CurrentShader.Unbind;

  glColor4f(1, 1, 1, 1);

  glEnable(GL_CULL_FACE);
end;

constructor TRParticles.Create;
begin
  writeln('Hint: Creating particle renderer');

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
begin
  fMaterialShader.Free;
  fGeometryShader.Free;
end;

end.