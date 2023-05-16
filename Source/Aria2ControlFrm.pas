{ *********************************************************************** }
{                                                                         }
{   AriaNg Edge 自动化浏览器项目单元                                      }
{                                                                         }
{   设计：Lsuper 2017.09.11                                               }
{   备注：                                                                }
{   审核：                                                                }
{                                                                         }
{   Copyright (c) 1998-2023 Super Studio                                  }
{                                                                         }
{ *********************************************************************** }

unit Aria2ControlFrm;

interface

uses
  System.SysUtils, Winapi.Messages, Vcl.Forms, Vcl.ExtCtrls, uWVTypeLibrary, uWVTypes,
  uWVBrowser, uWVWindowParent, uWVCoreWebView2Args, Win11Forms;

type
  TAria2ControlForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FLastTheme: string;
    FWebBrowser: TWVBrowser;
    FWebInitTimer: TTimer;
    FWebWindow: TWVWindowParent;
  private
    function  CompareVersion(const AVer1, AVer2: string): Integer;
    function  CheckAriaNgFileBuild(const AFile: string): Boolean;
    function  DarkModeIsEnabled: Boolean;
    function  GetShellFolderPath(nFolder: Integer): string;
    function  LoadDataFromFile(const AFileName: string; AEncoding: TEncoding;
      ABufferSize: Integer): string;
    procedure ExtractAriaNgFile(const AFile: string);
    procedure ParseOptionEvent(const AEvent: string);
    procedure SetTitleThemeMode(const ATheme: string);
  private
    procedure WebBrowserAfterCreated(Sender: TObject);
    procedure WebBrowserDocumentTitleChanged(Sender: TObject);
    procedure WebBrowserExecuteScriptCompleted(Sender: TObject; aErrorCode: HRESULT;
      const aResultObjectAsJson: wvstring; aExecutionID: integer);
    procedure WebBrowserInitializationError(Sender: TObject; aErrorCode: HRESULT;
      const aErrorMessage: wvstring);
    procedure WebBrowserInitTimer(Sender: TObject);
    procedure WebBrowserNavigationCompleted(Sender: TObject; const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2NavigationCompletedEventArgs);
    procedure WebBrowserMessageReceived(Sender: TObject; const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2WebMessageReceivedEventArgs);
  protected
    procedure WMMove(var aMessage : TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage : TMessage); message WM_MOVING;
    procedure WMSettingChange(var Message: TMessage); message WM_SETTINGCHANGE;
  end;

var
  Aria2ControlForm: TAria2ControlForm;

implementation

{$R *.dfm}
{$R *.res} { index.html }

uses
  System.Classes, System.StrUtils, System.Win.Registry, Winapi.ShlObj, Winapi.Windows,
  Vcl.Controls, JsonDataObjects, uWVConstants, uWVLoader;

const
  defAriaNgFileOpenTag  = 'buildVersion:"v';
  defAriaNgFileCloseTag = '"';
  defAriaNgFileBuild    = '1.3.5';

  defAriaNgDarkMode     = 'dark';
  defAriaNgLightMode    = 'light';
  defAriaNgSystemMode   = 'system';

  defEdgeAria2FileName  = 'App\index.html';
  defEdgeUserDataName   = 'AriaNgEdge';

{ TAria2ControlForm }

function TAria2ControlForm.CheckAriaNgFileBuild(const AFile: string): Boolean;
var
  P1, P2: Integer;
  S: string;
begin
  Result := False;
  S := LoadDataFromFile(AFile, TEncoding.UTF8, 512 * 1024);
  P1 := Pos(defAriaNgFileOpenTag, S);
  if P1 = 0 then
    Exit;
  Inc(P1, Length(defAriaNgFileOpenTag));
  P2 := PosEx(defAriaNgFileCloseTag, S, P1);
  if P2 = 0 then
    Exit;
  S := Copy(S, P1, P2 - P1);
  Result := CompareVersion(S, defAriaNgFileBuild) >= 0;
end;

function TAria2ControlForm.CompareVersion(const AVer1, AVer2: string): Integer;
type
  TFileVerRec = array[0..3] of Integer;

  function DecodeVersion(const AVerStr: string): TFileVerRec;
  var
    C, I: Integer;
    L: TStrings;
    S: string;
  begin
    FillChar(Result, SizeOf(TFileVerRec), 0);
    if AVerStr = '' then
      Exit;
    L := TStringList.Create;
    with L do
    try
      Delimiter := '.';
      DelimitedText := AVerStr;
      if L.Count > 4 then
        C := 4
      else C := L.Count;
      for I := 0 to C - 1 do
      begin
        S := Trim(L.Strings[I]);
        Result[I] := StrToIntDef(S, 0);
      end;
    finally
      Free;
    end;
  end;
var
  I: Integer;
  R1, R2: TFileVerRec;
begin
  R1 := DecodeVersion(AVer1);
  R2 := DecodeVersion(AVer2);
  for I := Low(TFileVerRec) to High(TFileVerRec) do
  begin
    Result := R1[I] - R2[I];
    if Result <> 0 then
      Exit;
  end;
  Result := 0;
