unit m_scriptmng_bytecode_cmdlist;

interface

uses
  SysUtils, Classes, m_scriptmng_bytecode_vm, u_scripts;

type
  TScriptOperation = procedure(C: Pointer);

  TScriptCommand = record
    OPCode: Word;
    Mask: String;
    Operation: TScriptOperation;
    Length: PtrUInt;
    end;
  PScriptCommand = ^TScriptCommand;

  TScriptCMDList = class
    protected
      fCounter: Integer;
    public
      List: Array[Word] of TScriptCommand;
      function GetByMask(S: String): TScriptCommand;
      procedure Add(A: TScriptCommand);
      constructor Create;
    end;

implementation

uses
  m_scriptmng_bytecode_vm_runner, m_varlist;

function _(B: String; C: TScriptOperation; D: PtrUInt): TScriptCommand;
begin
  Result.Mask := B;
  Result.Operation := C;
  Result.Length := D;
end;

procedure TScriptCMDList.Add(A: TScriptCommand);
begin
  inc(fCounter);
  A.OPCode := fCounter;
  if List[A.OPCode].Operation <> nil then
    ModuleManager.ModLog.AddWarning('Command ' + A.Mask + ' overwrites ' + List[A.OPCode].Mask);
  List[A.OPCode] := A;
end;

function TScriptCMDList.GetByMask(S: String): TScriptCommand;
var
  I: Word;
begin
  Result.Operation := @_NOP;
  Result.Length := 2;
  Result.OPCode := $0000;
  Result.Mask := 'NOP';
  for i := 0 to high(List) do
    if List[i].Mask = S then
      Exit(List[i]);
end;

constructor TScriptCMDList.Create;
var
  i: Word;
