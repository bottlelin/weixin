{ ******************************************************* }
{ }
{ ��˼΢ƽ̨ }
{ }
{ ��Ȩ���� (C) 2016 ʯ��ׯ��˼�����������޹�˾ }
{ }
{ ******************************************************* }
{ ����Ԫ�ṩ΢��ƽ̨�������� }
{ ע����һ��    /wxapi  ����������΢�Ž�����֤ }
{ ��΢����Ϣ���ա� }
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

  // get method - ΢����֤��������ַ����Ч��
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
        strs.Add('Jiuceng123'); // ��΢�ź�����
        strs.Add(timestamp);
        strs.Add(nonce);
        strs.Sort;
        tmpStr := strs[0] + strs[1] + strs[2];
        aStr := AnsiString(tmpStr);
        tmpStr := LowerCase(SHA1Print(SHA1StringA(aStr)));
        if tmpStr = signature then
          aReply.WriteString(echostr)
        else
          aReply.WriteString('������������ʾ˵�������ӵ�ַ����Ϊ΢�Žӿڵ�ַʹ�á�');
      finally
        strs.Free;
      end;
    end
    else
      aReply.WriteString('���ú�̨������������΢���˺���Ϣ��');

    // post method - �����û������˺ŷ�����Ϣʱ����
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
        raise Exception.Create('û��ȡ����Ѷ������ת��������΢����Ϣ��aRequest.Files.Count = ' +
          IntToStr(aRequest.Files.Count));
      end;
    end
    else
    begin
      aReply.WriteString('');
      raise Exception.Create('���ú�̨������������΢���˺���Ϣ��');
    end;
  end;
  aSession.Terminate;
end;

end.