end;

function TAria2ControlForm.DarkModeIsEnabled: Boolean;
const
  defLightThemeValueName = 'AppsUseLightTheme';
  defPersonalizeKeyName  = 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\';
var
  Reg: TRegistry;
begin
  Result := False;
  Reg := TRegistry.Create(KEY_READ);
  with Reg do
  try
    RootKey := HKEY_CURRENT_USER;
    if OpenKey(defPersonalizeKeyName, False) then
    begin
      if ValueExists(defLightThemeValueName) then
        Result := ReadInteger(defLightThemeValueName) = 0;
      CloseKey;
    end;
  finally
    Free;
  end;
end;

procedure TAria2ControlForm.ExtractAriaNgFile(const AFile: string);
var
  F: string;
  S: TResourceStream;
begin
  F := ExtractFileDir(AFile);
  if not DirectoryExists(F) then
    ForceDirectories(F);
  if not DirectoryExists(F) then
    Exit;
  S := TResourceStream.Create(HInstance, 'INDEX', RT_RCDATA);
  with TFileStream.Create(AFile, fmCreate) do
  try
    CopyFrom(S, S.Size);
  finally
    Free;
    S.Free;
  end;
end;

procedure TAria2ControlForm.FormCreate(Sender: TObject);
var
  B, F: string;
begin
  B := GetShellFolderPath(CSIDL_LOCAL_APPDATA) + defEdgeUserDataName;
  if not DirectoryExists(B) then
    ForceDirectories(B);

  GlobalWebView2Loader := TWVLoader.Create(nil);
  GlobalWebView2Loader.UseInternalLoader := True;
  GlobalWebView2Loader.UserDataFolder := B;
  GlobalWebView2Loader.StartWebView2;

  FWebWindow := TWVWindowParent.Create(Self);
  FWebWindow.Parent := Self;
  FWebWindow.Align := alClient;

  FWebBrowser := TWVBrowser.Create(Self);
  FWebWindow.Browser := FWebBrowser;
  FWebBrowser.OnAfterCreated := WebBrowserAfterCreated;
  FWebBrowser.OnDocumentTitleChanged := WebBrowserDocumentTitleChanged;
  FWebBrowser.OnExecuteScriptCompleted := WebBrowserExecuteScriptCompleted;
  FWebBrowser.OnInitializationError := WebBrowserInitializationError;
  FWebBrowser.OnNavigationCompleted := WebBrowserNavigationCompleted;
  FWebBrowser.OnWebMessageReceived := WebBrowserMessageReceived;

  F := Format('%s\%s', [B, defEdgeAria2FileName]);
  if not FileExists(F) or not CheckAriaNgFileBuild(F) then
    ExtractAriaNgFile(F);
  FWebBrowser.DefaultURL := F;

  FWebInitTimer := TTimer.Create(Self);
  with FWebInitTimer do
  begin
    Enabled := False;
    Interval := 300;
    OnTimer := WebBrowserInitTimer;
  end;

  Self.RoundedCorners := rcOff;
end;

procedure TAria2ControlForm.FormDestroy(Sender: TObject);
begin
  ;
end;

procedure TAria2ControlForm.FormShow(Sender: TObject);
begin
  if GlobalWebView2Loader.InitializationError then
  begin
    Application.MessageBox(PChar(GlobalWebView2Loader.ErrorMessage), '', MB_ICONERROR or MB_OK);
    Application.Terminate;
    Exit;
  end;
  if GlobalWebView2Loader.Initialized then
    FWebBrowser.CreateBrowser(FWebWindow.Handle)
  else FWebInitTimer.Enabled := True;
end;

