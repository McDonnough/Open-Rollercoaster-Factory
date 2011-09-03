unit m_gui_slider_class;

interface

uses
  SysUtils, Classes, m_gui_class, m_module, m_gui_edit_class, m_gui_iconifiedbutton_class, m_gui_label_class;

type
  TSlider = class(TGUIComponent)
    protected
      CX: Integer;
      fClicking: Boolean;
      fRealValue: Single;
      fEdit: TEdit;
      fLabel: TLabel;
      fConfirm: TIconifiedButton;
    public
      OnChange: TCallbackProcedure;
      Min, Max: Single;
      Value: Single;
      Digits: Integer;
      constructor Create(mParent: TGUIComponent);
      procedure Click(Sender: TGUIComponent);
      procedure ValueChanged(Sender: TGUIComponent);
      procedure ConfirmClicked(Sender: TGUIComponent);
      procedure Release(Sender: TGUIComponent);
      procedure Render; override;
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
  m_varlist, u_math, math, u_functions, u_vectors;

procedure TSlider.ValueChanged(Sender: TGUIComponent);
begin
  fRealValue := StrToFloatWD(fEdit.Text, Value);
  Value := Clamp(Round(fRealValue * Power(10, Digits)) / Power(10, Digits), Min, Max);
end;

procedure TSlider.ConfirmClicked(Sender: TGUIComponent);
begin
  fEdit.Alpha := 0;
  fConfirm.Alpha := 0;
  fLabel.Alpha := 0;
end;

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

  fLabel := TLabel.Create(Self);
  fLabel.Color := Vector(0, 0, 0, 0.4);
  fLabel.Alpha := 0;
  fLabel.Left := 0;
  fLabel.Top := 0;
  fLabel.Height := 32;
  fLabel.Size := 16;
  fLabel.Width := 96;

  fEdit := TEdit.Create(fLabel);
  fEdit.Top := 0;
  fEdit.Height := 32;
  fEdit.Width := 64;
  fEdit.Left := 0;
  fEdit.Alpha := 0;
  fEdit.OnChange := @ValueChanged;

  fConfirm := TIconifiedButton.Create(fLabel);
  fConfirm.Left := 64;
  fConfirm.Width := 32;
  fConfirm.Height := 32;
  fConfirm.Top := 0;
  fConfirm.Alpha := 0;
  fConfirm.Icon := 'dialog-ok-apply.tga';
  fConfirm.OnClick := @ConfirmClicked;
end;

procedure TSlider.Click(Sender: TGUIComponent);
begin
  if ModuleManager.ModInputHandler.MouseY > AbsY + 16 then
    begin
    fLabel.Width := Width;
    fLabel.Height := Height;
    fLabel.Alpha := 1;
    fEdit.Text := FloatToStr(Round(Value * Power(10, Digits)) / Power(10, Digits));
    fEdit.Alpha := 1;
    fEdit.Width := Width - 32;
    fConfirm.Alpha := 1;
    fConfirm.Left := Width - 32;
    end
  else
    begin
    fRealValue := Value;
    fClicking := True;
    CX := ModuleManager.ModInputHandler.MouseX;
    end;
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
    if OnChange <> nil then
      OnChange(Self);
    end;
  ModuleManager.ModGUISlider.Render(Self);
end;

end.