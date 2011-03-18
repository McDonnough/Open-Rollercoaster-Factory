unit m_gui_image_default;

interface

uses
  SysUtils, Classes, m_gui_image_class, DGLOpenGL;

type
  TModuleGUIImageDefault = class(TModuleGUIImageClass)
    public
      procedure Render(Img: TImage); override;
      constructor Create;
      procedure CheckModConf; override;
    end;

implementation

procedure TModuleGUIImageDefault.Render(Img: TImage);
begin
  if Img.Tex <> nil then
    begin
    glEnable(GL_BLEND);
    Img.Tex.Bind(0);
    glColor4f(1, 1, 1, Img.Alpha);
    glBegin(GL_QUADS);
      glTexCoord2f(0, 0); glVertex2f(Img.Left, Img.Top);
      glTexCoord2f(1, 0); glVertex2f(Img.Left + Img.Width, Img.Top);
      glTexCoord2f(1, 1); glVertex2f(Img.Left + Img.Width, Img.Top + Img.Height);
      glTexCoord2f(0, 1); glVertex2f(Img.Left, Img.Top + Img.Height);
    glEnd;
    Img.Tex.Unbind;
    end;
end;

constructor TModuleGUIImageDefault.Create;
begin
  fModName := 'GUIImageDefault';
  fModType := 'GUIImageBox';
end;

procedure TModuleGUIImageDefault.CheckModConf;
begin
end;

end.