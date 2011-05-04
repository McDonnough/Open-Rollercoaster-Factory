unit m_scriptmng_bytecode_compiler_tokenizer;

interface

uses
  SysUtils, Classes;

type
  TScriptTokenType = (stUnknown, stKeyword, stDataType, stIdentifier, stOperator, stDereference, stAssign, stInt, stFloat,
  stBraceL, stBracketL, stParentheseL, stBraceR, stBracketR, stParentheseR, stDot, stComma, stSemicolon);

  TScriptToken = record
    TType: TScriptTokenType;
    Value: String;
    Line: Integer;
    end;

  TTokenList = class
    Tokens: Array of TScriptToken;
    procedure Add(A: TScriptToken);
    end;

  TTokenizer = class
    protected
      fTokenList: TTokenList;
    public
      function Tokenize(S: String): TTokenList;
    end;

const
  ScriptTokenTypeNames: Array[TScriptTokenType] of String = (
    '#UNKNOWN', '#KEYWORD', '#DATATYPE', '#IDENTIFIER', '#OPERATOR', '^', '=', '#INT', '#FLOAT', '{', '[', '(', '}', ']', ')', '.', ',', ';');

  Keywords: Array[0..6] of String = (
    'extern', 'struct', 'if', 'while', 'else', 'do', 'for');
implementation

uses
  u_functions;

function _(A: TScriptTokenType; B: String): TScriptToken;
begin
  Result.TType := A;
  Result.Value := B;
end;

procedure TTokenList.Add(A: TScriptToken);
begin
  setLength(Tokens, length(Tokens) + 1);
  Tokens[high(Tokens)] := A;
end;

function TTokenizer.Tokenize(S: String): TTokenList;
var
  fPrev: TScriptToken;
  fLine: Integer;

  function getNextToken(var Pos: Integer): TScriptToken;
  var
    i: Integer;
  begin
    Result.TType := stUnknown;
    Result.Value := '';
    while isWhitespace(S[Pos]) do
      begin
      if S[Pos] = #10 then
        inc(fLine);
      inc(Pos);
      end;
    Result.Line := fLine;

    if S[Pos] = #0 then
      begin
      inc(Pos);
      exit;
      end;

    case S[Pos] of
      '(', '[', '{', '}', ']', ')':
        begin
        case S[Pos] of
          '(': Result.TType := stParentheseL;
          '[': Result.TType := stBracketL;
          '{': Result.TType := stBraceL;
          '}': Result.TType := stBraceR;
          ']': Result.TType := stBracketR;
          ')': Result.TType := stParentheseR;
          end;
        Result.Value := S[Pos];
        inc(Pos);
        exit;
        end;
      '+', '/', '*', '^', '.', ',', ';', '=', '&', '|', '!', '<', '>', '?', '%':
        begin
        Result.TType := stOperator;
        case S[Pos] of
          '^': Result.TType := stDereference;
          '.': Result.TType := stDot;
          ',': Result.TType := stComma;
          ';': Result.TType := stSemicolon;
          end;
        Result.Value := S[Pos];
        inc(Pos);
        if Result.TType = stOperator then
          while S[Pos] in ['+', '*', '/', '-', '&', '|', '!', '<', '>', '?', '%', '='] do
            begin
            Result.Value += S[Pos];
            inc(Pos);
            end;
        if Result.Value = '=' then
          Result.TType := stAssign;
        exit;
        end;
      '-':
        begin
        Result.Value := S[Pos];
        if fPrev.TType in [stIdentifier, stInt, stFloat, stDereference, stBraceR, stBracketR, stParentheseR] then
          begin
          Result.TType := stOperator;
          inc(Pos);
          while S[Pos] in ['+', '*', '/', '-', '&', '|', '!', '<', '>', '?', '%', '='] do
            begin
            Result.Value += S[Pos];
            inc(Pos);
            end;
          end
        else
          begin
          Result.TType := stInt;
          inc(Pos);
          while S[Pos] in ['0'..'9', '.'] do
            begin
            Result.Value += S[Pos];
            if S[Pos] = '.' then
              Result.TType := stFloat;
            inc(Pos);
            end;
          end;
        exit;
        end;
      '0'..'9':
        begin
        Result.TType := stInt;
        Result.Value := S[Pos];
        inc(Pos);
        while S[Pos] in ['0'..'9', '.'] do
          begin
          Result.Value += S[Pos];
          if S[Pos] = '.' then
            Result.TType := stFloat;
          inc(Pos);
          end;
        exit;
        end;
      'a'..'z', 'A'..'Z', '_':
        begin
        Result.TType := stIdentifier;
        if fPrev.TType = stIdentifier then
          fPrev.TType := stDataType;
        Result.Value := S[Pos];
        inc(Pos);
        while S[Pos] in ['a'..'z', 'A'..'Z', '_', '0'..'9', '.'] do
          begin
          Result.Value += S[Pos];
          inc(Pos);
          end;
        for i := 0 to high(Keywords) do
          if Result.Value = Keywords[i] then
            Result.TType := stKeyword;
        exit;
        end;
      else
        inc(Pos);
      end;
  end;

var
  i: Integer;
  t: TScriptToken;
begin
  fLine := 1;
  fTokenList := TTokenList.Create;
  s := s + #0;
  i := 1;
  fPrev := _(stUnknown, '');
  while i <= Length(S) do
    begin
    t := GetNextToken(i);
    if t.TType <> stUnknown then
      begin
      if length(fTokenList.Tokens) > 0 then
        fTokenList.Tokens[high(fTokenList.Tokens)].TType := fPrev.TType;
      fTokenList.Add(t);
      fPrev := t;
      end;
    end;
  Result := fTokenList;
end;

end.