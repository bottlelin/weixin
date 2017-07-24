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
  // ����¼��������Ҫ���������￨�˺ü��죡
  //
  // ��û��ʵ������¼���ʱ�����κ���������� /wxapi ���ܳɹ���Ӧ��Ψ������
  // ΢���о���ʾ����ʧ�ܣ������ڴ�����ʹ������־����ŷ���iw���յ�΢�����󣬵���
  // TWxApi.Execute����ȴû��ִ�У�����ȥ�����Ķ�����ذ������ŷ���iwֻ��֧�ֵ��
  // �����ſ�������Ӧ�������΢�ŷ�����web������Ȼ�������κ�һ����֪�������
  if rBrowser is TOther then
  begin
    rBrowser.Free;
    rBrowser := TInternetExplorer.Create(8); // �Լ���IE8ҳ���������ҳ���������
  end;
end;

procedure TIWServerController.IWServerControllerBaseConfig(Sender: TObject);
begin

  // IW.Parser.UTF8��Ԫ��RegisterContentType������������iw������content type���͵�֧�֣�����text/xml��application/msword�ȵȵȵȡ�
  RegisterContentType('text/xml');
  // ��ServerController.OnConfig�¼���ע�����Ƕ����΢��Handler
  // ServerController.OnConfig�¼�������Ӧ�ó�������������ֻ������һ��

  with THandlers.Add('', 'wxapi', TWxApi.Create) do
  begin
  // ��������������ܹ������Ự
    CanStartSession := True;
   // ���������������Ҫ�����Ự�����������Ա���������ã��������� /wxapi ��ת��������  ��
    RequiresSessionStart := False;
  end;
  // Ҳ���ǲ�����CanStartSession��RequiresSessionStart���������ִ��/$/start �����Ự���
  // ���������� /wxapiҳ�棬�����Ȼ����������Ҫ��end;
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
