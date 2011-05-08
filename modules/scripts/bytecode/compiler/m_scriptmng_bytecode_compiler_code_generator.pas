unit m_scriptmng_bytecode_compiler_code_generator;

interface

uses
  SysUtils, Classes, m_scriptmng_bytecode_compiler_tree_generator, u_functions;

type
  EScriptCodeException = class(Exception);

  TASMTable = class
    Commands: Array of AString;
    procedure AddCommand(A: String);
    end;

  TVariable = class;
  TFunction = class;

  TStruct = class
    Name: String;
    External: Boolean;
    Fields: Array of TVariable;
    function GetField(FieldName: String): TVariable;
    function GetSize: PtrUInt;
    function Add: TVariable;
    constructor Create;
    destructor Free;
    end;

  TVariable = class
    InternalOffset: PtrUInt;
    Parent: TFunction;
    Name: String;
    DataType, PointerType: TDataType;
    Struct: TStruct;
    function GetTypeName: String;
    function GetSize: PtrUInt;
    constructor Create;
    end;

  TFunction = class
    Return: TVariable;
    Parameters: Array of TVariable;
    function GetFullName: String;
    function AddParam: TVariable;
    constructor Create;
    destructor Free;
    end;

  TCodeGenerator = class
    protected
      fVars: Array of TVariable;
      fStructs, fExternalStructs: Array of TStruct;
      fFunctions: Array of TFunction;
      fCurrentOffset: PtrUInt;
      fLabelID: Integer;
      function GetDatatype(Name: String): TDataType;
      function GetVar(Name: String; Scope: TFunction; MustExist: Boolean = True): TVariable;
      function GetFunction(Name: String; MustExist: Boolean = True): TFunction;
      function GetStruct(Name: String; MustExist: Boolean = True): TStruct;
      function AddVar(Name: String; Scope: TFunction): TVariable;
      function AddFunction(Name: String): TFunction;
      function AddStruct(Name: String): TStruct;
      function GetVarOffset(Name: String; Scope: TFunction): PtrUInt;
      function GetVarType(Name: String; Scope: TFunction): TDataType;
      function GetBuiltinFunction(A: String): String;
      function GetExternalStruct(Name: String): TStruct;
      procedure CreateExtStruct(Tree: TStatementTree);
      procedure CreateFunction(Tree: TStatementTree; Result: TASMTable);
      procedure ParsePointerDeclaration(Tree: TStatementTree; Variable: TVariable);
      procedure ParseDeclaration(Tree: TStatementTree; Variable: TVariable);
      procedure CreateStruct(Tree: TStatementTree);
      procedure GenBuiltin(Tree: TStatementTree; Result: TASMTable; Method: TFunction);
      procedure GenOperation(Tree: TStatementTree; Result: TASMTable; Scope: TFunction; WantedType: TDataType = dtInt);
      procedure GenIf(Tree: TStatementTree; Result: TASMTable; Scope: TFunction);
      procedure GenWhile(Tree: TStatementTree; Result: TASMTable; Scope: TFunction);
      procedure GenFor(Tree: TStatementTree; Result: TASMTable; Scope: TFunction);
      procedure GenDo(Tree: TStatementTree; Result: TASMTable; Scope: TFunction);
      procedure GenCode(Tree: TStatementTree; Method: TFunction; Result: TASMTable);
      procedure Cleanup;
    public
      procedure AddExternalStruct(Name, Fields: String);
      function GenerateCode(Tree: TStatementTree): TASMTable;
      destructor Free;
    end;

implementation

uses
  m_varlist;

procedure TASMTable.AddCommand(A: String);
begin
  SetLength(Commands, length(Commands) + 1);
  Commands[high(Commands)] := Explode(' ', A);
end;



function TStruct.GetField(FieldName: String): TVariable;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(Fields) do
    if Fields[i].Name = FieldName then
      Result := Fields[i];
end;

function TStruct.GetSize: PtrUInt;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to high(Fields) do
    Result := Result + Fields[i].GetSize;
end;

function TStruct.Add: TVariable;
begin
  Result := TVariable.Create;
  Result.InternalOffset := GetSize;
  SetLength(Fields, length(Fields) + 1);
  Fields[high(Fields)] := Result;
end;

constructor TStruct.Create;
begin
  External := False;
end;

destructor TStruct.Free;
var
  i: Integer;
begin
  for i := 0 to high(Fields) do
    Fields[i].Free;
end;


function TVariable.GetTypeName: String;
begin
  if DataType <> dtStruct then
    Result := DataTypeNames[DataType]
  else
    Result := Struct.Name;
end;

function TVariable.GetSize: PtrUInt;
begin
  if DataType <> dtStruct then
    Result := DataTypeSizes[DataType]
  else
    Result := Struct.GetSize;
end;

constructor TVariable.Create;
begin
  DataType := dtVoid;
  PointerType := dtVoid;
  Struct := nil;
  Parent := nil;
end;


function TFunction.GetFullName: String;
var
  i: Integer;
begin
  Result := Return.Name;
  for i := 0 to high(Parameters) do
    if Parameters[i].DataType <> dtStruct then
      Result := Result + ':' + Parameters[i].GetTypeName;
end;

function TFunction.AddParam: TVariable;
begin
  Result := TVariable.Create;
  SetLength(Parameters, length(Parameters) + 1);
  Parameters[high(Parameters)] := Result;
end;

constructor TFunction.Create;
begin
  Return := TVariable.Create;
end;

destructor TFunction.Free;
var
  i: Integer;
begin
  Return.Free;
  for i := 0 to high(Parameters) do
    Parameters[i].Free;
end;


function TCodeGenerator.GetExternalStruct(Name: String): TStruct;
var
  i: Integer;
begin
  for i := 0 to high(fExternalStructs) do
    if fExternalStructs[i].Name = Name then
      exit(fExternalStructs[i]);
  Result := nil;
end;

procedure TCodeGenerator.AddExternalStruct(Name, Fields: String);
var
  TheStruct: TStruct;
  i: Integer;
  F, G: AString;
