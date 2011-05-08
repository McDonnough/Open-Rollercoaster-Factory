unit m_scriptmng_bytecode_compiler_tree_generator;

interface

uses
  SysUtils, Classes, m_scriptmng_bytecode_compiler_tokenizer, math;

type
  EScriptTreeException = class(Exception);

  TTreeNodeType = (ntScript, ntAssignment, ntDeclaration, ntExternStruct, ntIdentifier, ntStruct, ntFunction, ntCall, ntBlock,
    ntIf, ntFor, ntWhile, ntDo, ntOperation, ntInt, ntFloat, ntDereference, ntParameters);

  TDataType = (dtVoid, dtInt, dtBool, dtFloat, dtVec2, dtVec3, dtVec4, dtMat4, dtPointer, dtStruct);

  TStatementTreeNode = record
    Token: Integer;
    NodeType: TTreeNodeType;
    DataType: TDataType;
    end;

  TStatementTree = class
    Node: TStatementTreeNode;
    Children: Array of TStatementTree;
    procedure AddChild(C: TStatementTree);
    constructor Create;
    end;

  TStatementTreeGenerator = class
    protected
    public
      function GenerateTree(Tokens: TTokenList): TStatementTree;
    end;

const
  TreeNodeTypeNames: Array[TTreeNodeType] of String = (
    'SCRIPT', '=', 'DECL', 'EXTSTRUCT', 'IDENT', 'STRUCT', 'FUNCTION', 'CALL', 'BLOCK', 'IF', 'FOR', 'WHILE', 'DO', 'OP',
    'INT', 'FLOAT', 'DEREF', 'PARAM');

  DataTypeNames: Array[TDataType] of String = (
    'void', 'int', 'bool', 'float', 'vec2', 'vec3', 'vec4', 'mat4', 'pointer', '#STRUCT');

  DataTypeSizes: Array[TDataType] of PtrUInt = (
    0, SizeOf(Pointer), SizeOf(Pointer), 4 * SizeOf(Single), 4 * SizeOf(Single), 4 * SizeOf(Single), 4 * SizeOf(Single), 16 * SizeOf(Single), SizeOf(Pointer), 0);

var
  T: TTokenList;

function OperationTree(var Start: Integer; Last: Integer): TStatementTree;
function BlockTree(var Start: integer): TStatementTree;

implementation

uses
  m_varlist, u_functions;

constructor TStatementTree.Create;
begin
  Node.DataType := dtVoid;
end;

procedure TStatementTree.AddChild(C: TStatementTree);
begin
  SetLength(Children, length(Children) + 1);
  Children[high(Children)] := C;
end;

procedure OutputTree(Tree: TStatementTree; Prefix: String = '');
var
  i: Integer;
begin
  if Tree.Node.Token >= 0 then
    writeln(Prefix + TreeNodeTypeNames[Tree.Node.NodeType] + ': ' + T.Tokens[Tree.Node.Token].Value)
  else
    writeln(Prefix + TreeNodeTypeNames[Tree.Node.NodeType]);
  for i := 0 to high(Tree.Children) do
    OutputTree(Tree.Children[i], Prefix + '  ');
end;



function GetNextOfType(TType: TScriptTokenType; Position: Integer): Integer;
begin
  while Position <= high(T.Tokens) do
    if T.Tokens[Position].TType = TType then
      exit(Position)
    else
      inc(Position);
  Result := -1;
end;

procedure ErrLine(TokenID: Integer);
begin
  ModuleManager.ModLog.AddError('Line ' + IntToStr(T.Tokens[TokenID].Line) + ':');
end;

procedure Expect(TokenID: Integer; TType: TScriptTokenType; ForcedValue: String = '');
var
  E: String;
begin
  if (T.Tokens[TokenID].TType <> TType) or ((ForcedValue <> '') and (T.Tokens[TokenID].Value <> ForcedValue)) then
    begin
    ErrLine(TokenID);
    if ForcedValue <> '' then
      E := 'Expected "' + ForcedValue + '" but got "' + T.Tokens[TokenID].Value + '"'
    else
      E := 'Expected ' + ScriptTokenTypeNames[TType] + ' but got "' + T.Tokens[TokenID].Value + '"';
    ModuleManager.ModLog.AddError(E);
    raise EScriptTreeException.Create('Compilation aborted');
    end;
end;

function IdentifierNode(Token: Integer): TStatementTree;
begin
  Result := TStatementTree.Create;
  Result.Node.NodeType := ntIdentifier;
  Result.Node.Token := Token;
