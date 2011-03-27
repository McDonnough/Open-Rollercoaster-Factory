unit m_shdmng_dynamic_parser;

interface

uses
  SysUtils, Classes, u_functions;

type
  TGLSLTokenType = (ttUnknown, ttControlStatement, ttSingleLineComment, ttMultiLineComment, ttPreprocessorStatement, ttTypePrefix, ttDataType, ttIdentifier, ttPoint, ttSwizzle, ttOperator, ttBrace, ttNumber, ttSemicolon, ttComma);

  TGLSLToken = record
    TType: TGLSLTokenType;
    Value: String;
    end;

  TShaderFile = class
    protected
      fTokens: Array of TGLSLToken;
      fUniforms, fVaryings: TDictionary;
    public
      property Uniforms: TDictionary read fUniforms;
      property Varyings: TDictionary read fVaryings;
      function ToString: String;
      procedure EliminateVarying(Varying: String);
      procedure Preprocess;
      procedure GetVariables;
      procedure CleanUp;
      constructor Create(FileName: String);
      destructor Free;
    end;

  TShaderConstellation = class
    protected
      fVertexShaderFile, fFragmentShaderFile: TShaderFile;
    public
      property VertexShader: TShaderFile read fVertexShaderFile;
      property FragmentShader: TShaderFile read fFragmentShaderFile;
      constructor Create(VS, FS: String);
      destructor Free;
    end;

implementation

uses
  m_varlist;

procedure TShaderFile.EliminateVarying(Varying: String);
var
  i: Integer;
begin
  for i := 0 to high(fTokens) do
    if (fTokens[i].TType = ttTypePrefix) and (fTokens[i].Value = 'varying') then
      if fTokens[i + 2].Value = Varying then
        begin
        fTokens[i].Value := '';
        fTokens[i].TType := ttUnknown;
        end;
  writeln('Hint: Removed varying ' + Varying);
end;

procedure TShaderFile.Preprocess;
  procedure CheckBlock(tStart, tEnd: Integer);
    function Evaluate(ID: Integer): Boolean;
      function StatementGroup(A: String): Boolean;
        function SingleStatement(B: String): Boolean;
        var
          T: AString;
        begin
          T := Explode(' ', B);
          if Length(T) = 3 then
            begin
            if T[0] = 'EQ' then
              Result := ModuleManager.ModShdMng.Vars[T[1]] = T[2]
            else if T[0] = 'NEQ' then
              Result := ModuleManager.ModShdMng.Vars[T[1]] <> T[2];
            end
          else
            begin
            ModuleManager.ModLog.AddError('Invalid statement: ' + B);
            exit(True);
            end;
        end;
      var
        S: AString;
        FinalStatements: Array[0..1] of String;
        ConditionType: String;
        i, CurrentStatement, BlockDepth: Integer;
      begin
        S := Explode(' ', A);
        Result := True;
        if (S[0] = '[') and (S[High(S)] = ']') then
          begin
          FinalStatements[0] := '';
          FinalStatements[1] := '';
          ConditionType := '';
          CurrentStatement := 0;
          BlockDepth := 0;
          for i := 1 to high(S) - 1 do
            if ((S[i] = 'AND') or (S[i] = 'OR') or (S[i] = 'NOT')) and (BlockDepth = 0) then
              begin
              if FinalStatements[CurrentStatement] <> '' then
                SetLength(FinalStatements[CurrentStatement], length(FinalStatements[CurrentStatement]) - 1);
              ConditionType := S[i];
              inc(CurrentStatement);
              if CurrentStatement > 1 then
                begin
                ModuleManager.ModLog.AddError('Too many conditions');
                exit(True);
                end;
              end
            else
              begin
              if S[i] = '[' then
                inc(BlockDepth)
              else if S[i] = ']' then
                dec(BlockDepth);
              FinalStatements[CurrentStatement] := FinalStatements[CurrentStatement] + S[i] + ' ';
              end;
          if FinalStatements[CurrentStatement] <> '' then
            SetLength(FinalStatements[CurrentStatement], length(FinalStatements[CurrentStatement]) - 1);
          if ConditionType = '' then
            Result := SingleStatement(FinalStatements[0])
          else if ConditionType = 'NOT' then
            Result := not StatementGroup(FinalStatements[1])
          else if ConditionType = 'AND' then
            Result := StatementGroup(FinalStatements[0]) and StatementGroup(FinalStatements[1])
          else if ConditionType = 'OR' then
            Result := StatementGroup(FinalStatements[0]) or StatementGroup(FinalStatements[1]);
          end
        else
          ModuleManager.ModLog.AddError('Invalid statement group');
      end;
    begin
      if ID = -1 then
        begin
        ModuleManager.ModLog.AddError('No IF block open for END');
        exit(True);
        end;
      Result := StatementGroup(SubString(fTokens[ID].Value, 7, length(fTokens[ID].Value) - 6));
    end;
    
  var
    i, j: Integer;
    BlockCount: Integer;
    mStart, mEnd: Integer;
  begin
    mStart := -1;
    mEnd := -1;
    for i := tStart to tEnd do
      if (fTokens[i].TType = ttSingleLineComment) and (SubString(fTokens[i].Value, 1, 6) = '// IF ') then
        begin
        mStart := i;
        inc(BlockCount);
        end
      else if (fTokens[i].TType = ttSingleLineComment) and (SubString(fTokens[i].Value, 1, 6) = '// END') then
        begin
        dec(BlockCount);
        mEnd := i;
        if not Evaluate(mStart) then
          begin
          for j := mStart to mEnd do
            begin
            fTokens[j].Value := '';
            fTokens[j].TType := ttUnknown;
            end;
          end
        else
          CheckBlock(mStart + 1, mEnd - 1);
        end;
  end;