begin
  if GetExternalStruct(Name) <> nil then
    ModuleManager.ModLog.AddError('Cannot redeclare external struct ' + Name)
  else
    begin
    TheStruct := TStruct.Create;
    TheStruct.Name := Name;
    TheStruct.External := True;

    F := Explode(#10, Fields);
    for i := 0 to high(F) do
      begin
      G := Explode(' ', F[i]);
      with TheStruct.Add do
        begin
        Name := G[1];
        DataType := GetDatatype(G[0]);
        if DataType = dtStruct then
          begin
          Struct := GetExternalStruct(G[0]);
          if Struct = nil then
            ModuleManager.ModLog.AddError('Extern struct ' + G[0] + ' not declared');
          end;
        end;
      end;
   
    SetLength(fExternalStructs, length(fExternalStructs) + 1);
    fExternalStructs[high(fExternalStructs)] := TheStruct;
    end;
end;

function TCodeGenerator.GetBuiltinFunction(A: String): String;
const
  Builtins: Array[0..10] of String = (
    'bool', 'int', 'pointer', 'float', 'vec2', 'vec3', 'vec4', 'mat4', 'write', 'sqrt', 'power');
var
  i: Integer;
begin
  for i := 0 to high(Builtins) do
    if Builtins[i] = A then
      exit(A);
  Result := '';
end;

procedure TCodeGenerator.GenBuiltin(Tree: TStatementTree; Result: TASMTable; Method: TFunction);
var
  F: String;
  i: Integer;
begin
  F := T.Tokens[Tree.Node.Token].Value;
  if F = 'write' then
    begin
    GenOperation(Tree.Children[0], Result, Method);
    case Tree.Children[0].Node.DataType of
      dtInt, dtBool, dtPointer:
        begin
        Result.AddCommand('POP I0');
        Result.AddCommand('WRITE I0');
        end;
      dtFloat, dtVec2, dtVec3, dtVec4:
        begin
        Result.AddCommand('POP R0');
        Result.AddCommand('WRITE R0');
        end;
      dtMat4:
        begin
        Result.AddCommand('POPM R0');
        Result.AddCommand('WRITE R0');
        Result.AddCommand('WRITE R1');
        Result.AddCommand('WRITE R2');
        Result.AddCommand('WRITE R3');
        end;
      end;
    Result.AddCommand(' ');
    end
// TEMPLATE
//   else if F = '' then
//     begin
//     end
  else if F = 'sqrt' then
    begin
    GenOperation(Tree.Children[0], Result, Method);
    Tree.Node.DataType := Tree.Children[0].Node.DataType;
    Result.AddCommand('POP R0');
    Result.AddCommand('SQRT R0 R0');
    Result.AddCommand('PUSH R0');
    Result.AddCommand(' ');
    end
  else if F = 'power' then
    begin
    GenOperation(Tree.Children[1], Result, Method);
    GenOperation(Tree.Children[0], Result, Method);
    Tree.Node.DataType := Tree.Children[0].Node.DataType;
    Result.AddCommand('POP R0');
    Result.AddCommand('POP R1');
    Result.AddCommand('POW R0 R1 R0');
    Result.AddCommand('PUSH R0');
    Result.AddCommand(' ');
    end
  else if F = 'bool' then
    begin
    Tree.Node.DataType := dtBool;
    if Tree.Children[0].Node.NodeType = ntDereference then
      GenOperation(Tree.Children[0], Result, Method, dtBool)
    else
      GenOperation(Tree.Children[0], Result, Method);
    end
  else if F = 'int' then
    begin
    Tree.Node.DataType := dtInt;
    if Tree.Children[0].Node.NodeType = ntDereference then
      GenOperation(Tree.Children[0], Result, Method, dtInt)
    else
      GenOperation(Tree.Children[0], Result, Method);
    end
  else if F = 'pointer' then
    begin
    Tree.Node.DataType := dtPointer;
    if Tree.Children[0].Node.NodeType = ntDereference then
      GenOperation(Tree.Children[0], Result, Method, dtPointer)
    else
      GenOperation(Tree.Children[0], Result, Method);
    end
  else if F = 'float' then
    begin
    Tree.Node.DataType := dtFloat;
    if Tree.Children[0].Node.NodeType = ntDereference then
      GenOperation(Tree.Children[0], Result, Method, dtFloat)
    else
      GenOperation(Tree.Children[0], Result, Method);
    end
  else if F = 'vec2' then
    begin
    Tree.Node.DataType := dtVec2;
    case Length(Tree.Children) of
      1:
        if Tree.Children[0].Node.NodeType = ntDereference then
          GenOperation(Tree.Children[0], Result, Method, dtVec2)
        else
          GenOperation(Tree.Children[0], Result, Method);
      2:
        begin
        for i := 0 to high(Tree.Children) do
          GenOperation(Tree.Children[i], Result, Method, dtFloat);
        Result.AddCommand('POP R2');
        Result.AddCommand('POP R1');
        Result.AddCommand('LD R0 0f 0f 0f 1f');
        Result.AddCommand('LD R0 0 R1 0');
        Result.AddCommand('LD R0 1 R2 0');
        Result.AddCommand('PUSH R0');
        end;
      end;
    end
  else if F = 'vec3' then
    begin
    Tree.Node.DataType := dtVec3;
    case Length(Tree.Children) of
      1:
        if Tree.Children[0].Node.NodeType = ntDereference then
          GenOperation(Tree.Children[0], Result, Method, dtVec3)
        else
          GenOperation(Tree.Children[0], Result, Method);
      3:
        begin
        for i := 0 to high(Tree.Children) do
          GenOperation(Tree.Children[i], Result, Method, dtFloat);
        Result.AddCommand('POP R3');
        Result.AddCommand('POP R2');
        Result.AddCommand('POP R1');
        Result.AddCommand('LD R0 0f 0f 0f 1f');
        Result.AddCommand('LD R0 0 R1 0');
        Result.AddCommand('LD R0 1 R2 0');
        Result.AddCommand('LD R0 2 R3 0');
        Result.AddCommand('PUSH R0');
        end;
      end;
    end
  else if F = 'vec4' then
    begin
    Tree.Node.DataType := dtVec4;
    case Length(Tree.Children) of
      1:
        if Tree.Children[0].Node.NodeType = ntDereference then
          GenOperation(Tree.Children[0], Result, Method, dtVec4)
        else
          GenOperation(Tree.Children[0], Result, Method);
      4:
        begin
        for i := 0 to high(Tree.Children) do
          GenOperation(Tree.Children[i], Result, Method, dtFloat);
        Result.AddCommand('POP R4');
        Result.AddCommand('POP R3');
        Result.AddCommand('POP R2');
        Result.AddCommand('POP R1');
        Result.AddCommand('LD R0 0f 0f 0f 1f');
        Result.AddCommand('LD R0 0 R1 0');
        Result.AddCommand('LD R0 1 R2 0');
        Result.AddCommand('LD R0 2 R3 0');
        Result.AddCommand('LD R0 3 R4 0');
        Result.AddCommand('PUSH R0');
        end;
      end;
    end
  else if F = 'mat4' then
    begin
    Tree.Node.DataType := dtMat4;
    case Length(Tree.Children) of
      1:
        if Tree.Children[0].Node.NodeType = ntDereference then
          GenOperation(Tree.Children[0], Result, Method, dtMat4)
        else
          GenOperation(Tree.Children[0], Result, Method);
      4:
        for i := 0 to high(Tree.Children) do
          GenOperation(Tree.Children[i], Result, Method, dtVec4);
      16:
        begin
        for i := 0 to high(Tree.Children) do
          GenOperation(Tree.Children[i], Result, Method, dtFloat);
        Result.AddCommand('POP R7');
        Result.AddCommand('POP R6');
        Result.AddCommand('POP R5');
        Result.AddCommand('POP R4');
        Result.AddCommand('LD R3 0 R4 0');
        Result.AddCommand('LD R3 1 R5 0');
        Result.AddCommand('LD R3 2 R6 0');
        Result.AddCommand('LD R3 3 R7 0');
        Result.AddCommand('POP R7');
        Result.AddCommand('POP R6');
        Result.AddCommand('POP R5');
        Result.AddCommand('POP R4');
        Result.AddCommand('LD R2 0 R4 0');
        Result.AddCommand('LD R2 1 R5 0');
        Result.AddCommand('LD R2 2 R6 0');
        Result.AddCommand('LD R2 3 R7 0');
        Result.AddCommand('POP R7');
        Result.AddCommand('POP R6');
        Result.AddCommand('POP R5');
        Result.AddCommand('POP R4');
        Result.AddCommand('LD R1 0 R4 0');
        Result.AddCommand('LD R1 1 R5 0');
        Result.AddCommand('LD R1 2 R6 0');
        Result.AddCommand('LD R1 3 R7 0');
        Result.AddCommand('POP R7');
        Result.AddCommand('POP R6');
        Result.AddCommand('POP R5');
        Result.AddCommand('POP R4');
        Result.AddCommand('LD R0 0 R4 0');
        Result.AddCommand('LD R0 1 R5 0');
        Result.AddCommand('LD R0 2 R6 0');
        Result.AddCommand('LD R0 3 R7 0');
        Result.AddCommand('PUSHM R0');
        end;
      end;
    end
end;

function TCodeGenerator.GetDatatype(Name: String): TDataType;
begin
  for Result := low(TDataType) to high(TDataType) do
    if Name = DataTypeNames[Result] then
      exit;
  Result := dtStruct;
end;

function TCodeGenerator.GetVar(Name: String; Scope: TFunction; MustExist: Boolean = True): TVariable;
var
  i: Integer;
  NameParts: AString;
begin
  Result := nil;
  NameParts := Explode('.', Name);
  for i := 0 to high(fVars) do
    if (NameParts[0] = fVars[i].Name) and ((fVars[i].Parent = nil) or (Scope = fVars[i].Parent)) then
      Result := fVars[i];
  if (Result = nil) and (MustExist) then
    begin
    ModuleManager.ModLog.AddError('Variable ' + NameParts[0] + ' not defined');
    raise EScriptCodeException.Create('Compilation aborted');
    end;
end;

function TCodeGenerator.GetVarOffset(Name: String; Scope: TFunction): PtrUInt;
var
  NameParts: AString;
  i: Integer;
  Struct: TStruct;
  Field: TVariable;
begin
  NameParts := Explode('.', Name);
  Result := 0;
  Struct := GetVar(Name, Scope).Struct;
  for i := 1 to high(NameParts) do
    if Struct <> nil then
      begin
      Field := Struct.GetField(NameParts[i]);
      if Field <> nil then
        begin
        inc(Result, Field.InternalOffset);
        Struct := Field.Struct;
        end
      else
        begin
        ModuleManager.ModLog.AddError('Struct ' + Struct.Name + ' does not have a field ' + NameParts[i]);
        raise EScriptCodeException.Create('Compilation aborted');
        end;
      end
    else
      begin
      ModuleManager.ModLog.AddError('Variable ' + NameParts[i - 1] + ' must be of struct type');
      raise EScriptCodeException.Create('Compilation aborted');
      end;
end;

function TCodeGenerator.GetVarType(Name: String; Scope: TFunction): TDataType;
var
  NameParts: AString;
  i: Integer;
  Struct: TStruct;
  Field: TVariable;
begin
  NameParts := Explode('.', Name);
  Field := GetVar(Name, Scope);
  Result := Field.DataType;
  Struct := Field.Struct;
  for i := 1 to high(NameParts) do
    if Struct <> nil then
      begin
      Field := Struct.GetField(NameParts[i]);
      if Field <> nil then
        begin
        Result := Field.DataType;
        Struct := Field.Struct;
        end
      else
        begin
        ModuleManager.ModLog.AddError('Struct ' + Struct.Name + ' does not have a field ' + NameParts[i]);
        raise EScriptCodeException.Create('Compilation aborted');
        end;
      end
    else
      begin
      ModuleManager.ModLog.AddError('Variable ' + NameParts[i - 1] + ' must be of struct type');
      raise EScriptCodeException.Create('Compilation aborted');
      end;
end;

function TCodeGenerator.GetFunction(Name: String; MustExist: Boolean = True): TFunction;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(fFunctions) do
    if fFunctions[i].Return.Name = Name then
      Result := fFunctions[i];
  if (Result = nil) and (MustExist) then
    begin
    ModuleManager.ModLog.AddError('Function ' + Name + ' not defined');
    raise EScriptCodeException.Create('Compilation aborted');
    end;
end;

function TCodeGenerator.GetStruct(Name: String; MustExist: Boolean = True): TStruct;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(fStructs) do
    if fStructs[i].Name = Name then
      Result := fStructs[i];
  if (Result = nil) and (MustExist) then
    begin
    ModuleManager.ModLog.AddError('Struct ' + Name + ' not defined');
    raise EScriptCodeException.Create('Compilation aborted');
    end;
end;

function TCodeGenerator.AddVar(Name: String; Scope: TFunction): TVariable;
begin
  Result := GetVar(Name, Scope, False);
  if Result <> nil then
    if Scope = Result.Parent then
      begin
      ModuleManager.ModLog.AddError('Cannot redeclare identifier ' + Name + ' in the same scope');
      raise EScriptCodeException.Create('Compilation aborted');
      end
    else
      ModuleManager.ModLog.AddWarning('Local identifier ' + Name + ' hides global variable with the same name');

  Result := TVariable.Create;
  Result.Name := Name;
  Result.Parent := Scope;

  SetLength(fVars, length(fVars) + 1);
  fVars[high(fVars)] := Result;
end;

function TCodeGenerator.AddFunction(Name: String): TFunction;
begin
  Result := GetFunction(Name, False);
  if Result <> nil then
    begin
    ModuleManager.ModLog.AddError('Cannot redeclare function ' + Name);
    raise EScriptCodeException.Create('Compilation aborted');
    end;

  Result := TFunction.Create;
  Result.Return.Name := Name;

  SetLength(fFunctions, length(fFunctions) + 1);
  fFunctions[high(fFunctions)] := Result;
end;

function TCodeGenerator.AddStruct(Name: String): TStruct;
begin
  Result := GetStruct(Name, False);
  if Result <> nil then
    begin
    ModuleManager.ModLog.AddError('Cannot redeclare struct ' + Name);
    raise EScriptCodeException.Create('Compilation aborted');
    end;

  Result := TStruct.Create;
  Result.Name := Name;

  SetLength(fStructs, length(fStructs) + 1);
  fStructs[high(fStructs)] := Result;
end;

procedure TCodeGenerator.ParseDeclaration(Tree: TStatementTree; Variable: TVariable);
begin
  Variable.Name := T.Tokens[Tree.Children[1].Node.Token].Value;
  Variable.DataType := GetDatatype(T.Tokens[Tree.Children[0].Node.Token].Value);
  if Variable.DataType = dtStruct then
    begin
    Variable.Struct := GetStruct(T.Tokens[Tree.Children[0].Node.Token].Value);
    if Variable.Struct = nil then
      begin
      ModuleManager.ModLog.AddError('Undefined datatype: ' + T.Tokens[Tree.Children[0].Node.Token].Value);
      raise EScriptCodeException.Create('Compilation aborted');
      end;
    end;
end;

procedure TCodeGenerator.ParsePointerDeclaration(Tree: TStatementTree; Variable: TVariable);
begin
  Variable.Name := T.Tokens[Tree.Children[1].Node.Token].Value;
  Variable.PointerType := GetDatatype(T.Tokens[Tree.Children[0].Node.Token].Value);
  Variable.DataType := dtPointer;
  if Variable.PointerType = dtStruct then
    begin
    Variable.Struct := GetStruct(T.Tokens[Tree.Children[0].Node.Token].Value);
    if Variable.Struct = nil then
      begin
      ModuleManager.ModLog.AddError('Undefined datatype: ' + T.Tokens[Tree.Children[0].Node.Token].Value);
      raise EScriptCodeException.Create('Compilation aborted');
      end;
    end;
end;

procedure TCodeGenerator.CreateStruct(Tree: TStatementTree);
var
  i: Integer;
  Struct: TStruct;
begin
  try
    Struct := AddStruct(T.Tokens[Tree.Children[0].Node.Token].Value);
    for i := 0 to high(Tree.Children[1].Children) do
      ParseDeclaration(Tree.Children[1].Children[i], Struct.Add);
  except
    ModuleManager.ModLog.AddError('Error in struct declaration');
    raise EScriptCodeException.Create('Compilation aborted');
  end;
end;

procedure TCodeGenerator.GenOperation(Tree: TStatementTree; Result: TASMTable; Scope: TFunction; WantedType: TDataType = dtInt);
  function OperatorInst(OP: String): String;
  const
    OrigOps: Array[0..17] of String = (
      '!', '*', '/', '%', '&', '+', '-', '|', '?', '<', '<=', '==', '>=', '>', '!=', '&&', '||', '??');
    OpInsts: Array[0..17] of String = (
      'NOT', 'MUL', 'DIV', 'MOD', 'AND', 'ADD', 'SUB', 'OR', 'XOR', 'LT', 'LE', 'EQ', 'GE', 'GT', 'NEQ', 'AND', 'OR', 'XOR');
  var
    i: Integer;
  begin
    for i := 0 to high(OrigOps) do
      if OrigOps[i] = OP then
        exit(OpInsts[i]);
    Result := 'NOP';
  end;
var
  i, PSize: Integer;
  TmpVar: TVariable;
  TmpFunction: TFunction;
  OP: String;
  ManualChildren: Boolean;
begin
  ManualChildren := False;

  if Tree.Node.NodeType = ntCall then
    if GetBuiltinFunction(T.Tokens[Tree.Node.Token].Value) <> '' then
      begin
      GenBuiltin(Tree, Result, Scope);
      Exit;
      end;

  case Tree.Node.NodeType of
    ntCall: ManualChildren := True;
    end;

  if not ManualChildren then
    for i := high(Tree.Children) downto 0 do
      GenOperation(Tree.Children[i], Result, Scope);

  case Tree.Node.NodeType of
    ntInt:
      begin
      Result.AddCommand('PUSH ' + T.Tokens[Tree.Node.Token].Value);
      Tree.Node.DataType := dtInt;
      end;
    ntFloat:
      begin
      Result.AddCommand('LD R0 ' + T.Tokens[Tree.Node.Token].Value + 'f');
      Result.AddCommand('PUSH R0');
      Tree.Node.DataType := dtFloat;
      end;
    ntCall:
      begin
      TmpFunction := GetFunction(T.Tokens[Tree.Node.Token].Value);
      Tree.Node.DataType := TmpFunction.Return.DataType;
      Result.AddCommand('LD I12 SP');
      Result.AddCommand('LD I0 ' + IntToStr(TmpFunction.Return.GetSize));
      Result.AddCommand('ADD I12 I0 I12');
      Result.AddCommand('LD SP I12');
      Result.AddCommand('SUB I12 I0 I12');
      Result.AddCommand(' ');

      PSize := 0;
      for i := 0 to high(Tree.Children) do
        begin
        GenOperation(Tree.Children[i], Result, Scope, TmpFunction.Parameters[i].DataType);
        Inc(PSize, TmpFunction.Parameters[i].GetSize);
        end;
      
      Result.AddCommand('CALL [@' + TmpFunction.GetFullName + ']');
      Result.AddCommand(' ');
      Result.AddCommand('LD I0 ' + IntToStr(TmpFunction.Return.GetSize));
      Result.AddCommand('ADD I12 I0 I12');
      Result.AddCommand('LD SP I12');
      Result.AddCommand(' ');
      end;
    ntIdentifier:
      begin
      TmpVar := GetVar(T.Tokens[Tree.Node.Token].Value, Scope);
      Result.AddCommand('LD I0 ' + IntToStr(TmpVar.InternalOffset));
      if TmpVar.Parent <> nil then
        Result.AddCommand('ADD I14 I0 I0');
      if (TmpVar.DataType = dtStruct) or ((TmpVar.DataType = dtPointer) and (TmpVar.PointerType = dtStruct)) then
        begin
        if TmpVar.DataType = dtPointer then
          Result.AddCommand('LD I0 [I0]');
        if GetVarOffset(T.Tokens[Tree.Node.Token].Value, Scope) > 0 then
          begin
          Result.AddCommand('LD I1 ' + IntToStr(GetVarOffset(T.Tokens[Tree.Node.Token].Value, Scope)));
          Result.AddCommand('ADD I0 I1 I0');
          end;
        end;
      Tree.Node.DataType := GetVarType(T.Tokens[Tree.Node.Token].Value, Scope);
      case Tree.Node.DataType of
        dtBool, dtPointer, dtInt:
          begin
          Result.AddCommand('LD I0 [I0]');
          Result.AddCommand('PUSH I0');
          end;
        dtFloat:
          begin
          Result.AddCommand('LD1 R0 [I0]');
          Result.AddCommand('PUSH R0');
          end;
        dtVec2:
          begin
          Result.AddCommand('LD2 R0 [I0]');
          Result.AddCommand('PUSH R0');
          end;
        dtVec3:
          begin
          Result.AddCommand('LD3 R0 [I0]');
          Result.AddCommand('PUSH R0');
          end;
        dtVec4:
          begin
          Result.AddCommand('LD R0 [I0]');
          Result.AddCommand('PUSH R0');
          end;
        dtMat4:
          begin
          Result.AddCommand('LD I1 ' + IntToStr(4 * SizeOf(Single)));
          Result.AddCommand('LD R0 [I0]');
          Result.AddCommand('ADD I0 I1 I0');
          Result.AddCommand('LD R1 [I0]');
          Result.AddCommand('ADD I0 I1 I0');
          Result.AddCommand('LD R2 [I0]');
          Result.AddCommand('ADD I0 I1 I0');
          Result.AddCommand('LD R3 [I0]');
          Result.AddCommand('PUSHM R0');
          end;
        end;
      end;
    ntDereference:
      begin
      Result.AddCommand('POP I0');
      case WantedType of
        dtInt, dtBool, dtPointer:
          begin
          Result.AddCommand('LD I0 [I0]');
          Result.AddCommand('PUSH I0');
          end;
        dtFloat:
          begin
          Result.AddCommand('LD1 R0 [I0]');
          Result.AddCommand('PUSH R0');
          end;
        dtVec2:
          begin
          Result.AddCommand('LD2 R0 [I0]');
          Result.AddCommand('PUSH R0');
          end;
        dtVec3:
          begin
          Result.AddCommand('LD3 R0 [I0]');
          Result.AddCommand('PUSH R0');
          end;
        dtVec4:
          begin
          Result.AddCommand('LD R0 [I0]');
          Result.AddCommand('PUSH R0');
          end;
        dtMat4:
          begin
          Result.AddCommand('LD I1 ' + IntToStr(4 * SizeOf(Single)));
          Result.AddCommand('LD R0 [I0]');
          Result.AddCommand('ADD I0 I1 I0');
          Result.AddCommand('LD R1 [I0]');
          Result.AddCommand('ADD I0 I1 I0');
          Result.AddCommand('LD R2 [I0]');
          Result.AddCommand('ADD I0 I1 I0');
          Result.AddCommand('LD R3 [I0]');
          Result.AddCommand('PUSHM R0');
          end;
        end;
      Tree.Node.DataType := WantedType;
      end;
    ntOperation:
      begin
      Op := T.Tokens[Tree.Node.Token].Value;
      Tree.Node.DataType := Tree.Children[0].Node.DataType;
      if (Op = '<') or (Op = '<=') or (Op = '==') or (Op = '>=') or (Op = '>') or (Op = '!=') then
        begin
        if Tree.Children[0].Node.DataType = Tree.Children[1].Node.DataType then
          begin
          Tree.Node.DataType := dtBool;
          case Tree.Children[0].Node.DataType of
            dtBool, dtInt, dtPointer:
              begin
              Result.AddCommand('POP I0');
              Result.AddCommand('POP I1');
              Result.AddCommand(OperatorInst(OP) + ' I0 I1');
              Result.AddCommand('PUSH I15');
              end;
            dtFloat, dtVec2, dtVec3, dtVec4:
              begin
              Result.AddCommand('POP R0');
              Result.AddCommand('POP R1');
              Result.AddCommand(OperatorInst(OP) + ' R0 R1 R0');
              Result.AddCommand('PUSH I15');
              end;
            end;
          end;
        end
      else if Op <> '!' then
        begin
        if Tree.Children[0].Node.DataType = Tree.Children[1].Node.DataType then
          begin
          case Tree.Node.DataType of
            dtBool, dtInt, dtPointer:
              begin
              Result.AddCommand('POP I0');
              Result.AddCommand('POP I1');
              Result.AddCommand(OperatorInst(OP) + ' I0 I1 I0');
              Result.AddCommand('PUSH I0');
              end;
            dtFloat, dtVec2, dtVec3, dtVec4:
              begin
              Result.AddCommand('POP R0');
              Result.AddCommand('POP R1');
              Result.AddCommand(OperatorInst(OP) + ' R0 R1 R0');
              Result.AddCommand('PUSH R0');
              end;
            dtMat4:
              begin
              Result.AddCommand('POPM R0');
              Result.AddCommand('POPM R4');
              Result.AddCommand('MULMM R0 R4 R0');
              Result.AddCommand('PUSHM R0');
              end;
            end;
          end
        else if (Tree.Children[0].Node.DataType = dtMat4) and (Tree.Children[1].Node.DataType = dtVec4) then
          begin
          Result.AddCommand('POPM R0');
          Result.AddCommand('POP R4');
          Result.AddCommand('MULMV R0 R4 R0');
          Result.AddCommand('PUSH R0');
          Tree.Node.DataType := dtVec4;
          end;
        end
      else
        begin
        Result.AddCommand('POP I0');
        Result.AddCommand('NOT I0 I0');
        Result.AddCommand('PUSH I0');
        end;
      end;
    end;
  Result.AddCommand(' ');
end;

procedure TCodeGenerator.GenIf(Tree: TStatementTree; Result: TASMTable; Scope: TFunction);
var
  i, FirstLabel, SecondLabel: Integer;
begin
  FirstLabel := fLabelID;
  SecondLabel := fLabelID + 1;
  inc(fLabelID, 2);

  GenOperation(Tree.Children[0], Result, Scope);

  Result.AddCommand('POP I0');
  Result.AddCommand('LD I1 0');
  Result.AddCommand('EQ I0 I1');
  Result.AddCommand('JMP0 [@_' + IntToStr(FirstLabel) + ']');
  Result.AddCommand(' ');

  // If block
  for i := 0 to high(Tree.Children[1].Children) do
    GenCode(Tree.Children[1].Children[i], Scope, Result);

  Result.AddCommand('JMP [@_' + IntToStr(SecondLabel) + ']');
  Result.AddCommand('@_' + IntToStr(FirstLabel));

  // Else block
  if Length(Tree.Children) > 2 then
    if Tree.Children[2].Node.NodeType = ntBlock then
      begin
      for i := 0 to high(Tree.Children[2].Children) do
        GenCode(Tree.Children[2].Children[i], Scope, Result);
      end
    else if Tree.Children[2].Node.NodeType = ntIf then
      GenIf(Tree.Children[2], Result, Scope);

  Result.AddCommand('@_' + IntToStr(SecondLabel));

  inc(fLabelID, 2);
end;

procedure TCodeGenerator.GenWhile(Tree: TStatementTree; Result: TASMTable; Scope: TFunction);
var
  i, FirstLabel, SecondLabel: Integer;
begin
  FirstLabel := fLabelID;
  SecondLabel := fLabelID + 1;
  inc(fLabelID, 2);

  Result.AddCommand('@_' + IntToStr(FirstLabel));

  GenOperation(Tree.Children[0], Result, Scope);

  Result.AddCommand('POP I0');
  Result.AddCommand('LD I1 0');
  Result.AddCommand('EQ I0 I1');
  Result.AddCommand('JMP0 [@_' + IntToStr(SecondLabel) + ']');
  Result.AddCommand(' ');

  for i := 0 to high(Tree.Children[1].Children) do
    GenCode(Tree.Children[1].Children[i], Scope, Result);

  Result.AddCommand('JMP [@_' + IntToStr(FirstLabel) + ']');
  Result.AddCommand('@_' + IntToStr(SecondLabel));
end;

procedure TCodeGenerator.GenDo(Tree: TStatementTree; Result: TASMTable; Scope: TFunction);
var
  i, FirstLabel: Integer;
begin
  FirstLabel := fLabelID;
  inc(fLabelID);

  Result.AddCommand('@_' + IntToStr(FirstLabel));

  for i := 0 to high(Tree.Children[0].Children) do
    GenCode(Tree.Children[0].Children[i], Scope, Result);

  GenOperation(Tree.Children[1], Result, Scope);

  Result.AddCommand('POP I15');
  Result.AddCommand('JMP0 [@_' + IntToStr(FirstLabel) + ']');
  Result.AddCommand(' ');
end;

procedure TCodeGenerator.GenFor(Tree: TStatementTree; Result: TASMTable; Scope: TFunction);
var
  i, FirstLabel, SecondLabel: Integer;
begin
  FirstLabel := fLabelID;
  SecondLabel := fLabelID + 1;
  inc(fLabelID, 2);

  GenCode(Tree.Children[0], Scope, Result);

  Result.AddCommand('@_' + IntToStr(FirstLabel));
  GenOperation(Tree.Children[1], Result, Scope);

  Result.AddCommand('POP I0');
  Result.AddCommand('LD I1 0');
  Result.AddCommand('EQ I0 I1');
  Result.AddCommand('JMP0 [@_' + IntToStr(SecondLabel) + ']');
  Result.AddCommand(' ');

  for i := 0 to high(Tree.Children[3].Children) do
    GenCode(Tree.Children[3].Children[i], Scope, Result);

  GenCode(Tree.Children[2], Scope, Result);
  
  Result.AddCommand('JMP [@_' + IntToStr(FirstLabel) + ']');
  Result.AddCommand('@_' + IntToStr(SecondLabel));
end;

procedure TCodeGenerator.GenCode(Tree: TStatementTree; Method: TFunction; Result: TASMTable);
var
  TmpVar: TVariable;
  TmpFunction: TFunction;
  i, PSize: Integer;
begin
  if Tree.Node.NodeType = ntCall then
    if GetBuiltinFunction(T.Tokens[Tree.Node.Token].Value) <> '' then
      begin
      GenBuiltin(Tree, Result, Method);
      Exit;
      end;

  case Tree.Node.NodeType of
    ntIf:
      GenIf(Tree, Result, Method);
    ntWhile:
      GenWhile(Tree, Result, Method);
    ntFor:
      GenFor(Tree, Result, Method);
    ntDo:
      GenDo(Tree, Result, Method);
    ntDeclaration:
      begin
      ParseDeclaration(Tree, AddVar(T.Tokens[Tree.Node.Token + 1].Value, Method));
      fVars[high(fVars)].InternalOffset := fCurrentOffset;
      fCurrentOffset := fCurrentOffset + fVars[high(fVars)].GetSize;
      end;
    ntCall:
      begin
      TmpFunction := GetFunction(T.Tokens[Tree.Node.Token].Value);
      Tree.Node.DataType := TmpFunction.Return.DataType;
      Result.AddCommand('LD I12 SP');
      Result.AddCommand('LD I0 ' + IntToStr(TmpFunction.Return.GetSize));
      Result.AddCommand('ADD I12 I0 I12');
      Result.AddCommand('LD SP I12');
      Result.AddCommand('SUB I12 I0 I12');
      Result.AddCommand(' ');

      PSize := 0;
      for i := 0 to high(Tree.Children) do
        begin
        GenOperation(Tree.Children[i], Result, Method, TmpFunction.Parameters[i].DataType);
        Inc(PSize, TmpFunction.Parameters[i].GetSize);
        end;

      Result.AddCommand('CALL [@' + TmpFunction.GetFullName + ']');
      Result.AddCommand(' ');
      Result.AddCommand('LD SP I12');
      Result.AddCommand(' ');
      end;
    ntAssignment:
      begin
      GenOperation(Tree.Children[1], Result, Method);
      case Tree.Children[0].Node.NodeType of
        ntDeclaration:
          begin
          if GetDatatype(T.Tokens[Tree.Children[0].Children[0].Node.Token].Value) = dtStruct then
            ParsePointerDeclaration(Tree.Children[0], AddVar(T.Tokens[Tree.Children[0].Children[1].Node.Token].Value, Method))
          else
            ParseDeclaration(Tree.Children[0], AddVar(T.Tokens[Tree.Children[0].Children[1].Node.Token].Value, Method));
          fVars[high(fVars)].InternalOffset := fCurrentOffset;
          if Method = nil then
            Result.AddCommand('LD I0 ' + IntToStr(fCurrentOffset))
          else
            begin
            Result.AddCommand('LD I1 ' + IntToStr(fCurrentOffset));
            Result.AddCommand('ADD I14 I1 I0');
            end;
          fCurrentOffset := fCurrentOffset + fVars[high(fVars)].GetSize;
          TmpVar := fVars[high(fVars)];
          end;
        ntIdentifier:
          begin
          TmpVar := GetVar(T.Tokens[Tree.Node.Token].Value, Method);
          Result.AddCommand('LD I0 ' + IntToStr(TmpVar.InternalOffset));
          if TmpVar.Parent <> nil then
            Result.AddCommand('ADD I14 I0 I0');
          if (TmpVar.DataType = dtStruct) or ((TmpVar.DataType = dtPointer) and (TmpVar.PointerType = dtStruct)) then
            begin
            if (T.Tokens[Tree.Node.Token].Value <> TmpVar.Name) and (TmpVar.DataType = dtPointer) then
              Result.AddCommand('LD I0 [I0]');
            if GetVarOffset(T.Tokens[Tree.Node.Token].Value, Method) > 0 then
              begin
              Result.AddCommand('LD I1 ' + IntToStr(GetVarOffset(T.Tokens[Tree.Node.Token].Value, Method)));
              Result.AddCommand('ADD I0 I1 I0');
              end;
            end;
          end;
        ntDereference:
          begin
          TmpVar := nil;
          GenOperation(Tree.Children[0].Children[0], Result, Method);
          Result.AddCommand('POP I0');
          end;
        end;
      case Tree.Children[1].Node.DataType of
        dtInt, dtPointer, dtBool:
          begin
          Result.AddCommand('POP I1');
          Result.AddCommand('LD [I0] I1');
          end;
        dtFloat:
          begin
          Result.AddCommand('POP R0');
          Result.AddCommand('LD1 [I0] R0');
          end;
        dtVec2:
          begin
          Result.AddCommand('POP R0');
          Result.AddCommand('LD2 [I0] R0');
          end;
        dtVec3:
          begin
          Result.AddCommand('POP R0');
          Result.AddCommand('LD3 [I0] R0');
          end;
        dtVec4:
          begin
          Result.AddCommand('POP R0');
          Result.AddCommand('LD [I0] R0');
          end;
        dtMat4:
          begin
          Result.AddCommand('POPM R0');
          Result.AddCommand('LD I1 ' + IntToStr(4 * SizeOf(Single)));
          Result.AddCommand('LD [I0] R0');
          Result.AddCommand('ADD I0 I1 I0');
          Result.AddCommand('LD [I0] R1');
          Result.AddCommand('ADD I0 I1 I0');
          Result.AddCommand('LD [I0] R2');
          Result.AddCommand('ADD I0 I1 I0');
          Result.AddCommand('LD [I0] R3');
          end;
        end;
      if Tree.Children[0].Node.NodeType = ntDeclaration then
        begin
        Result.AddCommand('LD I2 ' + IntToStr(fVars[high(fVars)].GetSize));
        Result.AddCommand('LD I1 SP');
        Result.AddCommand('ADD I1 I2 I1');
        Result.AddCommand('LD SP I1');
      end;
      Result.AddCommand(' ');
      end;
    end;
end;

procedure TCodeGenerator.CreateFunction(Tree: TStatementTree; Result: TASMTable);
var
  F: TFunction;
  V: TVariable;
  i: Integer;
begin
  fCurrentOffset := 0;
  
  F := AddFunction(T.Tokens[Tree.Node.Token + 1].Value);
  F.Return.DataType := GetDatatype(T.Tokens[Tree.Node.Token].Value);
  if F.Return.DataType = dtStruct then
    F.Return.Struct := GetStruct(T.Tokens[Tree.Node.Token].Value);

  if F.GetFullName <> 'main' then
    begin
    V := AddVar('result', F);
    V.DataType := F.Return.DataType;
    V.Struct := F.Return.Struct;
    V.InternalOffset := fCurrentOffset;
    inc(fCurrentOffset, V.GetSize);

    for i := 0 to high(Tree.Children[0].Children) do
      begin
      V := F.AddParam;
      ParseDeclaration(Tree.Children[0].Children[i], V);
      V.InternalOffset := fCurrentOffset;
      inc(fCurrentOffset, V.GetSize);
      with AddVar(V.Name, F) do
        begin
        InternalOffset := V.InternalOffset;
        DataType := V.DataType;
        Struct := V.Struct;
        end;
      end;

    inc(fCurrentOffset, 3 * SizeOf(Pointer));
    end;

  Result.AddCommand('@' + F.GetFullName);
  if F.GetFullName = 'main' then
    Result.AddCommand('LD I14 SP')
  else
    begin
    Result.AddCommand('PUSH I13');
    Result.AddCommand('PUSH I14');
    Result.AddCommand('LD I14 I12');
    end;
  Result.AddCommand('LD I13 SP');
  Result.AddCommand(' ');

  for i := 0 to high(Tree.Children[1].Children) do
    GenCode(Tree.Children[1].Children[i], F, Result);

  Result.AddCommand('LD SP I13');

  if F.GetFullName = 'main' then
    Result.AddCommand('JMP [0]')
  else
    begin
    Result.AddCommand('LD I12 I14');
    Result.AddCommand('POP I14');
    Result.AddCommand('POP I13');
    Result.AddCommand('RET');
    end;
  Result.AddCommand(' ');
end;

procedure TCodeGenerator.CreateExtStruct(Tree: TStatementTree);
var
  ExtStruct: TStruct;
begin
  ExtStruct := GetExternalStruct(T.Tokens[Tree.Children[0].Node.Token].Value);
  if ExtStruct = nil then
    begin
    ModuleManager.ModLog.AddError('External Struct ' + T.Tokens[Tree.Children[0].Node.Token].Value + ' not declared');
    raise EScriptCodeException.Create('Compilation aborted');
    end
  else
    begin
    SetLength(fStructs, length(fStructs) + 1);
    fStructs[high(fStructs)] := ExtStruct;
    end;
end;

function TCodeGenerator.GenerateCode(Tree: TStatementTree): TASMTable;
var
  i: Integer;
  FinishedInitProcedure: Boolean;
begin
  fLabelID := 0;
  fCurrentOffset := SizeOf(Pointer);

  try
    Result := TASMTable.Create;
    Result.AddCommand('@__INIT__');
    Result.AddCommand('LD I0 ' + IntToStr(fCurrentOffset));
    Result.AddCommand('LD SP I0');
    Result.AddCommand(' ');

    FinishedInitProcedure := False;

    for i := 0 to high(Tree.Children) do
      case Tree.Children[i].Node.NodeType of
        ntStruct: CreateStruct(Tree.Children[i]);
        ntExternStruct: CreateExtStruct(Tree.Children[i]);
        ntFunction:
          begin
          if not FinishedInitProcedure then
            begin
            Result.AddCommand('LD I0 SP');
            Result.AddCommand('LD I1 0');
            Result.AddCommand('LD [I1] I0');
            Result.AddCommand('JMP [0]');
            Result.AddCommand(' ');
            end;
          FinishedInitProcedure := True;
          CreateFunction(Tree.Children[i], Result);
          end;
        else
          if FinishedInitProcedure then
            begin
            ModuleManager.ModLog.AddError('Commands outside a function are not allowed after a function');
            raise EScriptCodeException.Create('Compilation aborted');
            end
          else
            GenCode(Tree.Children[i], nil, Result);
        end;

    if not FinishedInitProcedure then
      begin
      Result.AddCommand('LD I0 SP');
      Result.AddCommand('LD I1 0');
      Result.AddCommand('LD [I1] I0');
      Result.AddCommand('JMP [0]');
      Result.AddCommand(' ');
      end;
  except
    Cleanup;
    raise EScriptCodeException.Create('Compilation aborted');
  end;
  Cleanup;
end;

procedure TCodeGenerator.Cleanup;
var
  i: Integer;
begin
  for i := 0 to high(fStructs) do
    if not fStructs[i].External then
      fStructs[i].Free;
  SetLength(fStructs, 0);
  for i := 0 to high(fFunctions) do
    fFunctions[i].Free;
  SetLength(fFunctions, 0);
  for i := 0 to high(fVars) do
    fVars[i].Free;
  SetLength(fVars, 0);
end;

destructor TCodeGenerator.Free;
begin
end;

end.