end;

function ExternStructTree(var Start: Integer): TStatementTree;
begin
  Result := TStatementTree.Create;
  Result.Node.NodeType := ntExternStruct;
  Result.Node.Token := Start;

  Expect(Start, stKeyword, 'extern');
  Expect(Start + 1, stKeyword, 'struct');
  Expect(Start + 2, stIdentifier);
  Expect(Start + 3, stSemicolon);

  Result.AddChild(IdentifierNode(Start + 2));

  inc(Start, 4);
end;

function DeclarationTree(var Start: Integer; ExpectSemicolon: Boolean = True): TStatementTree;
begin
  Result := TStatementTree.Create;
  Result.Node.NodeType := ntDeclaration;
  Result.Node.Token := Start;

  Expect(Start, stDataType);
  Expect(Start + 1, stIdentifier);
  if ExpectSemicolon then
    Expect(Start + 2, stSemicolon);

  if StrPos(T.Tokens[Start + 1].Value, '.') <> -1 then
    begin
    ErrLine(Start + 1);
    ModuleManager.ModLog.AddError('Invalid identifier name: ' + T.Tokens[Start + 1].Value);
    raise EScriptTreeException.Create('Compilation aborted');
    end;

  Result.AddChild(IdentifierNode(Start));
  Result.AddChild(IdentifierNode(Start + 1));

  if ExpectSemicolon then
    inc(Start, 3)
  else
    inc(Start, 2);
end;

function NumTree(var Start: Integer): TStatementTree;
begin
  Result := TStatementTree.Create;
  Result.Node.Token := Start;
  if T.Tokens[Start].TType = stFloat then
    Result.Node.NodeType := ntFloat
  else if T.Tokens[Start].TType = stInt then
    Result.Node.NodeType := ntInt
  else if T.Tokens[Start].TType = stIdentifier then
    Result.Node.NodeType := ntIdentifier
  else
    begin
    ErrLine(Start);
    ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stFloat] + ', ' + ScriptTokenTypeNames[stInt] + ' but got "' + T.Tokens[Start].Value + '"');
    raise EScriptTreeException.Create('Compilation aborted');
    end;
  inc(Start);
end;

function GetLowPriorityOperator(Start, Last: Integer; Priority: Integer = 6): Integer;
var
  CurrentOperator, Parentheses: Integer;
  V: String;
begin
  Parentheses := 0;
  Result := -1;
  for CurrentOperator := Start to Last do
    case T.Tokens[CurrentOperator].TType of
      stParentheseL: Inc(Parentheses);
      stParentheseR: Dec(Parentheses);
      stOperator, stDereference:
        if Parentheses = 0 then
          begin
          V := T.Tokens[CurrentOperator].Value;
          case Priority of
            6: if (V = '||') or (V = '??') then exit(CurrentOperator);
            5: if (V = '&&') then exit(CurrentOperator);
            4: if (V = '<') or (V = '<=') or (V = '==') or (V = '>=') or (V = '>') or (V = '!=') then exit(CurrentOperator);
            3: if (V = '+') or (V = '-') or (V = '|') or (V = '?') then exit(CurrentOperator);
            2: if (V = '*') or (V = '/') or (V = '&') or (V = '%') then exit(CurrentOperator);
            1: if (V = '!') then exit(CurrentOperator);
            0: if (V = '^') then Result := CurrentOperator;
            end;
          end;
      end;
  if Priority > 0 then
    Result := GetLowPriorityOperator(Start, Last, Priority - 1);
end;

function FunctionCallTree(var Start: Integer): TStatementTree;
var
  i, OperationStart, Parentheses, VeryLast: Integer;
begin
  Result := TStatementTree.Create;
  Result.Node.NodeType := ntCall;
  Result.Node.Token := Start;

  Expect(Start, stIdentifier);
  Expect(Start + 1, stParentheseL);

  Parentheses := 1;
  VeryLast := Start + 1;
  while Parentheses <> 0 do
    begin
    inc(VeryLast);
    if VeryLast > high(T.Tokens) then
      begin
      ErrLine(Start + 1);
      ModuleManager.ModLog.AddError('Unmatched (');
      raise EScriptTreeException.Create('Compilation aborted');
      end
    else
      if T.Tokens[VeryLast].TType = stParentheseL then
        inc(Parentheses)
      else if T.Tokens[VeryLast].TType = stParentheseR then
        dec(Parentheses);
    end;

  Inc(Start, 2);
  OperationStart := Start;

  Parentheses := 0;

  for i := Start to VeryLast - 1 do
    case T.Tokens[i].TType of
      stParentheseL: inc(Parentheses);
      stParentheseR: dec(Parentheses);
      stComma:
        if Parentheses = 0 then
          begin
          Result.AddChild(OperationTree(OperationStart, i - 1));
          OperationStart := i + 1;
          end;
      end;
  if OperationStart < VeryLast then
    Result.AddChild(OperationTree(OperationStart, VeryLast - 1));
  Start := VeryLast + 1;
