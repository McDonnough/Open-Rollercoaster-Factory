unit m_renderer_opengl_interface;

interface

uses
  SysUtils, Classes, u_functions;

type
  TRendererOpenGLInterface = class
    protected
      fOptions: TDictionary;
      fOptionStack: Array of TDictionary;
    public
      property Options: TDictionary read fOptions;
      function Option(O: String; D: Integer): Integer;
      function Option(O: String; D: String): String;
      procedure PushOptions;
      procedure PopOptions;
      constructor Create;
      destructor Free;
    end;

var
  FInterface: TRendererOpenGLInterface = nil;

implementation

uses
  m_varlist;

function TRendererOpenGLInterface.Option(O: String; D: Integer): Integer;
begin
  Result := D;
  if Options.Items[O] <> '' then
    try
      Result := StrToInt(Options.Items[O]);
    except
    end
  else
    Options.Items[O] := IntToStr(D);
end;

function TRendererOpenGLInterface.Option(O: String; D: String): String;
begin
  Result := D;
  if Options.Items[O] <> '' then
    Result := Options.Items[O]
  else
    Options.Items[O] := D;
end;

procedure TRendererOpenGLInterface.PushOptions;
var
  i: Integer;
begin
  fInterface := Self;
  setLength(fOptionStack, length(fOptionStack) + 1);
  fOptionStack[high(fOptionStack)] := fOptions;
  fOptions := TDictionary.Create;
  fOptions.Assign(fOptionStack[high(fOptionStack)]);
end;

procedure TRendererOpenGLInterface.PopOptions;
begin
  fInterface := Self;
  fOptions.Free;
  fOptions := fOptionStack[high(fOptionStack)];
  setLength(fOptionStack, length(fOptionStack) - 1);
end;

constructor TRendererOpenGLInterface.Create;
begin
  fInterface := Self;
  fOptions := TDictionary.Create;
end;

destructor TRendererOpenGLInterface.Free;
begin
  fInterface := nil;
  fOptions.Free;
end;

end.