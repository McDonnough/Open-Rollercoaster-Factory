unit u_dialogs;

interface

uses
  SysUtils, Classes, u_events, main, m_gui_class, m_gui_window_class, m_gui_label_class, m_gui_tabbar_class, m_gui_iconifiedbutton_class,
  m_gui_edit_class, m_gui_button_class, m_texmng_class, m_gui_scrollbox_class, u_vectors, m_gui_image_class, DGLOpenGL;

type
  TDialogFileUI = record
    BG: TLabel;
    Name, Description: TLabel;
    Select: TIconifiedButton;
    Preview: TImage;
    end;

  TFileDialog = class
    protected
      FileArea, DirArea: TScrollBox;
      fDirList, fFileList: TStringList;
      Files: Array of TDialogFileUI;
      OpenSave, Abort: TIconifiedButton;
      bgLabel, Name, Title: TLabel;
      Window: TWindow;
      Dirs: Array of TButton;
      fDirectory, fFileName: String;
      procedure CallEvent(Sender: TGUIComponent);
      procedure UpdateFileList(Sender: TGUIComponent);
      procedure SelectFile(Sender: TGUIComponent);
      procedure OCFFileLoaded(Event: String; Data, Result: Pointer);
    public
      property Directory: String read fDirectory;
      property FileName: String read fFileName;
      constructor Create(ReadOnly: Boolean; InitialDirectory, TitleString: String);
      destructor Free;
    end;

implementation

uses
  m_varlist, u_files, u_functions, g_loader_ocf;

procedure TFileDialog.OCFFileLoaded(Event: String; Data, Result: Pointer);
var
  Format: GLEnum;
  AR: Single;
begin
  if Integer(Result^) <= high(Files) then
    begin
    Files[Integer(Result^)].Description.Caption := TOCFFile(Data).Description;
    Files[Integer(Result^)].Name.Caption := TOCFFile(Data).Name;
    if TOCFFile(Data).Preview.BPP <> 0 then
      begin
      Format := GL_RGBA;
      if TOCFFile(Data).Preview.BPP = 24 then
        Format := GL_RGB;
      Files[Integer(Result^)].Preview.Tex := TTexture.Create;
      Files[Integer(Result^)].Preview.Tex.CreateNew(TOCFFile(Data).Preview.Width, TOCFFile(Data).Preview.Height, Format);
      Files[Integer(Result^)].Preview.Tex.Fill(@TOCFFile(Data).Preview.Data[0], Format);
      AR := TOCFFile(Data).Preview.Width / TOCFFile(Data).Preview.Height;
      if AR > 1 then
        begin
        Files[Integer(Result^)].Preview.Height := Files[Integer(Result^)].Preview.Height / AR;
        Files[Integer(Result^)].Preview.Top := 0.5 * (96 - Files[Integer(Result^)].Preview.Height / AR);
        end
      else if AR < 1 then
        begin
        Files[Integer(Result^)].Preview.Width := Files[Integer(Result^)].Preview.Width * AR;
        Files[Integer(Result^)].Preview.Left := 0.5 * (96 - Files[Integer(Result^)].Preview.Width * AR);
        end;
      end;
    end;
end;

procedure TFileDialog.CallEvent(Sender: TGUIComponent);
begin
  if Sender = OpenSave then
    EventManager.CallEvent('TFileDialog.Selected', @fFileName, nil)
  else if Sender = Abort then
    EventManager.CallEvent('TFileDialog.Aborted', @fFileName, nil);
end;

procedure TFileDialog.SelectFile(Sender: TGUIComponent);
begin
  fFileName := fFileList.Strings[Sender.Tag];
  Name.Caption := 'Selected file: ' + fFileName;
end;

procedure TFileDialog.UpdateFileList(Sender: TGUIComponent);
var
  i: Integer;
  fOldDirectory: String;