end;

function OperationTree(var Start: Integer; Last: Integer): TStatementTree;
var
  i, OperatorToken, Parentheses: Integer;
begin
  if Start > Last then
    begin
    ErrLine(Last);
    ModuleManager.ModLog.AddError('Missing command');
    raise EScriptTreeException.Create('Compilation aborted');
    end
  else if Start = Last then
    Result := NumTree(Start)
  else
    begin
    // Remove meaningless parentheses
    Parentheses := 0;

    for i := Start to Last do
      if T.Tokens[i].TType = stParentheseL then
        inc(Parentheses)
      else if T.Tokens[i].TType = stParentheseR then
        begin
        dec(Parentheses);
        if i = Last then
          begin
          inc(Start);
          exit(OperationTree(Start, Last - 1));
          end;
        end
      else if Parentheses = 0 then
        break;

    // Check for unmatched parentheses
    Parentheses := 0;

    for i := Start to Last do
      if T.Tokens[i].TType = stParentheseL then
        inc(Parentheses)
      else if T.Tokens[i].TType = stParentheseR then
        begin
        dec(Parentheses);
        if Parentheses < 0 then
          begin
          ErrLine(i);
          ModuleManager.ModLog.AddError('Unmatched )');
          raise EScriptTreeException.Create('Compilation aborted');
          end;
        end;

    if Parentheses <> 0 then
      begin
      ErrLine(Last);
      ModuleManager.ModLog.AddError('Unmatched (');
      raise EScriptTreeException.Create('Compilation aborted');
      end;

    // Get lowest operator
    OperatorToken := GetLowPriorityOperator(Start, Last);

    // Nothing? => function call
    if OperatorToken = -1 then
      Exit(FunctionCallTree(Start));

    // Operator exists - create subtree
    Result := TStatementTree.Create;
    Result.Node.NodeType := ntOperation;
    if T.Tokens[OperatorToken].TType = stDereference then
      Result.Node.NodeType := ntDereference;
    Result.Node.Token := OperatorToken;
    if Start <> OperatorToken then
      Result.AddChild(OperationTree(Start, OperatorToken - 1));
    Start := OperatorToken + 1;
    if Last <> OperatorToken then
      Result.AddChild(OperationTree(Start, Last));
    end;
  Start := Last + 2;
end;

function DereferenceTree(var Start: Integer; Last: Integer): TStatementTree;
begin
  Result := TStatementTree.Create;
  Result.Node.Token := Last;
  Result.Node.NodeType := ntDereference;

  Expect(Last, stDereference);
  Result.AddChild(OperationTree(Start, Last - 1));
  Start := Last + 1;
end;

function AssignmentTree(var Start: integer; AssignmentSign: Integer; ForcedEnd: Integer = -1): TStatementTree;
var
  StatementEnd: Integer;
begin
  Result := TStatementTree.Create;
  Result.Node.NodeType := ntAssignment;
  Result.Node.Token := Start;

  Expect(AssignmentSign, stAssign);

  if T.Tokens[AssignmentSign - 1].TType = stDereference then
    Result.AddChild(DereferenceTree(Start, AssignmentSign - 1))
  else if T.Tokens[Start].TType = stDataType then
    Result.AddChild(DeclarationTree(Start, false))
  else if T.Tokens[Start].TType = stIdentifier then
    Result.AddChild(IdentifierNode(Start))
  else
    begin
    ErrLine(Start);
    ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stDataType] + ', '
                                                     + ScriptTokenTypeNames[stIdentifier] + ' but got "' + T.Tokens[Start].Value + '"');
    raise EScriptTreeException.Create('Compilation aborted');
    end;

  if ForcedEnd < 0 then
    StatementEnd := GetNextOfType(stSemicolon, AssignmentSign)
  else
    StatementEnd := ForcedEnd;

  if StatementEnd = -1 then
    begin
    ErrLine(AssignmentSign);
    ModuleManager.ModLog.AddError('Missing ;');
    raise EScriptTreeException.Create('Compilation aborted');
    end;

  Start := AssignmentSign + 1;

  Result.AddChild(OperationTree(Start, StatementEnd - 1));

  Start := StatementEnd + 1;
