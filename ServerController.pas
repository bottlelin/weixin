unit ServerController;

interface

uses
  SysUtils, Classes, IWServerControllerBase, IWBaseForm, HTTPApp,
  // For OnNewSession Event
  UserSessionUnit, IWApplication, IWAppForm, DataModuleUnit, IWDataModulePool,
  IW.Browser.Browser;

type
  TIWServerController = class(TIWServerControllerBase)
    Pool: TIWDataModulePool;
    procedure IWServerControllerBaseNewSession(ASession: TIWApplication);
    procedure IWServerControllerBaseCreate(Sender: TObject);

    procedure PoolCreateDataModule(var ADataModule: TDataModule);
    procedure PoolFreeDataModule(var ADataModule: TDataModule);
    procedure IWServerControllerBaseBrowserCheck(ASession: TIWApplication;
      var rBrowser: TBrowser);
    procedure IWServerControllerBaseConfig(Sender: TObject);
  private

  public
  end;

function UserSession: TIWUserSession;
function IWServerController: TIWServerController;

function LockDataModule: TDataModule1;
procedure UnlockDataModule(ADataModule: TDataModule1);

implementation

{$R *.dfm}

uses
  IWInit, IWGlobal, IW.Content.Handlers,
  IW.Browser.Other, IW.Browser.InternetExplorer, IW.Parser.Files, uWxApi;

function UserSession: TIWUserSession;
begin
  Result := TIWUserSession(WebApplication.Data);
end;

function IWServerController: TIWServerController;
begin
  Result := TIWServerController(GServerController);
end;

procedure TIWServerController.IWServerControllerBaseNewSession
  (ASession: TIWApplication);
begin
  ASession.Data := TIWUserSession.Create(nil, ASession);
end;

procedure TIWServerController.IWServerControllerBaseBrowserCheck
  (ASession: TIWApplication; var rBrowser: TBrowser);
begin
  // 这个事件代码很重要，我在这里卡了好几天！
  //
  // 在没有实现这个事件的时候，在任何浏览器输入 /wxapi 都能成功响应，唯独到了
  // 微信中就显示配置失败，后来在代码中使用了日志输出才发现iw能收到微信请求，但是
  // TWxApi.Execute方法却没有执行，后来去官网阅读了相关帮助，才发现iw只有支持的浏
  // 览器才可正常响应输出，而微信发出的web请求显然不属于任何一个已知的浏览器
  if rBrowser is TOther then
  begin
    rBrowser.Free;
    rBrowser := TInternetExplorer.Create(8); // 以兼容IE8页面浏览进行页面内容输出
  end;
end;

procedure TIWServerController.IWServerControllerBaseConfig(Sender: TObject);
begin

  // IW.Parser.UTF8单元的RegisterContentType方法可以增加iw对其它content type类型的支持，例如text/xml、application/msword等等等等。
  RegisterContentType('text/xml');
  // 在ServerController.OnConfig事件中注册我们定义的微信Handler
  // ServerController.OnConfig事件在整个应用程序生命周期中只被运行一次

  with THandlers.Add('', 'wxapi', TWxApi.Create) do
  begin
  // 从字面上理解是能够启动会话
    CanStartSession := True;
   // 从字面上理解是需要启动会话，这两个属性必须进行设置，否则输入 /wxapi 将转向主窗体  。
    RequiresSessionStart := False;
  end;
  // 也就是不设置CanStartSession和RequiresSessionStart，则必须先执行/$/start 启动会话后才
  // 能正常访问 /wxapi页面，这个显然不是我们需要的end;
end;

procedure TIWServerController.IWServerControllerBaseCreate(Sender: TObject);
begin
  Pool.Active := True;

end;

procedure TIWServerController.PoolCreateDataModule(var ADataModule
  : TDataModule);
begin
  ADataModule := TDataModule1.Create(nil);
end;

procedure TIWServerController.PoolFreeDataModule(var ADataModule: TDataModule);
begin
  FreeAndNil(ADataModule);
end;

function LockDataModule: TDataModule1;
begin
  Result := TDataModule1(TIWServerController(GServerController).Pool.Lock);
end;

procedure UnlockDataModule(ADataModule: TDataModule1);
var
  LTemp: TDataModule;
begin
  LTemp := ADataModule;
  TIWServerController(GServerController).Pool.Unlock(LTemp);
end;

initialization

TIWServerController.SetServerControllerClass;

end.
