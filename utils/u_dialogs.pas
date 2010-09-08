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

  TOKDialog = class
    protected
      fBGLabel, fText, fTitle: TLabel;
      fWindow: TWindow;
      fBtnOK: TButton;
      fIcon: TImage;
      procedure CallSignals(Sender: TGUIComponent);
    public
      constructor Create(Message, Icon: String);
      destructor Free;
    end;

  TYesNoDialog = class
    protected
      fBGLabel, fText, fTitle: TLabel;
      fWindow: TWindow;
      fBtnYes, fBtnNo: TButton;
      fIcon: TImage;
      procedure CallSignals(Sender: TGUIComponent);
    public
      constructor Create(Message, Icon: String);
      destructor Free;
    end;

  TFileDialog = class
    protected
      fRO: Boolean;
      FileArea, DirArea: TScrollBox;
      fDirList, fFileList: TStringList;
      Files: Array of TDialogFileUI;
      OpenSave, Abort: TIconifiedButton;
      bgLabel, Name, Title: TLabel;
      Window: TWindow;
      Dirs: Array of TButton;
      fDirectory, fFileName: String;
      SaveName: TEdit;
      fOKD: TOKDialog;
      fYND: TYesNoDialog;
      procedure CallEvent(Sender: TGUIComponent);
      procedure UpdateFileList(Sender: TGUIComponent);
      procedure SelectFile(Sender: TGUIComponent);
      procedure OCFFileLoaded(Event: String; Data, Result: Pointer);
      procedure FreeDialogs(Event: String; Data, Result: Pointer);
    public
      property Directory: String read fDirectory;
      property FileName: String read fFileName;
      constructor Create(ReadOnly: Boolean; InitialDirectory, TitleString: String);
      destructor Free;
    end;

implementation

uses
  m_varlist, u_files, u_functions, g_loader_ocf;

procedure TOKDialog.CallSignals(Sender: TGUIComponent);
begin
  EventManager.CallEvent('TOKDialog.OK', self, nil);
end;

constructor TOKDialog.Create(Message, Icon: String);
var
  ResX, ResY: Integer;
begin
  ModuleManager.ModGlContext.GetResolution(ResX, ResY);

  fBGLabel := TLabel.Create(nil);
  fBGLabel.Left := 0;
  fBGLabel.Top := 0;
  fBGLabel.Height := ResY;
  fBGLabel.Width := ResX;

  fWindow := TWindow.Create(fBGLabel);
  fWindow.Width := 300;
  fWindow.Height := 128;
  fWindow.Top := 0.5 * (ResY - 128);
  fWindow.Left := 0.5 * (ResX - 300);
  fWindow.OfsY2 := 32;
  fWindow.OfsY1 := 24;
  fWindow.OfsX1 := 56;

  fTitle := TLabel.Create(fWindow);
  fTitle.Left := 8;
  fTitle.Top := 4;
  fTitle.Width := 284;
  fTitle.Height := 24;
  fTitle.Size := 24;
  fTitle.Caption := 'Message';

  fIcon := TImage.Create(fWindow);
  fIcon.Left := 8;
  fIcon.Top := 32;
  fIcon.Width := 48;
  fIcon.Height := 48;
  fIcon.Tex := TTexture.Create;
  fIcon.Tex.FromFile('guiicons/' + Icon);
  fIcon.FreeTextureOnDestroy := true;

  fText := TLabel.Create(fWindow);
  fText.Left := 72;
  fText.Width := 204;
  fText.Top := 32;
  fText.Height := 48;
  fText.Size := 16;
  fText.Caption := Message;

  fBtnOK := TButton.Create(fWindow);
  fBtnOK.Left := 107;
  fBtnOK.Width := 94;
  fBtnOK.Height := 32;
  fBtnOK.Top := 92;
  fBtnOK.Caption := 'OK';
  fBtnOK.OnClick := @CallSignals;
end;

destructor TOKDialog.Free;
begin
  fBGLabel.Free;
end;


procedure TYesNoDialog.CallSignals(Sender: TGUIComponent);
begin
  if Sender = fBtnNo then
    EventManager.CallEvent('TYesNoDialog.No', self, nil)
  else if Sender = fBtnYes then
    EventManager.CallEvent('TYesNoDialog.Yes', self, nil);
end;

constructor TYesNoDialog.Create(Message, Icon: String);
var
  ResX, ResY: Integer;
begin
  ModuleManager.ModGlContext.GetResolution(ResX, ResY);

  fBGLabel := TLabel.Create(nil);
  fBGLabel.Left := 0;
  fBGLabel.Top := 0;
  fBGLabel.Height := ResY;
  fBGLabel.Width := ResX;

  fWindow := TWindow.Create(fBGLabel);
  fWindow.Width := 300;
  fWindow.Height := 128;
  fWindow.Top := 0.5 * (ResY - 128);
  fWindow.Left := 0.5 * (ResX - 300);
  fWindow.OfsY2 := 32;
  fWindow.OfsY1 := 24;
  fWindow.OfsX1 := 56;

  fTitle := TLabel.Create(fWindow);
  fTitle.Left := 8;
  fTitle.Top := 4;
  fTitle.Width := 284;
  fTitle.Height := 24;
  fTitle.Size := 24;
  fTitle.Caption := 'Question';

  fIcon := TImage.Create(fWindow);
  fIcon.Left := 8;
  fIcon.Top := 32;
  fIcon.Width := 48;
  fIcon.Height := 48;
  fIcon.Tex := TTexture.Create;
  fIcon.Tex.FromFile('guiicons/' + Icon);
  fIcon.FreeTextureOnDestroy := true;

  fText := TLabel.Create(fWindow);
  fText.Left := 72;
  fText.Width := 204;
  fText.Top := 32;
  fText.Height := 48;
  fText.Size := 16;
  fText.Caption := Message;

  fBtnYes := TButton.Create(fWindow);
  fBtnYes.Left := 54 + 28;
  fBtnYes.Width := 94;
  fBtnYes.Height := 32;
  fBtnYes.Top := 92;
  fBtnYes.Caption := 'Yes';
  fBtnYes.OnClick := @CallSignals;

  fBtnNo := TButton.Create(fWindow);
  fBtnNo.Left := 152 + 28;
  fBtnNo.Width := 94;
  fBtnNo.Height := 32;
  fBtnNo.Top := 92;
  fBtnNo.Caption := 'No';
  fBtnNo.OnClick := @CallSignals;
