unit m_gui_progressbar_class;

interface

uses
  SysUtils, Classes, m_module, m_gui_class;

type
  TProgressBar = class(TGUIComponent)
    protected
      fProgress, fDestProgress: Integer;
    public
      property Progress: Integer read fProgress write fDestProgress;
      procedure Render;
      constructor Create(mParent: TGUIComponent);
    end;

  TModuleGUIProgressBarClass = class(TBasicModule)
    public
      (**
        * Render a progress bar
        *@param The progress bar to render
        *)
      procedure Render(pb: TProgressBar); virtual abstract;
    end;

implementation

uses
  m_varlist;

procedure TProgressBar.Render;
begin
  if abs(fProgress - fDestProgress) < 3 then
    fProgress := fDestProgress
  else if fDestProgress > fProgress then
    inc(fProgress, 3)
  else
    dec(fProgress, 3);
  ModuleManager.ModGUIProgressBar.Render(Self);
end;

constructor TProgressBar.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CProgressBar);
  fProgress := 0;
  fDestProgress := 0;
end;

end.