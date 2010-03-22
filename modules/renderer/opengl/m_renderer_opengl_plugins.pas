unit m_renderer_opengl_plugins;

interface

uses
  SysUtils, Classes, DGLOpenGL, u_math, u_vectors, m_shdmng_class, m_texmng_class, math;

type
  TRE3DAnaglyph = class
    protected
      ResX, ResY: Integer;
    public
      procedure Apply(Event: String; Param, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

  TRE3DShutter = class
    protected
      ResX, ResY: Integer;
    public
      procedure Apply(Event: String; Param, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

  TRE2DFocus = class
    protected
      ResX, ResY: Integer;
      FTexture, FTexture2: TTexture;
      FShader: TShader;
    public
      procedure Apply(Event: String; Param, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

  TREMotionBlur = class
    public
      procedure Apply(Event: String; Param, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

  TRenderEffectManager = class
    protected
      RE3DAnaglyph: TRE3DAnaglyph;
      RE3DShutter: TRE3DShutter;
      RE2DFocus: TRE2DFocus;
      REMotionBlur: TREMotionBlur;
    public
      constructor Create;
      destructor Free;
      procedure LoadEffect(ID: Integer);
    end;

const
  RE_3D_ANAGLYPH = 1;
  RE_3D_SHUTTER = 2;
  RE_2D_FOCUS = 3;
  RE_MOTIONBLUR = 4;

implementation

uses
  m_module, m_varlist, u_events;

procedure TRE3DAnaglyph.Apply(Event: String; Param, Result: Pointer);
var
  DistPixel: DWord;
  Distance: Single;
begin
  glReadPixels(ModuleManager.ModInputHandler.MouseX, ResY - ModuleManager.ModInputHandler.MouseY, 1, 1, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, @DistPixel);
  Distance := (DistPixel / High(DWord)) ** 2 * 10000;
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);

  glColorMask(true, false, false, true);
  ModuleManager.ModRenderer.Render(-0.2, Distance);
  glColorMask(false, true, true, true);
  ModuleManager.ModRenderer.Render(0.2, Distance);
  glColorMask(true, true, true, true);
end;

constructor TRE3DAnaglyph.Create;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  EventManager.AddCallback('TModuleRenderer.Render', @Self.Apply);
end;

destructor TRE3DAnaglyph.Free;
begin
  EventManager.RemoveCallback(@Self.Apply);
end;

procedure TRE3DShutter.Apply(Event: String; Param, Result: Pointer);
var
  DistPixel: DWord;
  Distance: Single;
begin
  glReadPixels(ModuleManager.ModInputHandler.MouseX, ResY - ModuleManager.ModInputHandler.MouseY, 1, 1, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, @DistPixel);
  Distance := (DistPixel / High(DWord)) ** 2 * 10000;
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);

  glDrawBuffer(GL_LEFT);
  ModuleManager.ModRenderer.Render(-0.2, Distance);
  glDrawBuffer(GL_RIGHT);
  ModuleManager.ModRenderer.Render(0.2, Distance);
  glDrawBuffer(GL_BACK);
end;

constructor TRE3DShutter.Create;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  ModuleManager.ModGLContext.AdditionalContextOptions := ModuleManager.ModGLContext.AdditionalContextOptions or GL_STEREO;
  ModuleManager.ModGLContext.SetResolution(ResX, ResY);
  EventManager.AddCallback('TModuleRenderer.Render', @Self.Apply);
end;

destructor TRE3DShutter.Free;
begin
  EventManager.RemoveCallback(@Self.Apply);
end;

procedure TRE2DFocus.Apply(Event: String; Param, Result: Pointer);
var
  DistPixel: DWord;
  Distance: Single;
begin
  glReadPixels(ModuleManager.ModInputHandler.MouseX, ResY - ModuleManager.ModInputHandler.MouseY, 1, 1, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, @DistPixel);
  Distance := (DistPixel / High(DWord)) ** 2 * 10000;
  FTexture.Bind(1);
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, 0, 0, ResX, ResY, 0);
  FTexture2.Bind(0);
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, ResX, ResY, 0);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glDisable(GL_DEPTH_TEST);
  FShader.Bind;
  FShader.UniformF('focusDist', Distance);
  FShader.UniformF('blurDirection', 1.0, 0.0);
  glBegin(GL_QUADS);
    glVertex2f(-1, -1);
    glVertex2f(-1, 1);
    glVertex2f(1, 1);
    glVertex2f(1, -1);
  glEnd;
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, ResX, ResY, 0);
  FShader.UniformF('blurDirection', 0.0, 1.0);
  glBegin(GL_QUADS);
    glVertex2f(-1, -1);
    glVertex2f(-1, 1);
    glVertex2f(1, 1);
    glVertex2f(1, -1);
  glEnd;
  FShader.UnBind;
end;

constructor TRE2DFocus.Create;
begin
  FTexture := TTexture.Create;
  FTexture.CreateNew(ResX, ResY, GL_LUMINANCE);
  FTexture.SetClamp(GL_CLAMP, GL_CLAMP);
  FTexture2 := TTexture.Create;
  FTexture2.CreateNew(ResX, ResY, GL_RGBA);
  FTexture2.SetClamp(GL_CLAMP, GL_CLAMP);
  FShader := TShader.Create('rendereropengl/glsl/effects/depthfocus.vs', 'rendereropengl/glsl/effects/depthfocus.fs');
  FShader.UniformI('tex', 0);
  FShader.UniformI('dist', 1);

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  EventManager.AddCallback('TModuleRenderer.PostRender', @Self.Apply);
end;

destructor TRE2DFocus.Free;
begin
  EventManager.RemoveCallback(@Self.Apply);
  FTexture.Free;
  FTexture2.Free;
  FShader.Free;
end;

procedure TREMotionBlur.Apply(Event: String; Param, Result: Pointer);
begin
  glAccum(GL_MULT, 0.6);
  glAccum(GL_ACCUM, 0.5);
  glAccum(GL_RETURN, 1.0);
end;

constructor TREMotionBlur.Create;
begin
  EventManager.AddCallback('TModuleRenderer.PostRender', @Self.Apply);
  glClear(GL_ACCUM_BUFFER_BIT);
end;

destructor TREMotionBlur.Free;
begin
  EventManager.RemoveCallback(@Self.Apply);
end;

constructor TRenderEffectManager.Create;
begin
  RE3DAnaglyph := nil;
  RE3DShutter := nil;
  RE2DFocus := nil;
  REMotionBlur := nil;
end;

destructor TRenderEffectManager.Free;
begin
  EventManager.RemoveCallback('TModuleRenderer.Render');
  if RE3DAnaglyph <> nil then RE3DAnaglyph.Free;
  if RE3DShutter <> nil then RE3DShutter.Free;
  if RE2DFocus <> nil then RE2DFocus.Free;
  if REMotionBlur <> nil then REMotionBlur.Free;
end;

procedure TRenderEffectManager.LoadEffect(ID: Integer);
begin
  case ID of
    RE_3D_ANAGLYPH: RE3DAnaglyph := TRE3DAnaglyph.Create;
    RE_3D_SHUTTER: RE3DShutter := TRE3DShutter.Create;
    RE_2D_FOCUS: RE2DFocus := TRE2DFocus.Create;
    RE_MOTIONBLUR: REMotionblur := TREMotionblur.Create;
    end;
end;

end.