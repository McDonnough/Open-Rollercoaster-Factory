unit m_gui_label_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, m_gui_class;

type
  TLabel = class(TGUIComponent)
    public
      Caption: String;
      Size: Integer;
      Align: Integer;
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

constructor TLabel.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CLabel);
  Size := 12;
  Caption := '';
  Align := LABEL_ALIGN_LEFT;
end;

end.