end;

function ControlStructureTree(var Start: Integer): TStatementTree;
var
  Parentheses, i, c1, c2: Integer;
begin
  Result := TStatementTree.Create;
  Result.Node.Token := Start;
  if T.Tokens[Start].Value = 'if' then
    Result.Node.NodeType := ntIf
  else if T.Tokens[Start].Value = 'while' then
    Result.Node.NodeType := ntWhile
  else if T.Tokens[Start].Value = 'do' then
    Result.Node.NodeType := ntDo
  else if T.Tokens[Start].Value = 'for' then
    Result.Node.NodeType := ntFor
  else
    begin
    ErrLine(Start);
    ModuleManager.ModLog.AddError('Expected one of "if", "while", "do", "for" but got "' + T.Tokens[Start].Value + '"');
    raise EScriptTreeException.Create('Compilation aborted');
    end;

  case Result.Node.NodeType of
    ntIf, ntWhile:
      begin
      inc(Start);

      Expect(Start, stParentheseL);
      Parentheses := 1;

      i := Start;

      while Parentheses > 0 do
        begin
        inc(i);
        if i > high(T.Tokens) then
          begin
          ErrLine(Start);
          ModuleManager.ModLog.AddError('Unmatched (');
          raise EScriptTreeException.Create('Compilation aborted');
          end;
        if T.Tokens[i].TType = stParentheseL then
          inc(Parentheses)
        else if T.Tokens[i].TType = stParentheseR then
          dec(Parentheses);
        end;

      inc(Start);
      Result.AddChild(OperationTree(Start, i - 1));
      Start := i + 1;

      Expect(Start, stBraceL);

      Result.AddChild(BlockTree(Start));

      if Result.Node.NodeType = ntIf then
        begin
        if (T.Tokens[Start].TType = stKeyword) and (T.Tokens[Start].Value = 'else') then
          begin
          inc(Start);
          if T.Tokens[Start].TType = stBraceL then
            Result.AddChild(BlockTree(Start))
          else if (T.Tokens[Start].TType = stKeyword) and (T.Tokens[Start].Value = 'if') then
            Result.AddChild(ControlStructureTree(Start))
          else
            begin
            ErrLine(Start);
            ModuleManager.ModLog.AddError('Expected one of if, {');
            raise EScriptTreeException.Create('Compilation aborted');
            end;
          end;
        end;
      end;
    ntDo:
      begin
      inc(Start);

      Expect(Start, stBraceL);
      Result.AddChild(BlockTree(Start));
      Expect(Start, stKeyword, 'while');

      inc(Start);
      Expect(Start, stParentheseL);

      Parentheses := 1;

      i := Start;
      while Parentheses > 0 do
        begin
        inc(i);
        if i > high(T.Tokens) then
          begin
          ErrLine(Start);
          ModuleManager.ModLog.AddError('Unmatched (');
          raise EScriptTreeException.Create('Compilation aborted');
          end;
        if T.Tokens[i].TType = stParentheseL then
          inc(Parentheses)
        else if T.Tokens[i].TType = stParentheseR then
          dec(Parentheses);
        end;

      inc(Start);

      Result.AddChild(OperationTree(Start, i - 1));

      Start := i + 1;
      Expect(Start, stSemicolon);

      inc(Start);
      end;
    ntFor:
      begin
      inc(Start);

      Expect(Start, stParentheseL);
      Parentheses := 1;

      i := Start;

      while Parentheses > 0 do
        begin
        inc(i);
        if i > high(T.Tokens) then
          begin
          ErrLine(Start);
          ModuleManager.ModLog.AddError('Unmatched (');
          raise EScriptTreeException.Create('Compilation aborted');
          end;
        if T.Tokens[i].TType = stParentheseL then
          inc(Parentheses)
        else if T.Tokens[i].TType = stParentheseR then
          dec(Parentheses);
        end;

      c1 := GetNextOfType(stSemicolon, Start);
      if (c1 = -1) or (c1 >= i) then
        begin
        ErrLine(Start);
        ModuleManager.ModLog.AddError('Missing ' + ScriptTokenTypeNames[stSemicolon]);
        raise EScriptTreeException.Create('Compilation aborted');
        end;

      c2 := GetNextOfType(stSemicolon, C1 + 1);
      if (c2 = -1) or (c2 >= i) then
        begin
        ErrLine(Start);
        ModuleManager.ModLog.AddError('Missing ' + ScriptTokenTypeNames[stSemicolon]);
        raise EScriptTreeException.Create('Compilation aborted');
        end;

      inc(Start);
      Result.AddChild(AssignmentTree(Start, GetNextOfType(stAssign, Start)));
      Start := C1 + 1;
      Result.AddChild(OperationTree(Start, c2 - 1));
      Start := C2 + 1;
      Result.AddChild(AssignmentTree(Start, GetNextOfType(stAssign, Start), i));

      Start := i + 1;
      Expect(Start, stBraceL);
      
      Result.AddChild(BlockTree(Start));
      end;
    end;
