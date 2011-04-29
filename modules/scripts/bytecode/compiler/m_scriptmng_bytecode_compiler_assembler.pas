unit m_scriptmng_bytecode_compiler_assembler;

interface

uses
  SysUtils, Classes, m_scriptmng_bytecode_compiler, m_scriptmng_bytecode_cmdlist;

type
  TScriptASMTokenType = (atUnknown, atInstruction, atFloat, atInt, atLabel, atReferenceLabel, atBracketL, atBracketR, atAddress, atIntRegister, atVecRegister);

  TScriptASMToken = record
    TType: TScriptASMTokenType;
    Value: String;
    end;

  AScriptASMToken = Array of TScriptASMToken;

  TScriptAssembler = class
    public
      procedure Assemble(Script: TBytecodeScriptHandle);
    end;

implementation

uses
  u_functions, m_varlist;

procedure TScriptAssembler.Assemble(Script: TBytecodeScriptHandle);
const
  TokNames: Array[TScriptASMTokenType] of String =
    ('#UNKNOWN', '#INSTRUCTION', '%float', '%int', '%int', '%addr', '[', ']', '%addr', '%ireg', '%vreg');
  VRegisters: Array[0..15] of String =
    ('R0', 'R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7', 'R8', 'R9', 'R10', 'R11', 'R12', 'R13', 'R14', 'R15');
  IRegisters: Array[0..15] of String =
    ('I0', 'I1', 'I2', 'I3', 'I4', 'I5', 'I6', 'I7', 'I8', 'I9', 'I10', 'I11', 'I12', 'I13', 'I14', 'I15');


  function ParseLine(A: String): AScriptASMToken;
  var
    i, j: Integer;
    Curr: TScriptASMToken;
  begin
    Curr.Value := '';
    Curr.TType := atUnknown;
    A := A + ' ';
    i := 1;
    setLength(Result, 0);
    while i < length(A) do
      begin
      case A[i] of
        '@':
          begin
          inc(i);
          Curr.TType := atLabel;
          while (not isWhitespace(A[i])) and (A[i] <> ']') do
            begin
            Curr.Value += A[i];
            inc(i);
            end;
          end;
        '[':
          begin
          Curr.TType := atBracketL;
          Curr.Value += A[i];
          inc(i);
          end;
        ']':
          begin
          Curr.TType := atBracketR;
          Curr.Value += A[i];
          inc(i);
          end;
        '0'..'9', '-':
          begin
          Curr.TType := atInt;
          while (not isWhitespace(A[i])) and (A[i] <> ']') and (A[i] <> 'f') do
            begin
            Curr.Value += A[i];
            if A[i] = '.' then
              Curr.TType := atFloat;
            inc(i);
            end;
          if A[i] = 'f' then
            begin
            Curr.TType := atFloat;
            inc(i);
            end;
          end;
        'a'..'z', 'A'..'Z':
          begin
          Curr.TType := atInstruction;
          while (not isWhitespace(A[i])) and (A[i] <> ']') do
            begin
            Curr.Value += A[i];
            inc(i);
            end;
          for j := 0 to high(VRegisters) do
            if VRegisters[j] = Curr.Value then
              begin
              Curr.TType := atVecRegister;
              Curr.Value := IntToStr(j);
              end;
          for j := 0 to high(IRegisters) do
            if IRegisters[j] = Curr.Value then
              begin
              Curr.TType := atIntRegister;
              Curr.Value := IntToStr(j);
              end;
          end;
        else
          inc(i);
        end;
      if Curr.TType <> atUnknown then
        begin
        SetLength(Result, length(Result) + 1);
        Result[high(Result)] := Curr;
        Curr.TType := atUnknown;
        Curr.Value := '';
        end;
      end;
    for i := 0 to high(Result) - 2 do
      if Result[i].TType = atBracketL then
        if Result[i + 1].TType = atInt then
          Result[i + 1].TType := atAddress
        else if Result[i + 1].TType = atLabel then
          Result[i + 1].TType := atReferenceLabel;
  end;

