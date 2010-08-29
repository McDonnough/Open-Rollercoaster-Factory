unit m_renderer_opengl_plugins;

interface

uses
  SysUtils, Classes, DGLOpenGL, u_math, u_vectors, m_shdmng_class, m_texmng_class, math, m_renderer_opengl_interface;

type
  TRENormal = class
    public
      procedure Apply(Event: String; Param, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

  TRE3DAnaglyph = class
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
      FTexture2: TTexture;
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

  TREBloom = class
    protected
      ResX, ResY: Integer;
      fTexture, fTexture2: TTexture;
      fShader, fShader2: TShader;
    public
      procedure Apply(Event: String; Param, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

  TRE3DInterlaced =  class
    protected
      ResX, ResY: Integer;
      fShader: TShader;
    public
      procedure Apply(Event: String; Param, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

  TRenderEffectManager = class
    protected
      RENormal: TRENormal;
      RE3DAnaglyph: TRE3DAnaglyph;
      RE2DFocus: TRE2DFocus;
      REMotionBlur: TREMotionBlur;
      REBloom: TREBloom;
    public
      constructor Create;
      destructor Free;
      procedure LoadEffect(ID: Integer);
    end;

const
  RE_NORMAL = 1;
  RE_3D_ANAGLYPH = 2;
  RE_2D_FOCUS = 3;
  RE_MOTIONBLUR = 4;
  RE_BLOOM = 5;
  RE_3D_INTERLACED = 6;

implementation

uses
  m_module, m_varlist, u_events, g_park;

procedure TRENormal.Apply(Event: String; Param, Result: Pointer);
begin
  ModuleManager.ModRenderer.Render();
end;

constructor TRENormal.Create;
begin
  EventManager.AddCallback('TModuleRenderer.Render', @Self.Apply);
end;

destructor TRENormal.Free;
begin
  EventManager.RemoveCallback(@Self.Apply);
end;

procedure TRE3DAnaglyph.Apply(Event: String; Param, Result: Pointer);
begin
  fInterface.Options.Items['terrain:occlusionquery'] := 'off';

  glColorMask(true, false, false, true);
  ModuleManager.ModRenderer.CR := True;
  ModuleManager.ModRenderer.CG := False;
  ModuleManager.ModRenderer.CB := False;
  glLoadIdentity;
  ModuleManager.ModRenderer.Render(-0.4, ModuleManager.ModRenderer.MouseDistance);
  glColorMask(false, true, true, true);
  ModuleManager.ModRenderer.CR := False;
  ModuleManager.ModRenderer.CG := True;
  ModuleManager.ModRenderer.CB := True;
  glLoadIdentity;
  ModuleManager.ModRenderer.Render(0.4, ModuleManager.ModRenderer.MouseDistance);
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

procedure TRE2DFocus.Apply(Event: String; Param, Result: Pointer);
var
  DistPixel: DWord;
  Distance: Single;
begin
  ModuleManager.ModRenderer.DistTexture.Bind(1);
  FTexture2.Bind(0);
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, ResX, ResY, 0);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glDisable(GL_DEPTH_TEST);
  FShader.Bind;
  FShader.UniformF('focusDist', ModuleManager.ModRenderer.MouseDistance);
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
  FTexture2 := TTexture.Create;
  FTexture2.CreateNew(ResX, ResY, GL_RGBA);
  FTexture2.SetClamp(GL_CLAMP, GL_CLAMP);
  FTexture2.SetFilter(GL_NEAREST, GL_NEAREST);
  FShader := TShader.Create('rendereropengl/glsl/effects/depthfocus.vs', 'rendereropengl/glsl/effects/depthfocus.fs');
  FShader.UniformI('tex', 0);
  FShader.UniformI('dist', 1);

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  EventManager.AddCallback('TModuleRenderer.PostRender', @Self.Apply);
end;

destructor TRE2DFocus.Free;
begin
  EventManager.RemoveCallback(@Self.Apply);
  FTexture2.Free;
  FShader.Free;
end;

procedure TREMotionBlur.Apply(Event: String; Param, Result: Pointer);
begin
  glAccum(GL_MULT, 0.6);
  glAccum(GL_ACCUM, 0.4);
  glAccum(GL_RETURN, 1.0);
end;

constructor TREMotionBlur.Create;
begin
  EventManager.AddCallback('TModuleRenderer.PostRender', @Self.Apply);
  glClearAccum(0.0, 0.0, 0.0, 0.0);
  glClear(GL_ACCUM_BUFFER_BIT);
end;

destructor TREMotionBlur.Free;
begin
  EventManager.RemoveCallback(@Self.Apply);
end;

procedure TREBloom.Apply(Event: String; Param, Result: Pointer);
begin
  fTexture2.Bind(0);
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, ResX, ResY, 0);
  fTexture.Bind(0);
  fShader.Unbind;
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, ResX, ResY, 0);
  fShader.Bind;
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glDisable(GL_DEPTH_TEST);
  glBegin(GL_QUADS);
    glVertex2f(-1, -1);
    glVertex2f(-1, 1);
    glVertex2f(1, 1);
    glVertex2f(1, -1);
  glEnd;
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, ResX, ResY, 0);

  fShader.Unbind;
  fShader2.Bind;
  fShader2.UniformF('BlurDirection', 0.0, 1.0);
  glBegin(GL_QUADS);
    glVertex2f(-1, -1);
    glVertex2f(-1, 1);
    glVertex2f(1, 1);
    glVertex2f(1, -1);
  glEnd;
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, ResX, ResY, 0);

  fShader2.UniformF('BlurDirection', 1.0, 0.0);
  glBegin(GL_QUADS);
    glVertex2f(-1, -1);
    glVertex2f(-1, 1);
    glVertex2f(1, 1);
    glVertex2f(1, -1);
  glEnd;
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, ResX, ResY, 0);

  fShader2.Unbind;
  fTexture2.Bind(0);
  glColor4f(1, 1, 1, 1);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex2f(-1, -1);
    glTexCoord2f(0, 1); glVertex2f(-1, 1);
    glTexCoord2f(1, 1); glVertex2f(1, 1);
    glTexCoord2f(1, 0); glVertex2f(1, -1);
  glEnd;

  glEnable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ONE);
  fTexture.Bind(0);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex2f(-1, -1);
    glTexCoord2f(0, 1); glVertex2f(-1, 1);
    glTexCoord2f(1, 1); glVertex2f(1, 1);
    glTexCoord2f(1, 0); glVertex2f(1, -1);
  glEnd;
  glDisable(GL_BLEND);

  fTexture.Unbind;
