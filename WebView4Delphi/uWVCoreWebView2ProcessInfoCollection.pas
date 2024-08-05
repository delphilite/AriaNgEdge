unit uWVCoreWebView2ProcessInfoCollection;

{$IFDEF FPC}{$MODE Delphi}{$ENDIF}

{$I webview2.inc}

interface

uses
  uWVTypeLibrary;

type
  /// <summary>
  /// A list containing process id and corresponding process type.
  /// </summary>
  /// <remarks>
  /// <para><see href="https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2processinfocollection">See the ICoreWebView2ProcessInfoCollection article.</see></para>
  /// </remarks>
  TCoreWebView2ProcessInfoCollection = class
    protected
      FBaseIntf : ICoreWebView2ProcessInfoCollection;

      function GetInitialized : boolean;
      function GetCount : cardinal;
      function GetValueAtIndex(index : cardinal) : ICoreWebView2ProcessInfo;

    public
      constructor Create(const aBaseIntf : ICoreWebView2ProcessInfoCollection); reintroduce;
      destructor  Destroy; override;

      /// <summary>
      /// Returns true when the interface implemented by this class is fully initialized.
      /// </summary>
      property Initialized           : boolean                                      read GetInitialized;
      /// <summary>
      /// Returns the interface implemented by this class.
      /// </summary>
      property BaseIntf              : ICoreWebView2ProcessInfoCollection           read FBaseIntf;
      /// <summary>
      /// The number of process contained in the ICoreWebView2ProcessInfoCollection.
      /// </summary>
      /// <remarks>
      /// <para><see href="https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2processinfocollection#get_count">See the ICoreWebView2ProcessInfoCollection article.</see></para>
      /// </remarks>
      property Count                 : cardinal                                     read GetCount;
      /// <summary>
      /// Gets the `ICoreWebView2ProcessInfo` located in the `ICoreWebView2ProcessInfoCollection`
      /// at the given index.
      /// </summary>
      /// <remarks>
      /// <para><see href="https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2processinfocollection#getvalueatindex">See the ICoreWebView2ProcessInfoCollection article.</see></para>
      /// </remarks>
      property Items[idx : cardinal] : ICoreWebView2ProcessInfo                     read GetValueAtIndex;
  end;

implementation

uses
  {$IFDEF DELPHI16_UP}
  Winapi.ActiveX;
  {$ELSE}
  ActiveX;
  {$ENDIF}

constructor TCoreWebView2ProcessInfoCollection.Create(const aBaseIntf: ICoreWebView2ProcessInfoCollection);
begin
  inherited Create;

  FBaseIntf := aBaseIntf;
end;

destructor TCoreWebView2ProcessInfoCollection.Destroy;
begin
  FBaseIntf := nil;

  inherited Destroy;
end;

function TCoreWebView2ProcessInfoCollection.GetInitialized : boolean;
begin
  Result := assigned(FBaseIntf);
end;

function TCoreWebView2ProcessInfoCollection.GetCount : cardinal;
var
  TempResult : SYSUINT;
begin
  Result     := 0;
  TempResult := 0;

  if Initialized and
     succeeded(FBaseIntf.Get_Count(TempResult)) then
    Result := TempResult;
end;

function TCoreWebView2ProcessInfoCollection.GetValueAtIndex(index : cardinal) : ICoreWebView2ProcessInfo;
var
  TempResult : ICoreWebView2ProcessInfo;
begin
  Result     := nil;
  TempResult := nil;

  if Initialized and
     succeeded(FBaseIntf.GetValueAtIndex(index, TempResult)) and
     assigned(TempResult) then
    Result := TempResult;
end;

end.
