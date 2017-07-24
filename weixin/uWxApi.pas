{ ******************************************************* }
{ }
{ 泛思微平台 }
{ }
{ 版权所有 (C) 2016 石家庄泛思电子商务有限公司 }
{ }
{ ******************************************************* }
{ 本单元提供微信平台接入能力 }
{ 注册了一个    /wxapi  处理程序完成微信接入验证 }
{ 和微信消息接收。 }
{ ******************************************************* }

unit uWxApi;

interface

uses
  Classes, IW.Content.Base, System.SysUtils, HTTPApp, IWApplication,
  IW.HTTP.Request, IW.HTTP.Reply, IWMimeTypes;

type
  TWxApi = class(TContentBase)
  private

  protected
    function Execute(aRequest: THttpRequest; aReply: THttpReply;
      const aPathname: string; aSession: TIWApplication; aParams: TStrings)
      : Boolean; override;
  public
    constructor Create; override;
  end;

implementation

uses
  ServerController, UserSessionUnit, CnSHA1,
  IW.HTTP.FileItem, uWxMsgHandler, IW.Parser.Files;

{ TWxApi }

constructor TWxApi.Create;
begin
  inherited;
  FileMustExist := False;
end;

function TWxApi.Execute(aRequest: THttpRequest; aReply: THttpReply;
  const aPathname: string; aSession: TIWApplication; aParams: TStrings)
  : Boolean;
var
  signature: string;
  timestamp: string;
  nonce: string;
  echostr: string;
  strs: TStringList;
  tmpStr: string;
  sWxid: string;
  aStr: AnsiString;
  iWxid: Integer;

  xFile: THttpFile;
  fs: TFileStream;
  msgHandler: TWxMsgHandler;
begin
  Result := True;

  sWxid := aParams.Values['wid'];
  iWxid := StrToIntDef(sWxid, 0);

  // get method - 微信验证服务器地址的有效性
  if aRequest.HttpMethod = THttpMethod.hmGet then
  begin
    signature := aParams.Values['signature'];
    timestamp := aParams.Values['timestamp'];
    nonce := aParams.Values['nonce'];
    echostr := aParams.Values['echostr'];
    strs := TStringList.Create;
    if (iWxid > 0) then
    begin
      try
        strs.Add('Jiuceng123'); // 见微信号设置
        strs.Add(timestamp);
        strs.Add(nonce);
        strs.Sort;
        tmpStr := strs[0] + strs[1] + strs[2];
        aStr := AnsiString(tmpStr);
        tmpStr := LowerCase(SHA1Print(SHA1StringA(aStr)));
        if tmpStr = signature then
          aReply.WriteString(echostr)
        else
          aReply.WriteString('如果看到这个提示说明此链接地址可作为微信接口地址使用。');
      finally
        strs.Free;
      end;
    end
    else
      aReply.WriteString('请用后台管理程序先添加微信账号信息。');

    // post method - 当有用户向公众账号发送消息时触发
  end
  else
  begin
    if (iWxid > 0) then
    begin
      if aRequest.Files.Count = 1 then
      begin
        xFile := THttpFile(aRequest.Files[0]);
        fs := TFileStream.Create(xFile.TempPathName, fmOpenRead or
          fmShareDenyNone);
        msgHandler := TWxMsgHandler.Create;
        try
          msgHandler.InitParams(iWxid, aParams.Values['msg_signature'],
            aParams.Values['timestamp'], aParams.Values['nonce']);
          msgHandler.DecodeXmlData(fs);
          aReply.WriteString(msgHandler.Response);
        finally
          fs.Free;
          msgHandler.Free;
        end;
      end
      else
      begin
        aReply.WriteString('');
        raise Exception.Create('没能取得腾讯服务器转发过来的微信消息！aRequest.Files.Count = ' +
          IntToStr(aRequest.Files.Count));
      end;
    end
    else
    begin
      aReply.WriteString('');
      raise Exception.Create('请用后台管理程序先添加微信账号信息。');
    end;
  end;
  aSession.Terminate;
end;

end.