end;

constructor TREBloom.Create;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fTexture := TTexture.Create;
  fTexture.CreateNew(ResX, ResY, GL_RGB);
  fTexture.SetClamp(GL_CLAMP, GL_CLAMP);
  FTexture.SetFilter(GL_NEAREST, GL_NEAREST);
  fTexture2 := TTexture.Create;
  fTexture2.CreateNew(ResX, ResY, GL_RGB);
  fTexture2.SetClamp(GL_CLAMP, GL_CLAMP);
  FTexture2.SetFilter(GL_NEAREST, GL_NEAREST);
  fShader := TShader.Create('rendereropengl/glsl/effects/bloom.vs', 'rendereropengl/glsl/effects/bloom.fs');
  fShader.UniformF('Screen', ResX, ResY);
  fShader.UniformI('Tex', 0);
  fShader2 := TShader.Create('rendereropengl/glsl/effects/bloomblur.vs', 'rendereropengl/glsl/effects/bloomblur.fs');
  fShader2.UniformF('Screen', ResX, ResY);
  fShader2.UniformI('Tex', 0);
  EventManager.AddCallback('TModuleRenderer.PostRender', @Self.Apply);
end;

destructor TREBloom.Free;
begin
  EventManager.RemoveCallback(@Self.Apply);
  fShader.Free;
  fShader2.Free;
  fTexture.Free;
  fTexture2.Free;
end;

procedure TRE3DInterlaced.Apply(Event: String; Param, Result: Pointer);
begin
  fInterface.Options.Items['terrain:occlusionquery'] := 'off';

  fShader.Bind;
  fShader.UniformI('ModMode', 0);


  glLoadIdentity;
  ModuleManager.ModRenderer.Render(-0.4, ModuleManager.ModRenderer.MouseDistance);
  glLoadIdentity;
  ModuleManager.ModRenderer.Render(0.4, ModuleManager.ModRenderer.MouseDistance);
end;

constructor TRE3DInterlaced.Create;
begin
  ModuleManager.ModGLMng.AspectRatioFactor := 2;
end;

destructor TRE3DInterlaced.Free;
begin
  ModuleManager.ModGLMng.AspectRatioFactor := 1;
end;

constructor TRenderEffectManager.Create;
begin
  RENormal := nil;
  RE3DAnaglyph := nil;
  RE2DFocus := nil;
  REMotionBlur := nil;
  REBloom := nil;
end;

destructor TRenderEffectManager.Free;
begin
  EventManager.RemoveCallback('TModuleRenderer.Render');
  EventManager.RemoveCallback('TModuleRenderer.PostRender');
  if RENormal <> nil then RENormal.Free;
  if RE3DAnaglyph <> nil then RE3DAnaglyph.Free;
  if RE2DFocus <> nil then RE2DFocus.Free;
  if REMotionBlur <> nil then REMotionBlur.Free;
  if REBloom <> nil then REBloom.Free;
end;

procedure TRenderEffectManager.LoadEffect(ID: Integer);
begin
  case ID of
    RE_NORMAL: RENormal := TRENormal.Create;
    RE_3D_ANAGLYPH: RE3DAnaglyph := TRE3DAnaglyph.Create;
    RE_2D_FOCUS: RE2DFocus := TRE2DFocus.Create;
    RE_MOTIONBLUR: REMotionblur := TREMotionblur.Create;
    RE_BLOOM: REBloom := TREBloom.Create;
    end;
end;

end.