end;

function BlockTree(var Start: integer): TStatementTree;
var
  i: Integer;
begin
  Result := TStatementTree.Create;
  Result.Node.NodeType := ntBlock;
  Result.Node.Token := Start;

  Expect(Start, stBraceL);
  inc(Start);
  while T.Tokens[Start].TType <> stBraceR do
    begin
    i := Start;
    case T.Tokens[i].TType of
      stKeyword:
        begin
        // TODO control structures
        if (T.Tokens[i].Value = 'if') or (T.Tokens[i].Value = 'while') or (T.Tokens[i].Value = 'do') or (T.Tokens[i].Value = 'for') then
          Result.AddChild(ControlStructureTree(Start))
        else
          begin
          ErrLine(i);
          ModuleManager.ModLog.AddError('Expected one of "if", "while", "do", "for" but got "' + T.Tokens[i].Value + '"');
          raise EScriptTreeException.Create('Compilation aborted');
          end;
        end;
      stDataType:
        begin
        Expect(i, stDataType);
        Expect(i + 1, stIdentifier);
        case T.Tokens[i + 2].TType of
          stSemicolon: Result.AddChild(DeclarationTree(Start));
          stAssign: Result.AddChild(AssignmentTree(Start, i + 2));
          else
            ErrLine(i + 2);
            ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stSemicolon] + ', '
                                                             + ScriptTokenTypeNames[stAssign] + ', '
                                                             + ScriptTokenTypeNames[stParentheseL] + ' but got "' + T.Tokens[i + 2].Value + '"');
            raise EScriptTreeException.Create('Compilation aborted');
          end;
        end;
      stIdentifier:
        begin
        case T.Tokens[Start + 1].TType of
          stAssign: Result.AddChild(AssignmentTree(Start, Start + 1));
          stDereference: Result.AddChild(AssignmentTree(Start, Start + 2));
          stParentheseL:
            begin
            Result.AddChild(FunctionCallTree(Start));
            Expect(Start, stSemicolon);
            inc(Start);
            end;
          end;
        end;
      stParentheseL:
        if GetNextOfType(stAssign, Start) <> -1 then
          Result.AddChild(AssignmentTree(Start, GetNextOfType(stAssign, Start)))
        else
          begin
          ErrLine(Start);
          ModuleManager.ModLog.AddError('Invalid statement');
          raise EScriptTreeException.Create('Compilation aborted');
          end;
      else
        ErrLine(Start);
        ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stKeyword] + ', '
        + ScriptTokenTypeNames[stIdentifier] + ', '
        + ScriptTokenTypeNames[stDataType] + ', '
        + ScriptTokenTypeNames[stParentheseL] + ' but got "' + T.Tokens[i].Value + '"');
        raise EScriptTreeException.Create('Compilation aborted');
      end;
    end;
  inc(Start);
end;

function StructTree(var Start: Integer): TStatementTree;
var
  I: Integer;
begin
  Result := TStatementTree.Create;
  Result.Node.NodeType := ntStruct;
  Result.Node.Token := Start;

  Expect(Start, stKeyword, 'struct');
  Expect(Start + 1, stIdentifier);
  Expect(Start + 2, stBraceL);

  Result.AddChild(IdentifierNode(Start + 1));

  i := Start + 3;
  while T.Tokens[i].TType <> stBraceR do
    begin
    Expect(i, stDataType);
    Expect(i + 1, stIdentifier);
    Expect(i + 2, stSemicolon);
    inc(i, 3);
    end;

  Expect(i, stBraceR);

  inc(Start, 2);
  Result.AddChild(BlockTree(Start));
