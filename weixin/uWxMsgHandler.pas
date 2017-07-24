{ ******************************************************* }
{ }
{ ��˼΢ƽ̨ }
{ }
{ ��Ȩ���� (C) 2016 ʯ��ׯ��˼�����������޹�˾ }
{ }
{ ******************************************************* }
{ �����Ԫ�ṩ΢����Ϣ�������ҵ���� }
{ �����Զ���Ϣ�ظ����û���עд�⣬ }
{ �û�ȡ����ע�ͷ���Դ�ȵȡ� }
{ �����Ԫ��ʹ��PaxCompiler�ṩ�ű��������� }
{ �ڲ����±������������ʹ�ýű��ı䱾��Ԫ }
{ ΢����Ϣ��Ĭ�ϴ���ʽ�� }
{ ******************************************************* }

unit uWxMsgHandler;

interface

uses
  System.Classes, uWxMsgAnalyze;

const
  DefaultTxtMsgAnswer = '<xml>' + '<ToUserName><![CDATA[%s]]></ToUserName>' +
    '<FromUserName><![CDATA[%s]]></FromUserName>' +
    '<CreateTime>%s</CreateTime>' + '<MsgType><![CDATA[text]]></MsgType>' +
    '<Content><![CDATA[%s]]></Content>' + '</xml>';
  subscribe_str_def = 'subscribe';
  unsubscribe_str_def = 'unsubscribe';

type
  /// <summary>
  /// ΢����Ϣ������
  /// </summary>
  TWxMsgHandler = class
  private
    FWxMsgAna: TWxMsgAnalyze;
    FResponse: string;
    FWxId: Integer;
    FTimeStamp: string;
    FNonce: string;
    FMsgSignature: string;
    Fmt: string;
    function GetResponse: string;
    function GetWxMsgData: TWxMsgBase;
    function GetWxMsgType: TWxMsgType;
    procedure Setmt(const Value: string);
  public
    property WxMsgType: TWxMsgType read GetWxMsgType;
    property WxMsgData: TWxMsgBase read GetWxMsgData;
    property Response: string read GetResponse;
    property WxId: Integer read FWxId write FWxId;
    property TimeStamp: string read FTimeStamp write FTimeStamp;
    property Nonce: string read FNonce write FNonce;
    property MsgSignature: string read FMsgSignature write FMsgSignature;
    property mt: string read Fmt write Setmt;

    /// <summary>
    /// ���������΢����Ϣ�������ɹ������WxMsgType��WxMsgData��Response�ֶ�
    /// ����ʧ��WxMsgType=wmt_known��WxMsgData=nil��Response=''���׳��쳣
    /// </summary>
    procedure DecodeXmlData(inputXmlData: TStream);

    /// <summary>
    /// ����һ��Ĭ�ϵ��ı��ظ���Ϣ��������΢���ı���Ϣ�ӿ���Ӧ���ԣ�
    /// �������������һ�������ı���Ϣ�Ļ�����Ϣ
    /// </summary>
    procedure GenDefaultTextEchoMsgAnswer;

    procedure InitParams(iWxId: Integer; sMsgSignature, sTimeStamp,
      sNonce: string);

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, uWxGlobal, System.DateUtils,
  ServerController;

{ TWxMsgHandler }

constructor TWxMsgHandler.Create;
begin
  FWxMsgAna := TWxMsgAnalyze.Create(nil);
end;

procedure TWxMsgHandler.DecodeXmlData(inputXmlData: TStream);
begin
  FResponse := '';
  FWxMsgAna.InitParams('Jiuceng123', 'wxb44f6515ac7b15ad',
    '89e67407961629abf58775bee2dfe6ff', FMsgSignature, FTimeStamp, FNonce);

  FWxMsgAna.DecodeXmlData(inputXmlData);
  case WxMsgType of
    // �ı���Ϣ
    wmt_text:
      begin
        GenDefaultTextEchoMsgAnswer;
      end;
    // ͼƬ��Ϣ
    wmt_image:
      begin

      end;
    // ������Ϣ
    wmt_voice:
      begin

      end;
    // ��Ƶ��Ϣ
    wmt_video:
      begin

      end;
    // С��Ƶ��Ϣ
    wmt_shortvideo:
      begin

      end;
    // λ����Ϣ
    wmt_location:
      begin

      end;
    // ������Ϣ
    wmt_link:
      begin

      end;
    // �¼���Ϣ
    wmt_event:
      begin

      end;
  end;
end;

destructor TWxMsgHandler.Destroy;
begin
  FWxMsgAna.Free;
  inherited;
end;

procedure TWxMsgHandler.GenDefaultTextEchoMsgAnswer;
var
  s: string;
  inputMsg: TWxTextMsg;
begin
  if WxMsgType = wmt_text then
  begin
    inputMsg := TWxTextMsg(WxMsgData);
    s := Format(DefaultTxtMsgAnswer, [inputMsg.FromUserName,
      inputMsg.ToUserName, GetWxNowStr, inputMsg.Content]);
    if FWxMsgAna.mWxMsgEncodeType = wmet_encrypt then
      s := FWxMsgAna.EncodeXmlData(FWxId, s);
    FResponse := s;
  end;
end;

function TWxMsgHandler.GetResponse: string;
begin
  Result := FResponse;
end;

function TWxMsgHandler.GetWxMsgData: TWxMsgBase;
begin
  Result := FWxMsgAna.mWxMsgData;
end;

function TWxMsgHandler.GetWxMsgType: TWxMsgType;
begin
  Result := FWxMsgAna.mWxMsgType;
end;

procedure TWxMsgHandler.InitParams(iWxId: Integer;
  sMsgSignature, sTimeStamp, sNonce: string);
begin
  FWxId := iWxId;
  FMsgSignature := sMsgSignature;
  FTimeStamp := sTimeStamp;
  FNonce := sNonce;
end;

procedure TWxMsgHandler.Setmt(const Value: string);
begin
  Fmt := Value;
end;

end.
