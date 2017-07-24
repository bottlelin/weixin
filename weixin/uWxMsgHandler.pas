{ ******************************************************* }
{ }
{ 泛思微平台 }
{ }
{ 版权所有 (C) 2016 石家庄泛思电子商务有限公司 }
{ }
{ ******************************************************* }
{ 这个单元提供微信消息分析后的业务处理， }
{ 例如自动消息回复，用户关注写库， }
{ 用户取消关注释放资源等等。 }
{ 这个单元将使用PaxCompiler提供脚本运行能力 }
{ 在不重新编译程序的情况下使用脚本改变本单元 }
{ 微信消息的默认处理方式。 }
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
  /// 微信消息处理类
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
    /// 解析传入的微信消息，解析成功后填充WxMsgType、WxMsgData和Response字段
    /// 解析失败WxMsgType=wmt_known，WxMsgData=nil，Response=''并抛出异常
    /// </summary>
    procedure DecodeXmlData(inputXmlData: TStream);

    /// <summary>
    /// 生成一个默认的文本回复消息，仅用于微信文本消息接口响应测试！
    /// 这个函数将生成一个传入文本消息的回显消息
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
    // 文本消息
    wmt_text:
      begin
        GenDefaultTextEchoMsgAnswer;
      end;
    // 图片消息
    wmt_image:
      begin

      end;
    // 语音消息
    wmt_voice:
      begin

      end;
    // 视频消息
    wmt_video:
      begin

      end;
    // 小视频消息
    wmt_shortvideo:
      begin

      end;
    // 位置消息
    wmt_location:
      begin

      end;
    // 链接消息
    wmt_link:
      begin

      end;
    // 事件消息
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