var
  Lines: AString;
  I, J, K, Start: Integer;
  fOffset: PtrUInt;
  Commands: Array of AScriptASMToken;
  CmdMasks: Array of String;
  OPCodes: Array of TScriptCommand;
  LabelName: String;
begin
  Lines := Explode(#10, Script.ASMCode);
  Start := 0;
  if Lines[0] = 'ASM:' then
    Start := 1;

  // Create tokens
  setLength(Commands, Length(Lines) - Start);
  for i := 0 to high(Lines) do
    Commands[i] := ParseLine(Lines[i + Start]);

  // Generate command masks and label offsets
  fOffset := 2;
  setLength(CmdMasks, length(Commands));
  setLength(OPCodes, length(Commands));
  
  for i := 0 to high(Commands) do
    begin
    CmdMasks[i] := '';
    if length(Commands[i]) > 0 then
      begin
      if Commands[i, 0].TType = atLabel then
        Script.Functions[Commands[i, 0].Value] := fOffset
      else
        begin
        for j := 0 to high(Commands[i]) do
          begin
          if CmdMasks[i] <> '' then
            CmdMasks[i] += ' ';
          if Commands[i, j].TType = atInstruction then
            CmdMasks[i] += Commands[i, j].Value
          else
            CmdMasks[i] += TokNames[Commands[i, j].TType];
          end;
        OPCodes[i] := ModuleManager.ModScriptManager.CommandList.GetByMask(CmdMasks[i]);
        if OPCodes[i].Mask <> CmdMasks[i] then
          ModuleManager.ModLog.AddError('Operation ' + CmdMasks[i] + ' does not exist, inserting ' + OPCodes[i].Mask);
        inc(fOffset, ModuleManager.ModScriptManager.CommandList.List[OPCodes[i].OPCode].Length);
        end;
      end;
    end;

  // Replace Labels by their address
  for i := 0 to high(Commands) do
    for j := 1 to high(Commands[i]) do
      begin
      if Commands[i, j].TType = atLabel then
        Commands[i, j].TType := atInt
      else if Commands[i, j].TType = atReferenceLabel then
        Commands[i, j].TType := atAddress;
      if (Commands[i, j].TType = atReferenceLabel) or (Commands[i, j].TType = atLabel) then
        begin
        LabelName := Commands[i, j].Value;
        Commands[i, j].Value := IntToStr(Script.Functions[LabelName]);
        if Commands[i, j].Value = '0' then
          ModuleManager.ModLog.AddError('Label ' + LabelName + ' not defined, setting it to ' + Commands[i, j].Value);
        end;
      end;

  // Create final bytecode
  SetLength(Script.ByteCode, fOffset);
  Word((@Script.ByteCode[0])^) := 0; // Insert a NOP

  fOffset := 2;

  for i := 0 to high(Commands) do
    begin
    Word((@Script.ByteCode[fOffset])^) := OPCodes[i].OPCode;
    inc(fOffset, 2);
    for j := 1 to high(Commands[i]) do
      try
        case Commands[i, j].TType of
          atAddress, atInt:
            begin
            PtrUInt((@Script.ByteCode[fOffset])^) := StrToInt(Commands[i, j].Value);
            inc(fOffset, SizeOf(PtrUInt));
            end;
          atFloat:
            begin
            Single((@Script.ByteCode[fOffset])^) := StrToFloat(Commands[i, j].Value);
            inc(fOffset, SizeOf(Single));
            end;
          atVecRegister, atIntRegister:
            begin
            Byte((@Script.ByteCode[fOffset])^) := StrToInt(Commands[i, j].Value);
            inc(fOffset, SizeOf(Byte));
            end;
          end;
      except
        ModuleManager.ModLog.AddError('Error assembling ' + TokNames[Commands[i, j].TType] + ' ' + Commands[i, j].Value + ': Type mismatch?');
      end;
    end;
end;

end.