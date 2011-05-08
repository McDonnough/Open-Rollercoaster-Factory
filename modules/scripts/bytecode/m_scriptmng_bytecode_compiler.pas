unit m_scriptmng_bytecode_compiler;

interface

uses
  SysUtils, Classes, u_scripts, m_scriptmng_bytecode_classes, m_scriptmng_bytecode_compiler_tokenizer,
  m_scriptmng_bytecode_compiler_tree_generator, m_scriptmng_bytecode_compiler_code_generator,
  m_scriptmng_bytecode_compiler_asm_optimizer;

type
  TBytecodeScriptHandle = class;

  TScriptCompiler = class
    protected
      fTokenList: TTokenList;
      fTokenizer: TTokenizer;
      fStatementTree: TStatementTree;
      fASMTable: TASMTable;
      fStatementTreeGenerator: TStatementTreeGenerator;
      fCodeGenerator: TCodeGenerator;
      fASMOptimizer: TASMOptimizer;
    public
      property CodeGenerator: TCodeGenerator read fCodeGenerator;
      procedure Compile(Handle: TBytecodeScriptHandle);
      constructor Create;
      destructor Free;
    end;

  TBytecodeScriptHandle = class
    protected
      fFirstByte: Pointer;
      fFunctionTable: TLocationTable;
      fGlobalLocations: TLocationTable;
    public
      Code: TScriptCode;
      ASMCode: String;
      ByteCode: Array of Byte;
      property FirstByte: Pointer read fFirstByte;
      property Functions: TLocationTable read fFunctionTable;
      property GlobalLocations: TLocationTable read fGlobalLocations;
      procedure Compile;
      procedure Assemble;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_functions;

procedure TScriptCompiler.Compile(Handle: TBytecodeScriptHandle);
begin
  Handle.ASMCode := 'ASM:' + #10;
  writeln('Compiling ' + Handle.Code.Name);
  try
    fTokenList := fTokenizer.Tokenize(Handle.Code.SourceCode);
    fStatementTree := fStatementTreeGenerator.GenerateTree(fTokenList);
    fASMTable := fCodeGenerator.GenerateCode(fStatementTree);
    Handle.ASMCode := fASMOptimizer.Optimize(fASMTable);
    fASMTable.Free;
    fStatementTree.Free;
    fTokenList.Free;
  except
    ModuleManager.ModLog.AddError('Compilation aborted.');
  end;
end;

constructor TScriptCompiler.Create;
begin
  fTokenizer := TTokenizer.Create;
  fStatementTreeGenerator := TStatementTreeGenerator.Create;
  fCodeGenerator := TCodeGenerator.Create;
  fASMOptimizer := TASMOptimizer.Create;
end;

destructor TScriptCompiler.Free;
begin
  fASMOptimizer.Free;
  fCodeGenerator.Free;
  fStatementTreeGenerator.Free;
  fTokenizer.Free;
end;


procedure TBytecodeScriptHandle.Compile;
begin
  ModuleManager.ModScriptManager.Compiler.Compile(self);
end;

procedure TBytecodeScriptHandle.Assemble;
begin
  ModuleManager.ModScriptManager.Assembler.Assemble(self);
  fFirstByte := @ByteCode[0];
  ASMCode := '';
end;

constructor TBytecodeScriptHandle.Create;
begin
  fFunctionTable := TLocationTable.Create;
  fGlobalLocations := TLocationTable.Create;
  fFirstByte := nil;
end;

destructor TBytecodeScriptHandle.Free;
begin
  fGlobalLocations.Free;
  fFunctionTable.Free;
  setLength(ByteCode, 0);
end;

end.