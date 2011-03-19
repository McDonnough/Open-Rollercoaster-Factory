unit m_gui_slider_class;

interface

uses
  SysUtils, Classes, m_gui_class, m_module;

type
  TSlider = class(TGUIComponent)
    protected
      CX: Integer;
      fClicking: Boolean;
      fRealValue: Single;
    public
      OnChange: TCallbackProcedure;
      Min, Max: Single;
      Value: Single;
      Digits: Integer;
      constructor Create(mParent: TGUIComponent);
      procedure Click(Sender: TGUIComponent);
      procedure Release(Sender: TGUIComponent);
      procedure Render;
    end;

  TModuleGUISliderClass = class(TBasicModule)
    public
      (**
        * Render a slider
        *)
      procedure Render(Slider: TSlider); virtual abstract;
    end;

implementation

uses
  m_varlist, u_math, math;

constructor TSlider.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CSlider);
  Min := 0;
  Max := 1;
  Value := 0;
  OnChange := nil;
  Digits := 1;
  OnClick := @Click;
  OnRelease := @Release;
  fRealValue := 0;
end;

procedure TSlider.Click(Sender: TGUIComponent);
begin
  fRealValue := Value;
  fClicking := True;
  CX := ModuleManager.ModInputHandler.MouseX;
end;

procedure TSlider.Release(Sender: TGUIComponent);
begin
  fClicking := False;
  if OnChange <> nil then
    OnChange(Self);
end;

procedure TSlider.Render;
var
  PixelOffset: Integer;
  ValuePerPixel: Single;
begin
  if fClicking then
    begin
    PixelOffset := ModuleManager.ModInputHandler.MouseX - CX;
    ValuePerPixel := (Max - Min) / (Width - 15);
    fRealValue := fRealValue + ValuePerPixel * PixelOffset;
    Value := Clamp(Round(fRealValue * Power(10, Digits)) / Power(10, Digits), Min, Max);
    CX := ModuleManager.ModInputHandler.MouseX;
    end;
  ModuleManager.ModGUISlider.Render(Self);
end;

end.