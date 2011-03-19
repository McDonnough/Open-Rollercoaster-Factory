unit m_gui_slider_default;

interface

uses
  SysUtils, Classes, m_gui_slider_class, m_texmng_class, DGLOpenGL, Math, u_math;

type
  TModuleGUISliderDefault = class(TModuleGUISliderClass)
    protected
      fLineTexture, fThrobberTexture: TTexture;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      procedure Render(Slider: TSlider);
    end;

implementation

uses
  m_varlist;

constructor TModuleGUISliderDefault.Create;
begin
  fModType := 'GUISlider';
  fModName := 'GUISliderDefault';

  CheckModConf;

  fLineTexture := TTexture.Create;
  fLineTexture.FromFile(GetConfVal('line'));

  fThrobberTexture := TTexture.Create;
  fThrobberTexture.FromFile(GetConfVal('throbber'));
end;

destructor TModuleGUISliderDefault.Free;
begin
  fLineTexture.Free;
  fThrobberTexture.Free;
end;

procedure TModuleGUISliderDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('line', 'guisliderdefault/line.tga');
    SetConfVal('throbber', 'guisliderdefault/throbber.tga');
    end;
end;

procedure TModuleGUISliderDefault.Render(Slider: TSlider);
var
  Number: String;
  TextWidth: Integer;
  ThrobberPosition: Integer;
begin
  ThrobberPosition := Round((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min) * (Slider.Width - 15));
  fLineTexture.Bind(0);
  glEnable(GL_BLEND);
  glBegin(GL_QUADS);
    glColor4f(1, 1, 1, Slider.Alpha);
    glTexCoord2f(0.0, 0); glVertex2f(Slider.Left,     Slider.Top);
    glTexCoord2f(0.5, 0); glVertex2f(Slider.Left + 9, Slider.Top);
    glTexCoord2f(0.5, 1); glVertex2f(Slider.Left + 9, Slider.Top + 15);
    glTexCoord2f(0.0, 1); glVertex2f(Slider.Left,     Slider.Top + 15);

    glTexCoord2f(0.5, 0); glVertex2f(Slider.Left + 9,                Slider.Top);
    glTexCoord2f(0.5, 0); glVertex2f(Slider.Left + Slider.Width - 9, Slider.Top);
    glTexCoord2f(0.5, 1); glVertex2f(Slider.Left + Slider.Width - 9, Slider.Top + 15);
    glTexCoord2f(0.5, 1); glVertex2f(Slider.Left + 9,                Slider.Top + 15);

    glTexCoord2f(0.5, 0); glVertex2f(Slider.Left + Slider.Width - 9, Slider.Top);
    glTexCoord2f(1.0, 0); glVertex2f(Slider.Left + Slider.Width,     Slider.Top);
    glTexCoord2f(1.0, 1); glVertex2f(Slider.Left + Slider.Width,     Slider.Top + 15);
    glTexCoord2f(0.5, 1); glVertex2f(Slider.Left + Slider.Width - 9, Slider.Top + 15);
  glEnd;
  fLineTexture.Unbind;
  fThrobberTexture.Bind(0);
  glBegin(GL_QUADS);
    glColor4f(1, 1, 1, Slider.Alpha);
    glTexCoord2f(0, 0); glVertex2f(Slider.Left + ThrobberPosition +  0, Slider.Top +  0);
    glTexCoord2f(1, 0); glVertex2f(Slider.Left + ThrobberPosition + 15, Slider.Top +  0);
    glTexCoord2f(1, 1); glVertex2f(Slider.Left + ThrobberPosition + 15, Slider.Top + 15);
    glTexCoord2f(0, 1); glVertex2f(Slider.Left + ThrobberPosition +  0, Slider.Top + 15);
  glEnd;
  glDisable(GL_BLEND);
  fThrobberTexture.Unbind;
  Number := FloatToStr(Round(Slider.Value * Power(10, Slider.Digits)) / Power(10, Slider.Digits));
  TextWidth := ModuleManager.ModFont.CalculateTextWidth(Number, Round(Slider.Height) - 16);
  ModuleManager.ModFont.Write(Number, Slider.Height - 16, Clamp(Slider.Left + ThrobberPosition + 8 - (TextWidth div 2), Slider.Left, Slider.Left + Slider.Width - TextWidth), Slider.Top + 16, 0, 0, 0, Slider.Alpha, 0);
  glColor4f(1, 1, 1, 1);
end;

end.