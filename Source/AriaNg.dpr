{ *********************************************************************** }
{                                                                         }
{   AriaNg Edge �Զ����������Ŀ��Ԫ                                      }
{                                                                         }
{   ��ƣ�Lsuper 2017.09.11                                               }
{   ��ע��                                                                }
{   ��ˣ�                                                                }
{                                                                         }
{   Copyright (c) 1998-2023 Super Studio                                  }
{                                                                         }
{ *********************************************************************** }

program AriaNg;

{$IF CompilerVersion >= 21.0}
  {$WEAKLINKRTTI ON}
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

uses
{
  FastMM4,
}
  System.SysUtils,
  Winapi.Windows,
  Vcl.Forms,

  JsonDataObjects in '..\Common\JsonDataObjects.pas',
  Win11Forms in '..\Common\Win11Forms.pas',

  Aria2ControlFrm in 'Aria2ControlFrm.pas' {Aria2ControlForm};

{$R *.res}

{$SETPEFLAGS IMAGE_FILE_LARGE_ADDRESS_AWARE or IMAGE_FILE_RELOCS_STRIPPED}
{$SETPEOPTFLAGS $140}

begin
  Application.Title := 'AriaNg';
  Application.Initialize;
  Application.CreateForm(TAria2ControlForm, Aria2ControlForm);
  Application.Run;
end.
