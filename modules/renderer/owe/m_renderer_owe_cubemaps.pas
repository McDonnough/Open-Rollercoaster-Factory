unit m_renderer_owe_cubemaps;

interface

uses
  SysUtils, Classes, m_renderer_owe_classes, m_renderer_owe_renderpass, m_shdmng_class, m_texmng_class, u_graphics, u_scene,
  DGLOpenGL, u_vectors;

type
  TCubeMap = class
    protected
      fMap: TFBO;
      fWidth, fHeight: Integer;
      procedure SetUpView(Orientation: Integer);
      procedure ResetView;
    public
      property Map: TFBO read fMap;
      procedure Render(Orientation: Integer; RenderPass: TRenderPass; Position: TVector3D);
      procedure Render(RenderPass: TRenderPass; Position: TVector3D);
      constructor Create(Width, Height: Integer; Format: GLEnum);
      destructor Free;
    end;

  TShadowCubeMap = class(TCubeMap)
    public
      RenderProcedure: procedure of object;
      procedure RenderShadow(Orientation: Integer; Position: TVector3D);
      procedure Render(Position: TVector3D);
      constructor Create(Width, Height: Integer; Format: GLEnum);
    end;

const
  CUBE_FRONT  = 0;
  CUBE_RIGHT  = 1;
  CUBE_BACK   = 2;
  CUBE_LEFT   = 3;
  CUBE_BOTTOM = 4;
  CUBE_TOP    = 5;

implementation

uses
  m_varlist;

procedure TCubeMap.SetUpView(Orientation: Integer);
begin
  glMatrixMode(GL_PROJECTION);
  glPushMatrix;

  glLoadIdentity;
  gluPerspective(90, 1, 0.1, 10000);

  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;

  glLoadIdentity;

  case Orientation of
    CUBE_BACK: glRotatef(180, 0, 1, 0);
    CUBE_LEFT: glRotatef(270, 0, 1, 0);
    CUBE_RIGHT: glRotatef(90, 0, 1, 0);
    CUBE_BOTTOM: glRotatef(90, 1, 0, 0);
    CUBE_TOP: glRotatef(270, 1, 0, 0);
    end;
end;

procedure TCubeMap.ResetView;
begin
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix;

  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  
  glMatrixMode(GL_MODELVIEW);
end;

procedure TCubeMap.Render(Orientation: Integer; RenderPass: TRenderPass; Position: TVector3D);
begin
  SetUpView(Orientation);

  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  RenderPass.Render;

  fMap.Bind;
    glViewport(fWidth * (Orientation - 3 * (Orientation div 3)), fHeight * (Orientation div 3), fWidth, fHeight);

    ModuleManager.ModRenderer.FullscreenShader.Bind;
    RenderPass.Scene.Textures[0].Bind(0);

    glBegin(GL_QUADS);
      glTexCoord2f(0, 0); glVertex2f(-1, -1);
      glTexCoord2f(1, 0); glVertex2f( 1, -1);
      glTexCoord2f(1, 1); glVertex2f( 1,  1);
      glTexCoord2f(0, 1); glVertex2f(-1,  1);
    glEnd;

    ModuleManager.ModRenderer.FullscreenShader.UnBind;
  fMap.Unbind;
  
  ResetView;
end;

procedure TCubeMap.Render(RenderPass: TRenderPass; Position: TVector3D);
begin
  Render(CUBE_FRONT, RenderPass, Position);
  Render(CUBE_BACK, RenderPass, Position);
  Render(CUBE_LEFT, RenderPass, Position);
  Render(CUBE_RIGHT, RenderPass, Position);
  ModuleManager.ModRenderer.RTerrain.BorderEnabled := False;
  Render(CUBE_BOTTOM, RenderPass, Position);
  Render(CUBE_TOP, RenderPass, Position);
  ModuleManager.ModRenderer.RTerrain.BorderEnabled := True;
  ModuleManager.ModRenderer.Frustum.Calculate;
end;

constructor TCubeMap.Create(Width, Height: Integer; Format: GLEnum);
begin
  fWidth := Width;
  fHeight := Height;
  fMap := TFBO.Create(3 * Width, 2 * Height, false);
  fMap.AddTexture(Format, GL_LINEAR, GL_LINEAR);
  fMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fMap.Unbind;
end;

destructor TCubeMap.Free;
begin
  fMap.Free;
end;

procedure TShadowCubeMap.RenderShadow(Orientation: Integer; Position: TVector3D);
begin
  if RenderProcedure <> nil then
    begin
    SetUpView(Orientation);

    glTranslatef(-Position.X, -Position.Y, -Position.Z);
    ModuleManager.ModRenderer.Frustum.Calculate;

    glViewport(fWidth * (Orientation - 3 * (Orientation div 3)), fHeight * (Orientation div 3), fWidth, fHeight);
    RenderProcedure;

    ResetView;
    end;
end;

procedure TShadowCubeMap.Render(Position: TVector3D);
begin
  fMap.Bind;
    glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);
    RenderShadow(CUBE_FRONT, Position);
    RenderShadow(CUBE_BACK, Position);
    RenderShadow(CUBE_LEFT, Position);
    RenderShadow(CUBE_RIGHT, Position);
    RenderShadow(CUBE_BOTTOM, Position);
    RenderShadow(CUBE_TOP, Position);
  fMap.Unbind;
end;

constructor TShadowCubeMap.Create(Width, Height: Integer; Format: GLEnum);
begin
  fWidth := Width;
  fHeight := Height;
  fMap := TFBO.Create(3 * Width, 2 * Height, true);
  fMap.AddTexture(Format, GL_LINEAR, GL_LINEAR);
  fMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fMap.Unbind;
  RenderProcedure := nil;
end;

end.