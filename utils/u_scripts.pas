unit u_scripts;

interface

uses
  SysUtils, Classes;

type
  TScript = class;

  TScriptCode = class
    protected
      fSourceCode: String;
    public
      Name: String;
      property SourceCode: String read fSourceCode;
      function CreateInstance: TScript;
      constructor Create(Code: String);
      destructor Free;
    end;

  TScript = class
    private
      fCode: TScriptCode;
    public
      property Code: TScriptCode read fCode;
      procedure Execute;
      procedure SetInVar(Name: String; Location: Pointer);
      procedure SetInOutVar(Name: String; Location: Pointer);
      destructor Free;
    end;
  

implementation

uses
  m_varlist;

function TScriptCode.CreateInstance: TScript;
begin
  Result := TScript.Create;
  Result.fCode := self;
  ModuleManager.ModScriptManager.AddScript(Result);
end;

constructor TScriptCode.Create(Code: String);
begin
  fSourceCode := Code;
end;

destructor TScriptCode.Free;
begin
  ModuleManager.ModScriptManager.DestroyCode(Self);
end;


procedure TScript.Execute;
begin
  ModuleManager.ModScriptManager.Execute(Self);
end;

procedure TScript.SetInVar(Name: String; Location: Pointer);
begin
  ModuleManager.ModScriptManager.SetInVar(Self, Name, Location);
end;

procedure TScript.SetInOutVar(Name: String; Location: Pointer);
begin
  ModuleManager.ModScriptManager.SetInOutVar(Self, Name, Location);
end;

destructor TScript.Free;
begin
  ModuleManager.ModScriptManager.DestroyScript(Self);
end;


end.