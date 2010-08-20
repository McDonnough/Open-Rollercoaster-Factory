unit u_events;

interface

uses
  SysUtils, Classes;

type
  TEventCallback = procedure(Event: String; Data, Result: Pointer) of object;

  TEvent = record
    Name: String;
    Callbacks: Array of TEventCallback;
    end;

  TEventManager = class
    protected
      fEvents: Array of TEvent;
    public
      procedure CallEvent(Event: String; Data, Result: Pointer);
      procedure AddCallback(Event: String; Callback: TEventCallback);
      procedure RemoveCallback(Event: String);
      procedure RemoveCallback(Callback: TEventCallback);
      procedure RemoveCallback(Event: String; Callback: TEventCallback);
    end;

var
  EventManager: TEventManager;

implementation

uses
  m_varlist;

procedure TEventManager.CallEvent(Event: String; Data, Result: Pointer);
var
  i, j: Integer;
begin
  for i := 0 to high(fEvents) do
    if fEvents[i].name = Event then
      begin
      for j := 0 to high(fEvents[i].Callbacks) do
       // try
          fEvents[i].Callbacks[j](Event, Data, Result);
       // except
       //   ModuleManager.ModLog.AddError('Event ' + Event + ' #' + IntToStr(j) + ' caused an exception');
       // end;
      exit;
      end;
end;

procedure TEventManager.AddCallback(Event: String; Callback: TEventCallback);
var
  i: Integer;
begin
  for i := 0 to high(fEvents) do
    if fEvents[i].Name = Event then
      begin
      setLength(fEvents[i].Callbacks, length(fEvents[i].Callbacks) + 1);
      fEvents[i].Callbacks[high(fEvents[i].Callbacks)] := Callback;
      end;
  setLength(fEvents, length(fEvents) + 1);
  with fEvents[high(fEvents)] do
    begin
    Name := Event;
    setLength(Callbacks, length(Callbacks) + 1);
    Callbacks[high(Callbacks)] := Callback;
    end;
end;

procedure TEventManager.RemoveCallback(Event: String);
var
  i: Integer;
begin
  for i := 0 to high(fEvents) do
    if fEvents[i].Name = Event then
      begin
      fEvents[i] := fEvents[high(fEvents)];
      setLength(fEvents, length(fEvents) - 1);
      exit;
      end;
end;

procedure TEventManager.RemoveCallback(Callback: TEventCallback);
var
  i, j, k: Integer;
begin
  for i := 0 to high(fEvents) do
    for j := 0 to high(fEvents[i].Callbacks) do
      if j <= high(fEvents[i].Callbacks) then
        if fEvents[i].Callbacks[j] = Callback then
          begin
          for k := j + 1 to high(fEvents[i].Callbacks) do
            fEvents[i].Callbacks[k - 1] := fEvents[i].Callbacks[k];
          setLength(fEvents[i].Callbacks, length(fEvents[i].Callbacks) - 1);
          end;
end;

procedure TEventManager.RemoveCallback(Event: String; Callback: TEventCallback);
var
  i, j, k: Integer;
begin
  for i := 0 to high(fEvents) do
    if fEvents[i].Name = Event then
      begin
      for j := 0 to high(fEvents[i].Callbacks) do
        if j <= high(fEvents[i].Callbacks) then
          if fEvents[i].Callbacks[j] = Callback then
            begin
            for k := j + 1 to high(fEvents[i].Callbacks) do
              fEvents[i].Callbacks[k - 1] := fEvents[i].Callbacks[k];
            setLength(fEvents[i].Callbacks, length(fEvents[i].Callbacks) - 1);
            end;
      exit;
      end;
end;

end.