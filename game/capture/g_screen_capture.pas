unit g_screen_capture;

interface

uses
  SysUtils, Classes, u_files, m_inputhandler_class;

type
  TScreenCaptureMode = (cmNone, cmScreenshot, cmVideo);

  TScreenCaptureTool = class
    protected
      // Video capture stuff
      Buffer: Array[0..3] of TByteStream;
      ResX, ResY: Integer;
      fCurrentBuffer: Byte;
      fCurrentFrameID: Integer;
      fVideoBasename: String;

      // General
      fCurrentMode: TScreenCaptureMode;

      procedure InitVideo;
      procedure FinishVideo;

      procedure CaptureVideoFrame(Event: String; Data, Result: Pointer);
      procedure CaptureScreenshot(Event: String; Data, Result: Pointer);
      procedure HandleKeypress(Event: String; Data, Result: Pointer);
    public
      property CurrentMode: TScreenCaptureMode read fCurrentMode;
      procedure Advance;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, main;

procedure TScreenCaptureTool.InitVideo;
var
  i: Integer;
begin
  fCurrentBuffer := 0;
  fCurrentFrameID := 1;

  fVideoBasename := ModuleManager.ModPathes.Convert(ModuleManager.ModPathes.PersonalDataPath + 'videos/Video_');
  i := 0;
  while DirectoryExists(fVideoBasename + IntToStr(i)) do
    inc(i);
  fVideoBasename := fVideoBasename + IntToStr(i);

  ForceDirectories(fVideoBasename);
  writeln('Recording video to ' + fVideoBasename);

  fVideoBasename := ModuleManager.ModPathes.Convert(fVideoBasename + '/frame_');

  fCurrentMode := cmVideo;
  EventManager.AddCallback('TRenderer.CaptureNow', @CaptureVideoFrame);
  ModuleManager.ModRenderer.CaptureNextFrame := True;
end;

procedure TScreenCaptureTool.FinishVideo;
begin
  EventManager.RemoveCallback(@CaptureVideoFrame);
  fCurrentMode := cmNone;

  writeln('Finished recording');
end;

procedure TScreenCaptureTool.CaptureVideoFrame(Event: String; Data, Result: Pointer);
var
  Values: Array[0..3] of DWord;
  BPointers: Array[0..3] of Pointer;
  nPointer: Pointer;
  i: Integer;
  tmp: DWord;
  final: DWord;
  b: TByteStream;
  ByPP: Integer;

  function IntToStrLeadingZeroes(N: Integer): String;
  begin
    Result := IntToStr(N);
    while Length(Result) < 8 do
      Result := '0' + Result;
  end;
  
