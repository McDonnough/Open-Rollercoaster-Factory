unit m_gui_timer_class;

interface

uses
  SysUtils, Classes, m_module, m_gui_class;

type
  TTimer = class(TGUIComponent)
    protected
      fBaseInterval: UInt64;
      fTimeToExpire: UInt64;
      fLastUpdate: UInt64;
      procedure SetInterval(nInterval: UInt64);
    public
      IsOn: Boolean;
      OnExpire: TCallbackProcedure;
      property Interval: UInt64 read fBaseInterval write SetInterval; // Milliseconds!
      procedure Render;
      constructor Create(mParent: TGUIComponent);
    end;

  TModuleGUITimerClass = class(TBasicModule)
    public
      (**
        * Get time (1 unit = 100 microseconds = 0.1ms)
        *@return some time
        *)
      function GetTime: UInt64; virtual abstract;

      (**
        * Get the difference between two times
        *@param Time to subtract
        *@return The difference from now to the time
        *)
      function GetTimeDifference(Time: UInt64): UInt64; virtual abstract;
    end;

implementation

uses
  m_varlist;

procedure TTimer.SetInterval(nInterval: UInt64);
begin
  fBaseInterval := nInterval;
  fTimeToExpire := 10 * nInterval;
end;

procedure TTimer.Render;
begin
  if IsOn then
    begin
    fTimeToExpire := fTimeToExpire - ModuleManager.ModGUITimer.GetTimeDifference(fLastUpdate);
    if fTimeToExpire <= 0 then
      begin
      fTimeToExpire := 10 * fBaseInterval + fTimeToExpire;
      if OnExpire <> nil then
        OnExpire(Self);
      end;
    end;
  fLastUpdate := ModuleManager.ModGUITimer.GetTime;
end;

constructor TTimer.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CTimer);
  OnExpire := nil;
  IsOn := False;
  fLastUpdate := ModuleManager.ModGUITimer.GetTime;
  Interval := 1000;
end;

end.