begin
  try
    fOldDirectory := fDirectory;
    if Sender <> nil then
      if (Sender.Tag > 0) then
        begin
        if Sender.Tag = 1 then
          begin
          if fDirectory[length(fDirectory)] = '/' then
            fDirectory := ExtractFilePath(SubString(fDirectory, 1, Length(fDirectory) - 1))
          else
            fDirectory := ExtractFilePath(fDirectory);
          end
        else
          fDirectory := fDirList[Sender.Tag - 1] + '/';
        end;
    Name.Caption := 'Selected file: ' + fDirectory;

    DirArea.VScrollPosition := 0;
    FileArea.VScrollPosition := 0;

    fDirList.Clear;
    fFileList.Clear;

    GetDirectoriesInDirectory(fDirectory, fDirList);
    GetFilesInDirectory(fDirectory, '*.ocf', fFileList, false, false);
    fDirList.Sort;
    fFileList.Sort;

    for i := 0 to high(Dirs) do
      Dirs[i].Free;

    SetLength(Dirs, fDirList.Count);
    for i := 0 to high(Dirs) do
      begin
      Dirs[i] := TButton.Create(DirArea.Surface);
      Dirs[i].Left := 0;
      Dirs[i].Top := 32 * i;
      Dirs[i].Width := 144;
      Dirs[i].Height := 32;
      Dirs[i].Tag := i + 1;
      Dirs[i].OnClick := @UpdateFileList;
      if ExtractFileName(fDirList.Strings[i]) <> '..' then
        Dirs[i].Caption := ExtractFileName(fDirList.Strings[i])
      else
        Dirs[i].Caption := '<< Up <<';
      end;

    for i := 0 to high(Files) do
      Files[i].BG.Free;

    SetLength(Files, fFileList.Count);
    for i := 0 to high(Files) do
      with Files[i] do
        begin
        BG := TLabel.Create(FileArea);
        BG.Top := 96 * i;
        BG.Left := 0;
        BG.Width := 500;
        BG.Height := 96;
        BG.Color := Vector(0, 0, 0, 0.1 - 0.1 * (i mod 2));

        Name := TLabel.Create(BG);
        Name.Left := 104;
        Name.Width := 396;
        Name.Top := 0;
        Name.Height := 24;
        Name.Size := 24;
        Name.Caption := ExtractFileName(fFileList.Strings[i]);

        Description := TLabel.Create(BG);
        Description.Left := 104;
        Description.Top := 24;
        Description.Height := 72;
        Description.Size := 16;
        Description.Width := 396;
        Description.Caption := '[Waiting]';

        Select := TIconifiedButton.Create(BG);
        Select.Width := 32;
        Select.Height := 32;
        Select.Left := 468;
        Select.Top := 64;
        Select.Icon := 'dialog-ok-apply.tga';
        Select.Tag := i;
        Select.OnClick := @SelectFile;

        Preview := TImage.Create(BG);
        Preview.Left := 0;
        Preview.Top := 0;
        Preview.Width := 96;
        Preview.Height := 96;
        Preview.FreeTextureOnDestroy := true;

        ModuleManager.ModOCFManager.RequestOCFFile(fFileList.Strings[i], 'TFileOpenDialog.LoadedOCFFile', @Select.Tag);
        end;
  except
    ModuleManager.ModLog.AddError('Cannot change directory from ' + fDirectory);
    fDirectory := fOldDirectory;
    UpdateFileList(nil);
  end;
end;

constructor TFileDialog.Create(ReadOnly: Boolean; InitialDirectory, TitleString: String);
var
  ResX, ResY: Integer;
begin
  InitialDirectory := GetFirstExistingFileName(InitialDirectory);
  if InitialDirectory = '' then
    InitialDirectory := ModuleManager.ModPathes.PersonalDataPath;

  ModuleManager.ModGlContext.GetResolution(ResX, ResY);

  bgLabel := TLabel.Create(nil);
  bgLabel.Left := 0;
  bgLabel.Top := 0;
  bgLabel.Height := ResY;
  bgLabel.Width := ResX;

  Window := TWindow.Create(bgLabel);
  Window.Width := 700;
  Window.Height := 400;
  Window.Left := (ResX - 700) / 2;
  Window.Top := (ResY - 400) / 2;
  Window.OfsY1 := 32;
  Window.OfsX1 := 168;
  Window.OfsY2 := 24;

  DirArea := TScrollBox.Create(Window);
  DirArea.Top := 40;
  DirArea.Left := 8;
  DirArea.Width := 160;
  DirArea.Height := 328;
  DirArea.HScrollBar := sbmInvisible;
  DirArea.VScrollBar := sbmInverted;

  FileArea := TScrollBox.Create(Window);
  FileArea.Top := 40;
  FileArea.Left := 176;
  FileArea.Height := 328;
  FileArea.Width := 516;
  FileArea.HScrollBar := sbmInvisible;
  FileArea.VScrollBar := sbmNormal;

  Title := TLabel.Create(Window);
  Title.Top := 8;
  Title.Left := 8;
  Title.Width := 692;
  Title.Height := 24;
  Title.Size := 24;
  Title.Caption := TitleString;

  Name := TLabel.Create(Window);
  Name.Left := 8;
  Name.Height := 16;
  Name.Size := 16;
  Name.Width := 592;
  Name.Top := 376;
  Name.Caption := 'Selected file: ' + InitialDirectory;

  OpenSave := TIconifiedButton.Create(Window);
  OpenSave.Left := 600;
  OpenSave.Width := 48;
  OpenSave.Height := 48;
  OpenSave.Top := 344;
  OpenSave.OnClick := @CallEvent;
  if ReadOnly then
    OpenSave.Icon := 'document-open.tga'
  else
    OpenSave.Icon := 'document-save.tga';

  Abort := TIconifiedButton.Create(Window);
  Abort.Left := 644;
  Abort.Width := 48;
  Abort.Height := 48;
  Abort.Top := 344;
  Abort.OnClick := @CallEvent;
  Abort.Icon := 'dialog-cancel.tga';

  EventManager.AddCallback('TFileOpenDialog.LoadedOCFFile', @OCFFileLoaded);

  fDirectory := InitialDirectory;
  fFileName := '';

  fFileList := TStringList.Create;
  fDirList := TStringList.Create;
  UpdateFileList(Window);
end;

destructor TFileDialog.Free;
begin
  EventManager.RemoveCallback(@OCFFileLoaded);
  fDirList.Free;
  fFileList.Free;
  bgLabel.Free;
end;

end.