begin
  fCounter := 0;

  // Pre-fill the list wil empties
  for i := Low(Word) to high(Word) do
    List[i].Operation := nil;


  // Debugging OPs
  Add(_('WRITE %vreg',                          @_WRITEVR,     SizeOf(Word) + SizeOf(Byte)));
  Add(_('WRITE %ireg',                          @_WRITEIR,     SizeOf(Word) + SizeOf(Byte)));

  // Stack OPs
  Add(_('PUSH %int',                            @_PUSHI,       SizeOf(Word) + SizeOf(SInt)));
  Add(_('PUSH %ireg',                           @_PUSHIR,      SizeOf(Word) + SizeOf(Byte)));
  Add(_('PUSH %vreg',                           @_PUSHVR,      SizeOf(Word) + SizeOf(Byte)));
  Add(_('PUSHM %vreg',                          @_PUSHMR,      SizeOf(Word) + SizeOf(Byte)));

  Add(_('POP %ireg',                            @_POPI,        SizeOf(Word) + SizeOf(Byte)));
  Add(_('POP %vreg',                            @_POPV,        SizeOf(Word) + SizeOf(Byte)));
  Add(_('POPM %vreg',                           @_POPM,        SizeOf(Word) + SizeOf(Byte)));

  // Register OPs
  Add(_('LD %vreg %float',                      @_LDV1,        SizeOf(Word) + SizeOf(Byte) + 1 * SizeOf(Single)));
  Add(_('LD %vreg %float %float',               @_LDV2,        SizeOf(Word) + SizeOf(Byte) + 2 * SizeOf(Single)));
  Add(_('LD %vreg %float %float %float',        @_LDV3,        SizeOf(Word) + SizeOf(Byte) + 3 * SizeOf(Single)));
  Add(_('LD %vreg %float %float %float %float', @_LDV4,        SizeOf(Word) + SizeOf(Byte) + 4 * SizeOf(Single)));

  Add(_('LD %ireg %int',                        @_LDI,         SizeOf(Word) + SizeOf(Byte) + 1 * SizeOf(SInt)));

  Add(_('LD %ireg SP',                          @_LDISP,       SizeOf(Word) + SizeOf(Byte)));
  Add(_('LD SP %ireg',                          @_LDSPI,       SizeOf(Word) + SizeOf(Byte)));

  Add(_('LD %ireg [%ireg]',                     @_LDIA,        SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD1 %vreg [%ireg]',                    @_LDV1A,       SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD2 %vreg [%ireg]',                    @_LDV2A,       SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD3 %vreg [%ireg]',                    @_LDV3A,       SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD %vreg [%ireg]',                     @_LDV4A,       SizeOf(Word) + 2 * SizeOf(Byte)));

  Add(_('LD [%ireg] %ireg',                     @_LDAI,        SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD1 [%ireg] %vreg',                    @_LDAV1,       SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD2 [%ireg] %vreg',                    @_LDAV2,       SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD3 [%ireg] %vreg',                    @_LDAV3,       SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD [%ireg] %vreg',                     @_LDAV4,       SizeOf(Word) + 2 * SizeOf(Byte)));

  Add(_('LD %vreg %int %vreg %int',             @_LDVRCVRC,    SizeOf(Word) + 2 * SizeOf(Byte) + 2 * SizeOf(PtrUInt)));

  Add(_('LD %ireg %ireg',                       @_LDIRIR,      SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD %vreg %vreg',                       @_LDVRVR,      SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD %vreg %ireg',                       @_LDVRIR,      SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LD %ireg %vreg',                       @_LDIRVR,      SizeOf(Word) + 2 * SizeOf(Byte)));


  // Math OPs

  Add(_('ADD %ireg %ireg %ireg',                @_ADDI,        SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('ADD %vreg %vreg %vreg',                @_ADDV,        SizeOf(Word) + 3 * SizeOf(Byte)));

  Add(_('SUB %ireg %ireg %ireg',                @_SUBI,        SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('SUB %vreg %vreg %vreg',                @_SUBV,        SizeOf(Word) + 3 * SizeOf(Byte)));

  Add(_('MUL %ireg %ireg %ireg',                @_MULI,        SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('MUL %vreg %vreg %vreg',                @_MULV,        SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('MULMV %vreg %vreg %vreg',              @_MULMV,       SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('MULMM %vreg %vreg %vreg',              @_MULMM,       SizeOf(Word) + 3 * SizeOf(Byte)));

  Add(_('DIV %ireg %ireg %ireg',                @_DIVI,        SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('DIV %vreg %vreg %vreg',                @_DIVV,        SizeOf(Word) + 3 * SizeOf(Byte)));

  Add(_('RND %vreg %ireg',                      @_RNDI,        SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('RND %vreg %vreg',                      @_RNDV,        SizeOf(Word) + 2 * SizeOf(Byte)));

  Add(_('SQRT %vreg %vreg',                     @_SQRT,        SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('POW %vreg %vreg %vreg',                @_POW,         SizeOf(Word) + 3 * SizeOf(Byte)));
  

  // Vector OPs

  Add(_('DOT2 %vreg %vreg %vreg',               @_DOT2,        SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('DOT3 %vreg %vreg %vreg',               @_DOT3,        SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('DOT4 %vreg %vreg %vreg',               @_DOT4,        SizeOf(Word) + 3 * SizeOf(Byte)));
  
  Add(_('NORM2 %vreg %vreg',                    @_NORM2,       SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('NORM3 %vreg %vreg',                    @_NORM3,       SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('NORM4 %vreg %vreg',                    @_NORM4,       SizeOf(Word) + 2 * SizeOf(Byte)));

  Add(_('LEN2 %vreg %vreg',                     @_LEN2,        SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LEN3 %vreg %vreg',                     @_LEN3,        SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('LEN4 %vreg %vreg',                     @_LEN4,        SizeOf(Word) + 2 * SizeOf(Byte)));

  Add(_('CROSS %vreg %vreg %vreg',              @_CROSS,       SizeOf(Word) + 3 * SizeOf(Byte)));

  // Special matrix operations

  Add(_('TRANSLM %vreg %vreg',                  @_TRANSLM,     SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('ROTM %vreg %vreg',                     @_ROTM,        SizeOf(Word) + 2 * SizeOf(Byte)));
  Add(_('ORIENTM %vreg %vreg',                  @_ORIENTM,     SizeOf(Word) + 2 * SizeOf(Byte)));


  // Boolean OPs

  Add(_('AND %ireg %ireg %ireg',                @_AND,         SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('OR %ireg %ireg %ireg',                 @_OR,          SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('XOR %ireg %ireg %ireg',                @_XOR,         SizeOf(Word) + 3 * SizeOf(Byte)));
  Add(_('NOT %ireg %ireg',                      @_NOT,         SizeOf(Word) + 2 * SizeOf(Byte)));

  // Comparators

  ADD(_('LT %ireg %ireg',                       @_LTI,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('LT %vreg %vreg',                       @_LTV,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('LE %ireg %ireg',                       @_LEI,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('LE %vreg %vreg',                       @_LEV,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('GT %ireg %ireg',                       @_GTI,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('GT %vreg %vreg',                       @_GTV,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('GE %ireg %ireg',                       @_GEI,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('GE %vreg %vreg',                       @_GEV,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('EQ %ireg %ireg',                       @_EQI,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('EQ %vreg %vreg',                       @_EQV,         SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('NEQ %ireg %ireg',                      @_NEQI,        SizeOf(Word) + 2 * SizeOf(Byte)));
  ADD(_('NEQ %vreg %vreg',                      @_NEQV,        SizeOf(Word) + 2 * SizeOf(Byte)));


  // Program Flow OPs
  
  Add(_('JMP [%addr]',                          @_JMPI,        SizeOf(Word) + SizeOf(PtrUInt)));
  Add(_('JMP [%ireg]',                          @_JMPIR,       SizeOf(Word) + SizeOf(Byte)));

  Add(_('JMP0 [%addr]',                         @_JMP0I,       SizeOf(Word) + SizeOf(PtrUInt)));
  Add(_('JMP0 [%ireg]',                         @_JMP0IR,      SizeOf(Word) + SizeOf(Byte)));

  Add(_('CALL [%addr]',                         @_CALLI,       SizeOf(Word) + SizeOf(PtrUInt)));
  Add(_('CALL [%ireg]',                         @_CALLIR,      SizeOf(Word) + SizeOf(Byte)));
  Add(_('CALL0 [%addr]',                        @_CALL0I,      SizeOf(Word) + SizeOf(PtrUInt)));
  Add(_('CALL0 [%ireg]',                        @_CALL0IR,     SizeOf(Word) + SizeOf(Byte)));

  Add(_('RET',                                  @_RET,         SizeOf(Word)));
  Add(_('RET0',                                 @_RET0,        SizeOf(Word)));


  // Replace the empties with NOPs
  for i := Low(Word) to high(Word) do
    if List[i].Operation = nil then
      with List[i] do
        begin
        OPCode := i;
        Mask := 'NOP';
        Operation := @_NOP;
        Length := SizeOf(Word);
        end;
end;

end.