end;

function FunctionTree(var Start: Integer): TStatementTree;
var
  Last, i, Braces: Integer;
  P: TStatementTree;
begin
  Result := TStatementTree.Create;
  Result.Node.Token := Start;
  Result.Node.NodeType := ntFunction;

  Expect(Start, stDataType);
  Expect(Start + 1, stIdentifier);
  Expect(Start + 2, stParentheseL);

  Last := GetNextOfType(stParentheseR, Start + 3);
  if Last = -1 then
    begin
    ErrLine(Start);
    ModuleManager.ModLog.AddError('Unmatched (');
    raise EScriptTreeException.Create('Compilation aborted');
    end;

  P := TStatementTree.Create;
  P.Node.Token := Start + 3;
  P.Node.NodeType := ntParameters;

  Start := Start + 3;
  while Start < Last do
    begin
    P.AddChild(DeclarationTree(Start, False));
    inc(Start);
    end;
  Result.AddChild(P);

  if T.Tokens[Start].TType = stBraceL then
    dec(Start);

  Expect(Start, stParentheseR);
  Expect(Start + 1, stBraceL);

  inc(Start);

  i := Start;

  Braces := 1;

  while Braces <> 0 do
    begin
    inc(Start);
    if Start > high(T.Tokens) then
      begin
      end
    else
      if T.Tokens[Start].TType = stBraceL then
        inc(Braces)
      else if T.Tokens[Start].TType = stBraceR then
        dec(Braces);
    end;

  Result.AddChild(BlockTree(i));

  inc(Start);
end;

procedure AddStatements(Tree: TStatementTree; Min, Max: Integer);
var
  TreeMode: TTreeNodeType;
  i: Integer;
begin
  while Min <= Max do
    begin
    i := Min;
    case T.Tokens[i].TType of
      stKeyword:
        begin
        if T.Tokens[i].Value = 'extern' then
          Tree.AddChild(ExternStructTree(Min))
        else if T.Tokens[i].Value = 'struct' then
          Tree.AddChild(StructTree(Min));
        end;
      stDataType:
        begin
        Expect(i, stDataType);
        Expect(i + 1, stIdentifier);

        case T.Tokens[i + 2].TType of
          stSemicolon: Tree.AddChild(DeclarationTree(Min));
          stAssign: Tree.AddChild(AssignmentTree(Min, i + 2));
          stParentheseL: Tree.AddChild(FunctionTree(Min));
          else
            ErrLine(i + 2);
            ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stSemicolon] + ', '
                                                             + ScriptTokenTypeNames[stAssign] + ', '
                                                             + ScriptTokenTypeNames[stParentheseL] + ' but got "' + T.Tokens[i + 2].Value + '"');
            raise EScriptTreeException.Create('Compilation aborted');
          end;
        end;
      stIdentifier:
        begin
        case T.Tokens[Min + 1].TType of
          stAssign: Tree.AddChild(AssignmentTree(Min, Min + 1));
          stDereference: Tree.AddChild(AssignmentTree(Min, Min + 2));
          stParentheseL:
            begin
            Tree.AddChild(FunctionCallTree(Min));
            Expect(Min, stSemicolon);
            inc(Min);
            end;
          end;
        end;
      stParentheseL:
        if GetNextOfType(stAssign, Min) <> -1 then
          Tree.AddChild(AssignmentTree(Min, GetNextOfType(stAssign, Min)))
        else
          begin
          ErrLine(Min);
          ModuleManager.ModLog.AddError('Invalid statement');
          raise EScriptTreeException.Create('Compilation aborted');
          end;
      else
        ErrLine(Min);
        ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stKeyword] + ', '
        + ScriptTokenTypeNames[stIdentifier] + ', '
        + ScriptTokenTypeNames[stDataType] + ', '
        + ScriptTokenTypeNames[stParentheseL] + ' but got "' + T.Tokens[i].Value + '"');
        raise EScriptTreeException.Create('Compilation aborted');
      end;
    end;
end;

function TStatementTreeGenerator.GenerateTree(Tokens: TTokenList): TStatementTree;
begin
  T := Tokens;
  Result := TStatementTree.Create;
  Result.Node.NodeType := ntScript;
  Result.Node.Token := -1;
  AddStatements(Result, 0, High(T.Tokens));
  OutputTree(Result);
end;

end.