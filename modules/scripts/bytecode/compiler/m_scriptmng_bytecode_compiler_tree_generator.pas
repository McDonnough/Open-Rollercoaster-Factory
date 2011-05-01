unit m_scriptmng_bytecode_compiler_tree_generator;

interface

uses
  SysUtils, Classes, m_scriptmng_bytecode_compiler_tokenizer, math;

type
  EScriptTreeException = class(Exception);

  TTreeNodeType = (ntScript, ntAssignment, ntDeclaration, ntExternStruct, ntIdentifier, ntStruct, ntFunction, ntCall, ntBlock,
    ntIf, ntFor, ntWhile, ntDo, ntOperation, ntInt, ntFloat, ntDereference);

  TStatementTreeNode = record
    Token: Integer;
    NodeType: TTreeNodeType;
    end;

  TStatementTree = class
    Node: TStatementTreeNode;
    Children: Array of TStatementTree;
    procedure AddChild(C: TStatementTree);
    end;

  TStatementTreeGenerator = class
    protected
    public
      function GenerateTree(T: TTokenList): TStatementTree;
    end;

const
  TreeNodeTypeNames: Array[TTreeNodeType] of String = (
    'SCRIPT', '=', 'DECL', 'EXTSTRUCT', 'IDENT', 'STRUCT', 'FUNCTION', 'CALL', 'BLOCK', 'IF', 'FOR', 'WHILE', 'DO', 'OP',
    'INT', 'FLOAT', 'DEREF');

implementation

uses
  m_varlist, u_functions;

procedure TStatementTree.AddChild(C: TStatementTree);
begin
  SetLength(Children, length(Children) + 1);
  Children[high(Children)] := C;
end;

function TStatementTreeGenerator.GenerateTree(T: TTokenList): TStatementTree;
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



  procedure AddStatements(Tree: TStatementTree; Min, Max: Integer);
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

      Result.AddChild(IdentifierNode(Start));

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

    function GetLowPriorityOperator(Start, Last: Integer; Priority: Integer = 5): Integer;
    var
      CurrentOperator: Integer;
      V: String;
    begin
      Result := -1;
      CurrentOperator := GetNextOfType(stOperator, Start);
      while (CurrentOperator <= Last) and (CurrentOperator <> -1) do
        begin
        V := T.Tokens[CurrentOperator].Value;
        case Priority of
          5: if (V = '||') or (V = '&&') or (V = '??') then exit(CurrentOperator);
          4: if (V = '<') or (V = '<=') or (V = '==') or (V = '>=') or (V = '>') or (V = '!=') then exit(CurrentOperator);
          3: if (V = '+') or (V = '-') or (V = '|') or (V = '?') then exit(CurrentOperator);
          2: if (V = '*') or (V = '/') or (V = '&') or (V = '%') then exit(CurrentOperator);
          1: if (V = '!') then exit(CurrentOperator);
          end;
        CurrentOperator := GetNextOfType(stOperator, CurrentOperator + 1);
        end;
      if Priority <> 1 then
        Result := GetLowPriorityOperator(Start, Last, Priority - 1);
    end;

    function FunctionCallTree(var Start: Integer): TStatementTree;
    begin
      Result := TStatementTree.Create;
      Result.Node.NodeType := ntCall;
      Result.Node.Token := Start;

      // TODO: Implement this
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
            break;
            end;

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

        // None found? => search for dereference operator
        if T.Tokens[Last].TType = stDereference then
          begin
          Result := TStatementTree.Create;
          Result.Node.NodeType := ntDereference;
          Result.Node.Token := Last;
          Result.AddChild(OperationTree(Start, Last - 1));
          Exit;
          end;

        // Nothing? => function call
        if OperatorToken = -1 then
          Exit(FunctionCallTree(Start));

        // Operator exists - create subtree
        Result := TStatementTree.Create;
        Result.Node.NodeType := ntOperation;
        Result.Node.Token := OperatorToken;
        Result.AddChild(OperationTree(Start, OperatorToken - 1));
        Inc(OperatorToken);
        Result.AddChild(OperationTree(OperatorToken, Last));
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

    function AssignmentTree(var Start: integer; AssignmentSign: Integer): TStatementTree;
    var
      StatementEnd: Integer;
    begin
      Result := TStatementTree.Create;
      Result.Node.NodeType := ntAssignment;
      Result.Node.Token := Start;

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

      StatementEnd := GetNextOfType(stSemicolon, AssignmentSign);

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

    function BlockTree(var Start: integer): TStatementTree;
    begin
      Result := TStatementTree.Create;
      Result.Node.NodeType := ntBlock;
      Result.Node.Token := Start;

      Expect(Start, stBraceL);
      inc(Start);
      while T.Tokens[Start].TType <> stBraceR do
        begin
        case T.Tokens[Start].TType of
          stDataType:
            begin
            Expect(Start, stDataType);
            Expect(Start + 1, stIdentifier);
            if T.Tokens[Start + 2].TType = stSemicolon then
              Result.AddChild(DeclarationTree(Start))
            else if T.Tokens[Start + 2].TType = stAssign then
              Result.AddChild(AssignmentTree(Start, Start + 2))
            else
              begin
              ErrLine(Start);
              ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stSemicolon] + ', ' + ScriptTokenTypeNames[stAssign] + ' but got "' + T.Tokens[Start].Value + '"');
              raise EScriptTreeException.Create('Compilation aborted');
              end;
            end;
          else
            ErrLine(Start);
            ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stDataType] + ' but got "' + T.Tokens[Start].Value + '"');
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
//             stParentheseL:
            else
              ErrLine(i + 2);
              ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stSemicolon] + ', '
                                                               + ScriptTokenTypeNames[stAssign] + ', '
                                                               + ScriptTokenTypeNames[stParentheseL] + ' but got "' + T.Tokens[i + 2].Value + '"');
              raise EScriptTreeException.Create('Compilation aborted');
            end;
          end;
        else
          OutputTree(Tree);
          ErrLine(Min);
          ModuleManager.ModLog.AddError('Expected one of ' + ScriptTokenTypeNames[stKeyword] + ' but got "' + T.Tokens[i].Value + '"');
          raise EScriptTreeException.Create('Compilation aborted');
        end;
      end;
  end;

begin
  Result := TStatementTree.Create;
  Result.Node.NodeType := ntScript;
  Result.Node.Token := -1;
  AddStatements(Result, 0, High(T.Tokens));
end;

end.