end;

destructor TYesNoDialog.Free;
begin
  fBGLabel.Free;
end;


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
        Files[Integer(Result^)].Preview.Height := 96 / AR;
        Files[Integer(Result^)].Preview.Top := 0.5 * (96 - 96 / AR);
        end
      else if AR < 1 then
        begin
        Files[Integer(Result^)].Preview.Width := 96 * AR;
        Files[Integer(Result^)].Preview.Left := 0.5 * (96 - 96 * AR);
        end;
      end;
    end;
end;

procedure TFileDialog.FreeDialogs(Event: String; Data, Result: Pointer);
begin
  if fOKD <> nil then begin fOKD.Free; fOKD := nil; end;
  if fYND <> nil then begin fYND.Free; fYND := nil; end;
  if Event = 'TYesNoDialog.Yes' then
    EventManager.CallEvent('TFileDialog.Selected', @fFileName, nil);
end;

procedure TFileDialog.CallEvent(Sender: TGUIComponent);
begin
  if Sender = OpenSave then
    begin
    if not fRO then
      begin
      if fDirectory[length(fDirectory)] <> ModuleManager.ModPathes.Delimiter then
        fDirectory := fDirectory + ModuleManager.ModPathes.Delimiter;
      fFileName := fDirectory + SaveName.Text;
      if lowercase(ExtractFileExt(fFileName)) <> '.ocf' then
        fFileName := fFileName + '.ocf';
      if DirectoryExists(fFileName) then
        fOKD := TOKDialog.Create('Filename is a directory.', 'dialog-error.tga')
      else if FileExists(fFileName) then
        fYND := TYesNoDialog.Create('File does already exist. Overwrite?', 'dialog-warning.tga')
      else
        EventManager.CallEvent('TFileDialog.Selected', @fFileName, nil);
      end
    else
      begin
      if (not(FileExists(fFileName))) or (DirectoryExists(fFileName)) then
        fOKD := TOKDialog.Create('File does not exist', 'dialog-error.tga')
      else
        EventManager.CallEvent('TFileDialog.Selected', @fFileName, nil);
      end;
    end
  else if Sender = Abort then
    EventManager.CallEvent('TFileDialog.Aborted', @fFileName, nil);
end;

procedure TFileDialog.SelectFile(Sender: TGUIComponent);
begin
  fFileName := fFileList.Strings[Sender.Tag];
  if fRO then
    Name.Caption := 'Selected file: ' + fFileName
  else
    SaveName.Text := ExtractFileName(fFileName);
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
        Preview.Tag := i;
        Preview.FreeTextureOnDestroy := true;

        ModuleManager.ModOCFManager.RequestOCFFile(fFileList.Strings[i], 'TFileOpenDialog.LoadedOCFFile', @Preview.Tag);
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
  ModuleManager.ModGlContext.GetResolution(ResX, ResY);

  fRO := ReadOnly;

  InitialDirectory := GetFirstExistingFileName(InitialDirectory);
  if InitialDirectory = '' then
    InitialDirectory := ModuleManager.ModPathes.PersonalDataPath;

  fOKD := nil;
  fYND := nil;

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
  OpenSave.Top := 352;
  OpenSave.OnClick := @CallEvent;
  if ReadOnly then
    OpenSave.Icon := 'document-open.tga'
  else
    begin
    OpenSave.Icon := 'document-save.tga';
    SaveName := TEdit.Create(Window);
    SaveName.Left := 450;
    SaveName.Top := 368;
    SaveName.Height := 32;
    SaveName.Width := 150;
    end;

  Abort := TIconifiedButton.Create(Window);
  Abort.Left := 644;
  Abort.Width := 48;
  Abort.Height := 48;
  Abort.Top := 352;
  Abort.OnClick := @CallEvent;
  Abort.Icon := 'dialog-cancel.tga';

  EventManager.AddCallback('TFileOpenDialog.LoadedOCFFile', @OCFFileLoaded);
  EventManager.AddCallback('TOKDialog.OK', @FreeDialogs);
  EventManager.AddCallback('TYesNoDialog.Yes', @FreeDialogs);
  EventManager.AddCallback('TYesNoDialog.No', @FreeDialogs);

  fDirectory := InitialDirectory;
  fFileName := '';

  fFileList := TStringList.Create;
  fDirList := TStringList.Create;
  UpdateFileList(Window);
end;

destructor TFileDialog.Free;
begin
  EventManager.RemoveCallback(@OCFFileLoaded);
  EventManager.RemoveCallback(@FreeDialogs);
  fDirList.Free;
  fFileList.Free;
  bgLabel.Free;
end;

end.