function TAria2ControlForm.GetShellFolderPath(nFolder: Integer): string;
begin
  SetLength(Result, MAX_PATH);
  SHGetSpecialFolderPath(0, PChar(Result), nFolder, False);
  SetLength(Result, StrLen(PChar(Result)));
  if (Result <> '') and (Result[Length(Result)] <> '\') then
    Result := Result + '\';
end;

function TAria2ControlForm.LoadDataFromFile(const AFileName: string; AEncoding: TEncoding;
  ABufferSize: Integer): string;
var
  FS: TStream;
  SR: TTextReader;
begin
  Result := '';
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SR := TStreamReader.Create(FS, AEncoding, False, ABufferSize);
    with SR do
    try
      Result := ReadToEnd;
    finally
      Free;
    end;
  finally
    FS.Free;
  end;
end;

procedure TAria2ControlForm.ParseOptionEvent(const AEvent: string);
var
  R: TJsonBaseObject;
  S: string;
begin
  R := TJsonObject.Parse(AEvent);
  try
    if not (R is TJsonObject) then
      Exit;
    S := TJsonObject(R).S['key'];
    if S <> 'AriaNg.Options' then
      Exit;
    S := TJsonObject(R).S['value'];
  finally
    R.Free;
  end;
  R := TJsonObject.Parse(S);
  try
    if not (R is TJsonObject) then
      Exit;
    S := TJsonObject(R).S['theme'];
  finally
    R.Free;
  end;
  if S <> FLastTheme then
  begin
    FLastTheme := S;
    SetTitleThemeMode(FLastTheme);
  end;
end;

procedure TAria2ControlForm.SetTitleThemeMode(const ATheme: string);
var
  S: string;
begin
  S := ATheme;
  if S = defAriaNgSystemMode then
  begin
    if DarkModeIsEnabled then
      S := defAriaNgDarkMode
    else S := defAriaNgLightMode;
  end;
  Self.TitleDarkMode := S = defAriaNgDarkMode;
end;

procedure TAria2ControlForm.WebBrowserAfterCreated(Sender: TObject);
begin
{$IFDEF DEBUGMESSAGE}
  OutputDebugString(('WebBrowserAfterCreated');
{$ENDIF}
  FWebWindow.UpdateSize;
end;

procedure TAria2ControlForm.WebBrowserDocumentTitleChanged(Sender: TObject);
begin
{$IFDEF DEBUGMESSAGE}
  OutputDebugString(('WebBrowserDocumentTitleChanged');
{$ENDIF}
  Caption := FWebBrowser.DocumentTitle;
end;

procedure TAria2ControlForm.WebBrowserExecuteScriptCompleted(Sender: TObject; aErrorCode: HRESULT;
  const aResultObjectAsJson: wvstring; aExecutionID: integer);
begin
{$IFDEF DEBUGMESSAGE}
  OutputDebugString(PChar('WebBrowserExecuteScriptCompleted: ' + IntToStr(aErrorCode)));
{$ENDIF}
end;

procedure TAria2ControlForm.WebBrowserInitializationError(Sender: TObject; aErrorCode: HRESULT;
  const aErrorMessage: wvstring);
begin
{$IFDEF DEBUGMESSAGE}
  OutputDebugString(PChar('WebBrowserInitializationError: ' + IntToStr(aErrorCode)));
{$ENDIF}
  Application.MessageBox(PChar(aErrorMessage), '', MB_ICONERROR or MB_OK);
end;

procedure TAria2ControlForm.WebBrowserInitTimer(Sender: TObject);
begin
{$IFDEF DEBUGMESSAGE}
  OutputDebugString('WebBrowserInitTimer');
{$ENDIF}
  FWebInitTimer.Enabled := False;
  if GlobalWebView2Loader.Initialized then
    FWebBrowser.CreateBrowser(FWebWindow.Handle)
  else FWebInitTimer.Enabled := True;
end;

procedure TAria2ControlForm.WebBrowserMessageReceived(Sender: TObject; const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2WebMessageReceivedEventArgs);
var
  R: TCoreWebView2WebMessageReceivedEventArgs;
begin
{$IFDEF DEBUGMESSAGE}
  OutputDebugString(('WebBrowserMessageReceived');
{$ENDIF}
  R := TCoreWebView2WebMessageReceivedEventArgs.Create(aArgs);
  try
    ParseOptionEvent(R.WebMessageAsString);
  finally
    R.Free;
  end;
end;

procedure TAria2ControlForm.WebBrowserNavigationCompleted(Sender: TObject; const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2NavigationCompletedEventArgs);
var
  R: TCoreWebView2NavigationCompletedEventArgs;
  S: string;
begin
{$IFDEF DEBUGMESSAGE}
  OutputDebugString(('WebBrowserNavigationCompleted');
{$ENDIF}
  R := TCoreWebView2NavigationCompletedEventArgs.Create(aArgs);
  try
    if R.HttpStatusCode <> 0 then
      Exit;
  finally
    R.Free;
  end;

  S := 'var ge = new Event("setItemEvent");' +
    'ge.key = "AriaNg.Options";' +
    'ge.value = localStorage.getItem("AriaNg.Options");' +
    'window.chrome.webview.postMessage(JSON.stringify(ge));';
  FWebBrowser.ExecuteScript(S);

  S := 'var orignalSetItem = localStorage.setItem;' +
    'localStorage.setItem = function(key,newValue) {' +
    'var se = new Event("setItemEvent");' +
    'se.key = key;' +
    'se.value = newValue;' +
    'window.chrome.webview.postMessage(JSON.stringify(se));' +
    'orignalSetItem.apply(this,arguments);' +
  '};';
  FWebBrowser.ExecuteScript(S);
end;

procedure TAria2ControlForm.WMMove(var aMessage: TWMMove);
begin
  inherited;
  if Assigned(FWebBrowser) then FWebBrowser.NotifyParentWindowPositionChanged;
end;

procedure TAria2ControlForm.WMMoving(var aMessage: TMessage);
begin
  inherited;
  if Assigned(FWebBrowser) then FWebBrowser.NotifyParentWindowPositionChanged;
end;

procedure TAria2ControlForm.WMSettingChange(var Message: TMessage);
begin
{$IFDEF DEBUGMESSAGE}
  OutputDebugString(('WMSettingChange');
{$ENDIF}
  inherited;
  SetTitleThemeMode(FLastTheme);
end;

end.
