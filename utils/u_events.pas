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

  TEventCall = record
    Event: String;
    Data, Result: Pointer;
    end;

  TEventManager = class
    protected
      fEvents: Array of TEvent;
      fEventQuery: Array of TEventCall;
    public
      procedure ExecuteQuery;
      procedure QueryEvent(Event: String; Data, Result: Pointer);
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

procedure TEventManager.ExecuteQuery;
var
  I, TotalEvents: Integer;
begin
  TotalEvents := Length(fEventQuery);
  for I := 0 to TotalEvents - 1 do
    CallEvent(fEventQuery[I].Event, fEventQuery[I].Data, fEventQuery[I].Result);
  for I := TotalEvents to high(fEventQuery) do
    fEventQuery[I - TotalEvents] := fEventQuery[I];
  SetLength(fEventQuery, Length(fEventQuery) - TotalEvents);
end;

procedure TEventManager.QueryEvent(Event: String; Data, Result: Pointer);
begin
  SetLength(fEventQuery, length(fEventQuery) + 1);
  fEventQuery[high(fEventQuery)].Event := Event;
  fEventQuery[high(fEventQuery)].Data := Data;
  fEventQuery[high(fEventQuery)].Result := Result;
end;

procedure TEventManager.CallEvent(Event: String; Data, Result: Pointer);
var
  i, j: Integer;
begin
  for i := 0 to high(fEvents) do
    if fEvents[i].name = Event then
      begin
      for j := 0 to high(fEvents[i].Callbacks) do
        try
          fEvents[i].Callbacks[j](Event, Data, Result);
        except
          ModuleManager.ModLog.AddError('Event ' + Event + ' #' + IntToStr(j) + ' caused an exception');
        end;
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
      exit;
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
      end;
end;

procedure TEventManager.RemoveCallback(Callback: TEventCallback);
var
  i, j, k: Integer;
begin
  i := 0;
  while i <= high(fEvents) do
    begin
    j := 0;
    while j <= high(fEvents[i].Callbacks) do
      if (TMethod(fEvents[i].Callbacks[j]).Data = TMethod(Callback).Data) and (TMethod(fEvents[i].Callbacks[j]).Code = TMethod(Callback).Code) then
        begin
        for k := j + 1 to high(fEvents[i].Callbacks) do
          fEvents[i].Callbacks[k - 1] := fEvents[i].Callbacks[k];
        setLength(fEvents[i].Callbacks, length(fEvents[i].Callbacks) - 1);
        if length(fEvents[i].Callbacks) = 0 then
          begin
          fEvents[i] := fEvents[high(fEvents)];
          SetLength(fEvents, length(fEvents) - 1);
          dec(i);
          break;
          end;
        end
      else
        inc(j);
    inc(i);
    end;
end;

procedure TEventManager.RemoveCallback(Event: String; Callback: TEventCallback);
var
  i, j, k: Integer;
begin
  for i := 0 to high(fEvents) do
    if fEvents[i].Name = Event then
      begin
      j := 0;
      while j <= high(fEvents[i].Callbacks) do
        if (TMethod(fEvents[i].Callbacks[j]).Code = TMethod(Callback).Code) and (TMethod(fEvents[i].Callbacks[j]).Data = TMethod(Callback).Data) then
          begin
          for k := j + 1 to high(fEvents[i].Callbacks) do
            fEvents[i].Callbacks[k - 1] := fEvents[i].Callbacks[k];
          setLength(fEvents[i].Callbacks, length(fEvents[i].Callbacks) - 1);
          end
        else
          inc(j);
      end;
end;

end.