begin
  CheckBlock(0, high(fTokens));
end;

procedure TShaderFile.GetVariables;
var
  i: Integer;
begin
  for i := 0 to high(fTokens) do
    if fTokens[i].TType = ttTypePrefix then
      if fTokens[i].Value = 'uniform' then
        Uniforms[fTokens[i + 2].Value] := fTokens[i + 1].Value
      else if fTokens[i].Value = 'varying' then
        Varyings[fTokens[i + 2].Value] := fTokens[i + 1].Value;
end;

procedure TShaderFile.CleanUp;
var
  i, j: Integer;
begin
  i := 0;
  while i <= high(fTokens) do
    if fTokens[i].TType = ttUnknown then
      begin
      for j := i + 1 to high(fTokens) do
        fTokens[j - 1] := fTokens[j];
      SetLength(fTokens, length(fTokens) - 1);
      end
    else
      inc(i);
end;

constructor TShaderFile.Create(FileName: String);
var
  FileContents: String;
  S: Integer;
  fInComment: Boolean;
  fInPreprocessorStatement: Boolean;
  fCurrentLine, fCurrentCol: Integer;
  i: Integer;
  fCurrentToken, fPrevToken: TGLSLTokenType;
  fCurrentValue: String;
begin
  FileContents := '';
  with TFileStream.create(FileName, fmOpenRead) do
    begin
    SetLength(FileContents, Size);
    read(FileContents[1], Size);
    Free;
    end;
  SetLength(fTokens, 0);
  FileContents := FileContents + #10 + #10 + #0;
  fCurrentLine := 1;
  fPrevToken := ttUnknown;
  fCurrentToken := ttUnknown;
  fCurrentValue := '';
  i := 1;
  try
    fCurrentCol := 1;
    while i < length(FileContents) do
      begin
      if fCurrentToken = ttUnknown then
        begin
        case FileContents[i] of
          '!', '+', '-', '*', '=', '&', '|', '?', ':', '<', '>':
            begin
            fCurrentToken := ttOperator;
            fCurrentValue := FileContents[i];
            end;
          ',':
            begin
            fCurrentToken := ttComma;
            fCurrentValue := ',';
            end;
          '.':
            begin
            fCurrentToken := ttPoint;
            fCurrentValue := '.';
            end;
          ';':
            begin
            fCurrentToken := ttSemicolon;
            fCurrentValue := ';';
            end;
          '(', '[', '{', '}', ']', ')':
            begin
            fCurrentToken := ttBrace;
            fCurrentValue := FileContents[i];
            end;
          '#':
            begin
            fCurrentToken := ttPreprocessorStatement;
            fCurrentValue := '#';
            end;
          '0'..'9':
            begin
            fCurrentToken := ttNumber;
            fCurrentValue := FileContents[i];
            end;
          '/':
            begin
            fCurrentToken := ttOperator;
            fCurrentValue := FileContents[i];
            if FileContents[i + 1] = '/' then
              fCurrentToken := ttSingleLineComment
            else if FileContents[i + 1] = '*' then
              begin
              fCurrentToken := ttMultiLineComment;
              inc(i);
              fCurrentValue := '/*';
              end;
            end;
          'a'..'z', 'A'..'Z', '_':
            begin
            fCurrentToken := ttIdentifier;
            fCurrentValue := FileContents[i];
            end;
          end;
        inc(i);
        end
      else
        begin
        case fCurrentToken of
          ttOperator:
            begin
            while FileContents[i] in ['!', '+', '-', '*', '/', '=', '&', '|', '?', ':', '<', '>'] do
              begin
              fCurrentValue := fCurrentValue + FileContents[i];
              inc(i);
              end;
            end;
          ttIdentifier:
            begin
            while FileContents[i] in ['a'..'z', 'A'..'Z', '_', '0'..'9'] do
              begin
              fCurrentValue := fCurrentValue + FileContents[i];
              inc(i);
              end;
            if (fCurrentValue = 'uniform') or (fCurrentValue = 'const') or (fCurrentValue = 'varying')
            or (fCurrentValue = 'out') or (fCurrentValue = 'in') or (fCurrentValue = 'inout') then
              fCurrentToken := ttTypePrefix
            else if (fCurrentValue = 'if') or (fCurrentValue = 'for') or (fCurrentValue = 'while') or (fCurrentValue = 'do')
                 or (fCurrentValue = 'return') then
              fCurrentToken := ttControlStatement
            else if (fCurrentValue = 'void') or (fCurrentValue = 'int') or (fCurrentValue = 'float') or (fCurrentValue = 'bool')
                 or (fCurrentValue = 'sampler1D') or (fCurrentValue = 'sampler2D') or (fCurrentValue = 'sampler3D')
                 or (fCurrentValue = 'vec2') or (fCurrentValue = 'vec3') or (fCurrentValue = 'vec4')
                 or (fCurrentValue = 'ivec2') or (fCurrentValue = 'ivec3') or (fCurrentValue = 'ivec4')
                 or (fCurrentValue = 'bvec2') or (fCurrentValue = 'bvec3') or (fCurrentValue = 'bvec4')
                 or (fCurrentValue = 'mat2') or (fCurrentValue = 'mat3') or (fCurrentValue = 'mat4')  then
              fCurrentToken := ttDataType
            else if fPrevToken = ttPoint then
              fCurrentToken := ttSwizzle;
            end;
          ttSingleLineComment, ttPreprocessorStatement:
            begin
            while not (FileContents[i] in [#10, #13]) do
              begin
              fCurrentValue := fCurrentValue + FileContents[i];
              inc(i);
              end;
            end;
          ttMultiLineComment:
            begin
            while fCurrentValue[length(fCurrentValue) - 1] + fCurrentValue[length(fCurrentValue)] <> '*/' do
              begin
              fCurrentValue := fCurrentValue + FileContents[i];
              inc(i);
              end;
            end;
          ttNumber:
            begin
            while FileContents[i] in ['.', '0'..'9'] do
              begin
              fCurrentValue := fCurrentValue + FileContents[i];
              inc(i);
              end;
            end;
          ttSemicolon, ttComma:
            begin
            end;
          ttPoint:
            begin
            end;
          ttBrace:
            begin
            end;
          end;
        SetLength(fTokens, length(fTokens) + 1);
        fTokens[high(fTokens)].TType := fCurrentToken;
        fTokens[high(fTokens)].Value := fCurrentValue;
        fCurrentValue := '';
        fPrevToken := fCurrentToken;
        fCurrentToken := ttUnknown;
        end;
      end;
  except
    writeln('FAIL');
  end;

  fUniforms := TDictionary.Create;
  fVaryings := TDictionary.Create;
end;

destructor TShaderFile.Free;
begin
  fUniforms.Free;
  fVaryings.Free;
end;

function TShaderFile.ToString: String;
var
  i: Integer;
  Indention: String;
begin
  Result := '';
  Indention := '';
  for i := 0 to high(fTokens) do
    begin
    if fTokens[i].TType = ttBrace then
      if fTokens[i].Value = '{' then
        begin
        Indention := Indention + #9;
        Result := Result + ' ';
        end
      else if (fTokens[i].Value = '}') and (Indention <> '') then
        SetLength(Indention, length(Indention) - 1);
    if Result <> '' then
      if Result[length(Result)] = #10 then
        Result := Result + Indention;
    if fTokens[i].TType = ttOperator then
      Result := Result + ' ';
    if (fTokens[i].TType <> ttMultiLineComment) and (fTokens[i].TType <> ttSingleLineComment) then
      Result := Result + fTokens[i].Value;
    if fTokens[i].TType = ttPreprocessorStatement then
      Result := Result + #10 + #10
    else if (fTokens[i].TType = ttSemicolon) or ((fTokens[i].TType = ttBrace) and ((fTokens[i].Value = '{') or (fTokens[i].Value = '}'))) then
      Result := Result + #10
    else if (fTokens[i].TType = ttOperator) or (fTokens[i].TType = ttComma) then
      Result := Result + ' '
    else if ((fTokens[i].TType = ttDataType) and (fTokens[i + 1].TType <> ttBrace)) or (fTokens[i].TType = ttTypePrefix) then
      Result := Result + ' '
    else if (fTokens[i].TType = ttControlStatement) and (fTokens[i + 1].TType <> ttSemicolon) then
      Result := Result + ' '
    else if (fTokens[i].TType = ttBrace) and (fTokens[i].Value = ')') and ((fTokens[i + 1].TType = ttIdentifier) or (fTokens[i + 1].TType = ttDataType) or (fTokens[i + 1].TType = ttNumber) or (fTokens[i + 1].TType = ttTypePrefix) or (fTokens[i + 1].TType = ttControlStatement)) then
      Result := Result + ' ';
    end;
end;

constructor TShaderConstellation.Create(VS, FS: String);
var
  i: Integer;
  VertexVaryings: AString;
begin
  fVertexShaderFile := TShaderFile.Create(VS);
  fVertexShaderFile.GetVariables;
  
  fFragmentShaderFile := TShaderFile.Create(FS);
  fFragmentShaderFile.GetVariables;

  fVertexShaderFile.Preprocess;
  fFragmentShaderFile.Preprocess;

  VertexVaryings := fVertexShaderFile.Varyings.ItemStrings;
  for i := 0 to high(VertexVaryings) do
    if FragmentShader.Varyings.ItemID[VertexVaryings[i]] = -1 then
      fVertexShaderFile.EliminateVarying(VertexVaryings[i]);

  fVertexShaderFile.CleanUp;
  fFragmentShaderFile.CleanUp;
end;

destructor TShaderConstellation.Free;
begin
  fVertexShaderFile.Free;
  fFragmentShaderFile.Free;
end;

end.