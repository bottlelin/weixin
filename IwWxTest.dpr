program IwWxTest;

uses
  IWRtlFix,
  IWJclStackTrace,
  IWJclDebug,
  Forms,
  IWStart,
  UTF8ContentParser,
  Unit1 in 'Unit1.pas' {IWForm1: TIWAppForm} ,
  ServerController
    in 'ServerController.pas' {IWServerController: TIWServerControllerBase} ,
  UserSessionUnit in 'UserSessionUnit.pas' {IWUserSession: TIWUserSessionBase} ,
  DatamoduleUnit in 'DatamoduleUnit.pas' {DataModule1: TDataModule} ,
  uWxApi in 'weixin\uWxApi.pas',
  uWxGlobal in 'weixin\uWxGlobal.pas',
  uWxMsgAnalyze in 'weixin\uWxMsgAnalyze.pas',
  uWxMsgCrypt in 'weixin\uWxMsgCrypt.pas',
  uWxMsgHandler in 'weixin\uWxMsgHandler.pas';

{$R *.res}

begin
  TIWStart.Execute(True);

end.
