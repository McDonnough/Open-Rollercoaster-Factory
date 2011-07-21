unit m_scriptmng_bytecode;

interface

uses
  SysUtils, Classes, u_scripts, m_scriptmng_class, m_scriptmng_bytecode_compiler, m_scriptmng_bytecode_vm,
  m_scriptmng_bytecode_classes, m_scriptmng_bytecode_vm_runner, m_scriptmng_bytecode_compiler_assembler,
  m_scriptmng_bytecode_cmdlist, m_scriptmng_bytecode_compiler_code_generator;

type
  TModuleScriptManagerBytecode = class(TModuleScriptManagerClass)
    protected
      fCodeHandles: Array of TBytecodeScriptHandle;
      fScriptHandles: Array of TScriptInstanceHandle;
      fLastUsedCode: TBytecodeScriptHandle;
      fLastUsedScript: TScriptInstanceHandle;
      fVM: TScriptVM;
      fASM: TScriptAssembler;
      fCompiler: TScriptCompiler;
      fCommandList: TScriptCMDList;
      procedure SetScriptHandles(Script: TScript);
    public
      property VM: TScriptVM read fVM;
      property Compiler: TScriptCompiler read fCompiler;
      property Assembler: TScriptAssembler read fASM;
      property CommandList: TScriptCMDList read fCommandList;
      function GetLocation(Script: TScript; Bytes: Integer): PtrUInt;
      function GetRealPointer(Script: TScript; Location: PtrUInt): Pointer;
      procedure Execute(Script: TScript);
      procedure AddScript(Script: TScript);
      procedure DestroyScript(Script: TScript);
      procedure DestroyCode(Code: TScriptCode);
      procedure SetDataStructure(Name, Fields: String);
      procedure SetGlobal(Script: TScript; Name: String; Data: PByte; Bytes: Integer);
      function DataStructureSize(Name: String): PtrUInt;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_scene, m_varlist, u_particles, m_sound_class;

procedure TModuleScriptManagerBytecode.SetScriptHandles(Script: TScript);
var
  i: Integer;
begin
  if fLastUsedCode <> nil then
    if fLastUsedCode.Code <> Script.Code then
      fLastUsedCode := nil;
  if fLastUsedCode = nil then
    for i := 0 to high(fCodeHandles) do
      if fCodeHandles[i].Code = Script.Code then
        fLastUsedCode := fCodeHandles[i];

  if fLastUsedScript <> nil then
    if fLastUsedScript.Script <> Script then
      fLastUsedScript := nil;
  if fLastUsedScript = nil then
    for i := 0 to high(fScriptHandles) do
      if fScriptHandles[i].Script = Script then
        fLastUsedScript := fScriptHandles[i];
end;

function TModuleScriptManagerBytecode.GetLocation(Script: TScript; Bytes: Integer): PtrUInt;
begin
  SetScriptHandles(Script);
  Result := fLastUsedScript.GetLocation(Bytes);
end;

function TModuleScriptManagerBytecode.GetRealPointer(Script: TScript; Location: PtrUInt): Pointer;
begin
  SetScriptHandles(Script);
  Result := fLastUsedScript.GetRealPointer(Location);
end;

procedure TModuleScriptManagerBytecode.Execute(Script: TScript);
begin
  SetScriptHandles(Script);
  fLastUsedScript.Execute;
end;

procedure TModuleScriptManagerBytecode.AddScript(Script: TScript);
begin
  SetScriptHandles(Script);
  if fLastUsedScript <> nil then
    exit;
  if fLastUsedCode = nil then
    begin
    setLength(fCodeHandles, length(fCodeHandles) + 1);
    fCodeHandles[high(fCodeHandles)] := TBytecodeScriptHandle.Create;
    fCodeHandles[high(fCodeHandles)].Code := Script.Code;
    fCodeHandles[high(fCodeHandles)].Compile;
    fCodeHandles[high(fCodeHandles)].Assemble;
    end;
  SetLength(fScriptHandles, length(fScriptHandles) + 1);
  fScriptHandles[high(fScriptHandles)] := TScriptInstanceHandle.Create;
  fScriptHandles[high(fScriptHandles)].Script := Script;
  SetScriptHandles(Script);
  fScriptHandles[high(fScriptHandles)].CodeHandle := fLastUsedCode;
  fScriptHandles[high(fScriptHandles)].Init;
end;

procedure TModuleScriptManagerBytecode.DestroyScript(Script: TScript);
var
  i: Integer;
begin
  fLastUsedScript := nil;
  for i := 0 to high(fScriptHandles) do
    if fScriptHandles[i].Script = Script then
      begin
      fScriptHandles[i].Free;
      fScriptHandles[i] := fScriptHandles[high(fScriptHandles)];
      setLength(fScriptHandles, length(fScriptHandles) - 1);
      exit;
      end;
end;

procedure TModuleScriptManagerBytecode.DestroyCode(Code: TScriptCode);
var
  i: Integer;
begin
  fLastUsedCode := nil;
  fLastUsedScript := nil;
  for i := 0 to high(fCodeHandles) do
    if fCodeHandles[i].Code = Code then
      begin
      fCodeHandles[i].Free;
      fCodeHandles[i] := fCodeHandles[high(fCodeHandles)];
      setLength(fCodeHandles, length(fCodeHandles) - 1);
      exit;
      end;
end;

procedure TModuleScriptManagerBytecode.SetDataStructure(Name, Fields: String);
begin
  fCompiler.CodeGenerator.AddExternalStruct(Name, Fields);
end;

procedure TModuleScriptManagerBytecode.SetGlobal(Script: TScript; Name: String; Data: PByte; Bytes: Integer);
var
  FB: PByte;
  Offset: PtrUInt;
begin
  SetScriptHandles(Script);

  Offset := fLastUsedCode.GlobalLocations[Name];

  if Offset = 0 then
    exit;

  FB := fLastUsedScript.Stack.FirstByte + Offset;

  while Bytes > 0 do
    begin
    FB^ := Data^;
    inc(Data);
    inc(FB);
    dec(Bytes);
    end;
end;

function TModuleScriptManagerBytecode.DataStructureSize(Name: String): PtrUInt;
var
  S: TStruct;
begin
  S := fCompiler.CodeGenerator.GetExternalStruct(Name);
  if S <> nil then
    Result := S.GetSize
  else
    ModuleManager.ModLog.AddError('Extern struct ' + Name + ' not defined');
end;

procedure TModuleScriptManagerBytecode.CheckModConf;
begin
  fCommandList := TScriptCMDList.Create;
  fVM := TScriptVM.Create;
  fASM := TScriptAssembler.Create;
  fCompiler := TScriptCompiler.Create;

  TParticleGroup.RegisterStruct;
  TSoundSource.RegisterStruct;
  TLightSource.RegisterStruct;
  TMaterial.RegisterStruct;
  TBone.RegisterStruct;
  TArmature.RegisterStruct;
  TGeoMesh.RegisterStruct;
  TGeoObject.RegisterStruct;
end;

constructor TModuleScriptManagerBytecode.Create;
begin
  fModName := 'ScriptManagerBytecode';
  fModType := 'ScriptManager';

  fLastUsedCode := nil;
  fLastUsedScript := nil;
end;

destructor TModuleScriptManagerBytecode.Free;
begin
  fCompiler.Free;
  fASM.Free;
  fVM.Free;
  fCommandList.Free;
end;

end.