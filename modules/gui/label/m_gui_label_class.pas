unit m_gui_label_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, m_gui_class, u_vectors;

type
  TLabel = class(TGUIComponent)
    protected
      fCaption: String;
      procedure setCaption(C: String);
    public
      Size: Integer;
      Align: Integer;
      Color: TVector4D;
      property Caption: String read fCaption write setCaption;
      procedure Render;
      constructor Create(mParent: TGUIComponent);
    end;

  TModuleGUILabelClass = class(TBasicModule)
    public
      (**
        * Render a label
        *@param Label
        *)
      procedure Render(Lbl: TLabel); virtual abstract;
    end;

const
  LABEL_ALIGN_LEFT = 0;
  LABEL_ALIGN_CENTER = 1;
  LABEL_ALIGN_RIGHT = 2;

implementation

uses
  m_varlist;

procedure TLabel.Render;
begin
  ModuleManager.ModGUILabel.Render(Self);
end;

procedure TLabel.setCaption(C: String);
begin
  if TranslateContent then
    fCaption := ModuleManager.ModLanguage.Translate(C)
  else
    fCaption := C;
end;

constructor TLabel.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CLabel);
  Size := 12;
  Caption := '';
  Align := LABEL_ALIGN_LEFT;
  Color := Vector(1, 1, 1, 0);
end;

end.