begin
  Buffer[fCurrentBuffer] := ModuleManager.ModRenderer.Capture;
  inc(fCurrentBuffer);

  // Blend them together and save them
  if fCurrentBuffer = 4 then
    begin
    ByPP := 3;
    SetLength(b.Data, 18 + ResX * ResY * ByPP + 26);
    b.Data[0] := 0;
    b.Data[1] := 0;
    b.Data[2] := 2;
    Word((@b.Data[3])^) := 0;
    Word((@b.Data[5])^) := 0;
    b.Data[7] := 0;
    Word((@b.Data[8])^) := 0;
    Word((@b.Data[10])^) := 0;
    Word((@b.Data[12])^) := ResX;
    Word((@b.Data[14])^) := ResY;
    b.Data[16] := ByPP * 8;
    b.Data[17] := 0;

    fCurrentBuffer := 0;

    BPointers[0] := @Buffer[0].Data[18]; // 18 = TGA offset of datablock
    BPointers[1] := @Buffer[1].Data[18];
    BPointers[2] := @Buffer[2].Data[18];
    BPointers[3] := @Buffer[3].Data[18];

    nPointer := @b.Data[18];

    for i := 0 to ResX * ResY - 1 do
      begin
      Values[0] := DWord(BPointers[0]^);
      Values[1] := DWord(BPointers[1]^);
      Values[2] := DWord(BPointers[2]^);
      Values[3] := DWord(BPointers[3]^);

      tmp := ((Values[0] and $FF) + (Values[1] and $FF) + (Values[2] and $FF) + (Values[3] and $FF)) shr 2;
      final := tmp and $FF;
      
      tmp := ((Values[0] and $FF00) + (Values[1] and $FF00) + (Values[2] and $FF00) + (Values[3] and $FF00)) shr 2;
      final := final or (tmp and $FF00);

      tmp := ((Values[0] and $FF0000) + (Values[1] and $FF0000) + (Values[2] and $FF0000) + (Values[3] and $FF0000)) shr 2;
      final := final or (tmp and $FF0000);

      DWord(nPointer^) := final;

      inc(BPointers[0], 4);
      inc(BPointers[1], 4);
      inc(BPointers[2], 4);
      inc(BPointers[3], 4);
      inc(nPointer, 3);
      end;

    ByteStreamToFile(fVideoBasename + IntToStrLeadingZeroes(fCurrentFrameID) + '.tga', b);

    DWord((@b.Data[Length(b.Data) - 26])^) := 0;
    DWord((@b.Data[Length(b.Data) - 22])^) := 0;
    b.Data[Length(b.Data) - 18] := Ord('T');
    b.Data[Length(b.Data) - 17] := Ord('R');
    b.Data[Length(b.Data) - 16] := Ord('U');
    b.Data[Length(b.Data) - 15] := Ord('E');
    b.Data[Length(b.Data) - 14] := Ord('V');
    b.Data[Length(b.Data) - 13] := Ord('I');
    b.Data[Length(b.Data) - 12] := Ord('S');
    b.Data[Length(b.Data) - 11] := Ord('I');
    b.Data[Length(b.Data) - 10] := Ord('O');
    b.Data[Length(b.Data) - 09] := Ord('N');
    b.Data[Length(b.Data) - 08] := Ord('-');
    b.Data[Length(b.Data) - 07] := Ord('X');
    b.Data[Length(b.Data) - 06] := Ord('F');
    b.Data[Length(b.Data) - 05] := Ord('I');
    b.Data[Length(b.Data) - 04] := Ord('L');
    b.Data[Length(b.Data) - 03] := Ord('E');
    b.Data[Length(b.Data) - 02] := Ord('.');
    b.Data[Length(b.Data) - 01] := 0;

    inc(fCurrentFrameID);
    end;

  ModuleManager.ModRenderer.CaptureNextFrame := True;
end;

procedure TScreenCaptureTool.CaptureScreenshot(Event: String; Data, Result: Pointer);
var
  i: Integer;
  BasicPath: String;
begin
  BasicPath := ModuleManager.ModPathes.Convert(ModuleManager.ModPathes.PersonalDataPath + 'screenshots/Screenshot_');

  ForceDirectories(ModuleManager.ModPathes.Convert(ModuleManager.ModPathes.PersonalDataPath + 'screenshots'));
  
  i := 0;
  while FileExists(BasicPath + IntToStr(i) + '.tga') do
    inc(i);
  BasicPath := BasicPath + IntToStr(i) + '.tga';
  ByteStreamToFile(BasicPath, ModuleManager.ModRenderer.Capture);
  writeln('Saved screenshot to ' + BasicPath);

  fCurrentMode := cmNone;
  EventManager.RemoveCallback(@CaptureScreenshot);
end;

procedure TScreenCaptureTool.HandleKeypress(Event: String; Data, Result: Pointer);
begin
  case Integer(Result^) of
    K_F10:
      begin
      fCurrentMode := cmScreenshot;
      EventManager.AddCallback('TRenderer.CaptureNow', @CaptureScreenshot);
      ModuleManager.ModRenderer.CaptureNextFrame := True;
      end;
    K_F11:
      if fCurrentMode <> cmVideo then
        InitVideo
      else
        FinishVideo;
    end;
end;

procedure TScreenCaptureTool.Advance;
begin
  if fCurrentMode = cmVideo then
    begin
    FPSDisplay.MS := 10;
    FPSDisplay.FPS := 100;
    end;
end;

constructor TScreenCaptureTool.Create;
begin
  fCurrentMode := cmNone;

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);

  EventManager.AddCallback('BasicComponent.OnKeyDown', @HandleKeypress);
end;

destructor TScreenCaptureTool.Free;
begin
  EventManager.RemoveCallback(@HandleKeypress);
  EventManager.RemoveCallback(@CaptureScreenshot);
  EventManager.RemoveCallback(@CaptureVideoFrame);
end;

end.