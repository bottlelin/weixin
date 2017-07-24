{ ******************************************************* }
{ }
{ 泛思微平台 }
{ }
{ 版权所有 (C) 2016 石家庄泛思电子商务有限公司 }
{ }
{ ******************************************************* }
{ 这个单元提供微信消息分析的能力，仅解码，不做 }
{ 业务处理。 }
{ ******************************************************* }

unit uWxMsgAnalyze;

interface

uses
  System.Classes, Xml.xmldom, Xml.XMLIntf, Xml.XMLDoc, Xml.adomxmldom,
  uWxMsgCrypt;

type
{$REGION '所有微信消息类型定义'}
  TWxMsgType = (wmt_known, // 未知消息
    wmt_text, // 文本消息
    wmt_image, // 图片消息
    wmt_voice, // 语音消息
    wmt_video, // 视频消息
    wmt_shortvideo, // 小视频消息
    wmt_location, // 位置消息
    wmt_link, // 链接消息
    wmt_event // 事件消息
    );
{$ENDREGION}
{$REGION '微信消息加密方式'}
  TWxMsgEncodeType = (wmet_raw, // 明文
    wmet_fix, // 混合
    wmet_encrypt // 密文
    );
{$ENDREGION}
{$REGION '所有微信消息类型对象定义'}

  /// <summary>
  /// 所有消息的基础类，不论是文本、视频、地理位置信息还是订阅、取消订阅
  /// </summary>
  TWxMsgBase = class abstract
  public
    ToUserName: string; // 开发者微信号
    FromUserName: string; // 发送方帐号（一个OpenID）
    CreateTime: TDateTime; // 消息创建时间
  end;

  /// <summary>
  /// 文本消息
  /// </summary>
  TWxTextMsg = class(TWxMsgBase)
  public
    Content: string; // 文本消息内容
    MsgId: Int64; // 消息id
  end;

  /// <summary>
  /// 图片消息
  /// </summary>
  TWxImageMsg = class(TWxMsgBase)
  public
    PicUrl: string; // 图片链接
    MediaId: string; // 图片消息媒体id，可以调用多媒体文件下载接口拉取数据。
    MsgId: Int64; // 消息id
  end;

  /// <summary>
  /// 语音消息
  /// </summary>
  TWxVoiceMsg = class(TWxMsgBase)
  public
    MediaId: string; // 语音消息媒体id，可以调用多媒体文件下载接口拉取数据。
    Format: string; // 语音格式，如amr，speex等
    MsgId: Int64; // 消息id
  end;

  /// <summary>
  /// 视频和小视频消息
  /// </summary>
  TWxMediaMsg = class(TWxMsgBase)
  public
    MediaId: string; // 视频消息媒体id，可以调用多媒体文件下载接口拉取数据。
    ThumbMediaId: string; // 视频消息缩略图的媒体id，可以调用多媒体文件下载接口拉取数据。
    MsgId: Int64; // 消息id
  end;

  /// <summary>
  /// 地理位置消息
  /// </summary>
  TWxLocationMsg = class(TWxMsgBase)
  public
    Location_X: Double; // 地理位置维度
    Location_Y: Double; // 地理位置经度
    Scale: Integer; // 地图缩放大小
    PosLabel: string; // 地理位置信息
    MsgId: Int64; // 消息id
  end;

  /// <summary>
  /// 链接消息
  /// </summary>
  TWxLinkMsg = class(TWxMsgBase)
  public
    Title: string; // 消息标题
    Description: string; // 消息描述
    Url: string; // 消息链接
    MsgId: Int64; // 消息id
  end;

{$REGION '当是“事件”消息类型时，具体的事件类型的定义'}

  /// <summary>
  /// 当上报事件消息时，具体的某一种事件订阅
  /// </summary>
  TWxEventType = (wet_known, // 未知事件
    wet_subscribe, // 订阅事件
    wet_unsubscribe, // 取消订阅事件
    wet_ScanQRCodeSubscribe, // 没关注时扫描情景二维码，同时完成订阅
    wet_Scan, // 已关注后扫描情景二维码
    wet_reportLocation,
    // 用户同意上报地理位置后，每次进入公众号会话时，都会在进入时上报地理位置，或在进入会话后每5秒上报一次地理位置
    wet_MenuClick, // 菜单点击事件
    wet_View // 点击菜单跳转链接时的事件
    );
{$ENDREGION}
{$REGION '当时“事件”消息类型时，具体的事件类型对象的定义'}

  /// <summary>
  /// 扫描情景二维码时上报的数据
  /// </summary>
  TWxEventScanQRCodeData = class
  public
    EventKey: string; // 事件KEY值，qrscene_为前缀，后面为二维码的参数值
    Ticket: string; // 二维码的ticket，可用来换取二维码图片
  end;

  /// <summary>
  /// 用户同意上报地理位置后的附加数据
  /// </summary>
  TWxEventLocationData = class
  public
    Latitude: Double; // 地理位置纬度
    Longitude: Double; // 地理位置经度
    Precision: Double; // 地理位置精度
  end;

  /// <summary>
  /// 点击菜单的附加数据或者点击菜单跳转链接时的附加数据
  /// </summary>
  TWxEventMenuData = class
  public
    EventKey: string;
  end;
{$ENDREGION}

  /// <summary>
  /// 事件消息
  /// </summary>
  TWxEventMsg = class(TWxMsgBase)
  private
    FEventType: TWxEventType;
    FEventData: TObject;
    procedure SetEventType(const Value: TWxEventType);
    procedure FreeEventData;
  public
    // 具体是哪种事件，例如subscribe(订阅)、unsubscribe(取消订阅)等等
    property EventType: TWxEventType read FEventType write SetEventType;
    // 根据EventType决定EventData类型，如果是wet_subscribe或者wet_unsubscribe那么EventData=nil。
    property EventData: TObject read FEventData;

    constructor Create;
    destructor Destroy; override;
  end;

{$ENDREGION}

  /// <summary>
  /// 微信消息解析类，从TComponent类型继承主要是因为TXMLDocumnet创建时必须以TComponent作为父类，否则会操作异常
  /// </summary>
  TWxMsgAnalyze = class(TComponent)
  private
    FWxMsgCrypt: TWxMsgCrypt;
    FXml: TXMLDocument;
  public
    mWxMsgType: TWxMsgType;
    mWxMsgData: TWxMsgBase;
    mWxToken: string;
    mWxAppID: string;
    mWxEncodingAESKey: string;
    mTimeStamp: string;
    mNonce: string;
    mMsgSignature: string;
    mWxMsgEncodeType: TWxMsgEncodeType;

    /// <summary>
    /// 解析传入的微信消息，解析成功后填充mWxMsgType、mWxMsgData字段
    /// 解析失败mWxMsgType=wmt_known，mWxMsgData=nil并抛出异常
    ///
    /// 需要注意的是：调用此函数前必须先调用InitParams方法初始化参数！
    ///
    /// </summary>
    /// <param name="inputXmlData">xml字节流</param>
    procedure DecodeXmlData(inputXmlData: TStream);

    /// <summary>
    /// 加密微信消息。当服务器使用加密格式传递消息时，回复的消息也需要进行加密。
    /// </summary>
    /// <param name="wxid">微信号数据库ID</param>
    /// <param name="sMsg">微信消息明文</param>
    /// <returns>加密后的微信消息</returns>
    function EncodeXmlData(const wxid: Integer; const sMsg: string): string;

    /// <summary>
    /// 解码之前先初始化解码相关字段内容
    /// </summary>
    /// <param name="sWxToken">微信号Token设置</param>
    /// <param name="sWxAppId">微信号AppId</param>
    /// <param name="sWxEncodingAESKey">微信号EncodingAESKey设置</param>
    /// <param name="sMsgSignature">随微信消息传递过来的验证字符串</param>
    /// <param name="sTimeStamp">随微信消息传递过来的TimeStamp</param>
    /// <param name="sNonce">随微信消息传递过来的Nonce</param>
    procedure InitParams(sWxToken, sWxAppId, sWxEncodingAESKey, sMsgSignature,
      sTimeStamp, sNonce: string);

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, uWxGlobal, System.DateUtils, CnSHA1;

{$REGION 'TWxEventMsg'}
{ TWxEventMsg }

constructor TWxEventMsg.Create;
begin
  FEventType := wet_known;
  FEventData := nil;
end;

destructor TWxEventMsg.Destroy;
begin
  FreeEventData;
  inherited;
end;

procedure TWxEventMsg.FreeEventData;
begin
  if FEventData <> nil then
  begin
    case FEventType of
      // 没关注时扫描情景二维码，同时完成订阅
      wet_ScanQRCodeSubscribe:
        begin
          FreeAndNil(TWxEventScanQRCodeData(FEventData));
        end;
      // 已关注后扫描情景二维码
      wet_Scan:
        begin

        end;
      // 用户同意上报地理位置后，每次进入公众号会话时，都会在进入时上报地理位置，或在进入会话后每5秒上报一次地理位置
      wet_reportLocation:
        begin

        end;
      // 菜单点击事件，仅点击非链接跳转
      wet_MenuClick:
        begin

        end;
      // 点击菜单跳转链接时的事件
      wet_View:
        begin

        end;
    end;
  end;
end;

procedure TWxEventMsg.SetEventType(const Value: TWxEventType);
begin
  if FEventType <> Value then
  begin
    if (FEventType <> wet_known) then
    begin
      // 先释放原来的对象
      FreeEventData;

      // 创建新对象
      FEventType := Value;
      case FEventType of
        // 没关注时扫描情景二维码，同时完成订阅
        wet_ScanQRCodeSubscribe:
          begin
            FEventData := TWxEventScanQRCodeData.Create;
          end;
        // 已关注后扫描情景二维码
        wet_Scan:
          begin

          end;
        // 用户同意上报地理位置后，每次进入公众号会话时，都会在进入时上报地理位置，或在进入会话后每5秒上报一次地理位置
        wet_reportLocation:
          begin

          end;
        // 菜单点击事件，仅点击非链接跳转
        wet_MenuClick:
          begin

          end;
        // 点击菜单跳转链接时的事件
        wet_View:
          begin

          end;
      end;
    end
    else
      FreeEventData;
  end;
end;

{$ENDREGION}
{ TWxMsgAnalyze }

constructor TWxMsgAnalyze.Create(AOwner: TComponent);
begin
  inherited;
  FWxMsgCrypt := TWxMsgCrypt.Create;
  FXml := TXMLDocument.Create(Self);
  FXml.DOMVendor := GetDOMVendor('ADOM XML v4');
end;

procedure TWxMsgAnalyze.DecodeXmlData(inputXmlData: TStream);
var
  aNode, tmpNode: IXMLNode;
  i64: Int64;
  sDecryptMsg, sXml: string;
  DecryptRtn: WXBizMsgCryptErrorCode;

{$REGION 'XmlNode操作'}
  function GetNodeValue(nodeName: string): string;
  var
    node: IXMLNode;
    nodeList: IXMLNodeList;
    i: Integer;
  begin
    Result := '';
    nodeList := FXml.DocumentElement.ChildNodes;
    for i := 0 to nodeList.Count - 1 do
    begin
      node := nodeList[i];
      if node.nodeName = nodeName then
      begin
        Result := node.NodeValue;
        Break;
      end;
    end;
  end;

  function GetNode(nodeName: string): IXMLNode;
  var
    node: IXMLNode;
    nodeList: IXMLNodeList;
    i: Integer;
  begin
    Result := nil;
    nodeList := FXml.DocumentElement.ChildNodes;
    for i := 0 to nodeList.Count - 1 do
    begin
      node := nodeList[i];
      if node.nodeName = nodeName then
      begin
        Result := node;
        Break;
      end;
    end;
  end;
{$ENDREGION}
{$REGION '解析微信消息公共字段'}
  procedure GlobalFieldAnalyze;
  begin
    aNode := GetNode('ToUserName');
    mWxMsgData.ToUserName := aNode.NodeValue;
    aNode := GetNode('FromUserName');
    mWxMsgData.FromUserName := aNode.NodeValue;
    aNode := GetNode('CreateTime');
    mWxMsgData.CreateTime := ConvertWxDtToDateTime(aNode.NodeValue);
  end;
{$ENDREGION}
{$REGION '消息解码'}
  procedure DecodeMsg;
  begin
    aNode := GetNode('MsgType');
    if (aNode <> nil) then
    begin
      // 文本消息
      if aNode.NodeValue = 'text' then
      begin
        mWxMsgData := TWxTextMsg.Create;
        GlobalFieldAnalyze;
        tmpNode := GetNode('Content');
        TWxTextMsg(mWxMsgData).Content := tmpNode.NodeValue;
        tmpNode := GetNode('MsgId');
        TWxTextMsg(mWxMsgData).MsgId := tmpNode.NodeValue;
        mWxMsgType := wmt_text;

        // 图片消息
      end
      else if aNode.NodeValue = 'image' then
      begin
        mWxMsgData := TWxImageMsg.Create;
        GlobalFieldAnalyze;
        with TWxImageMsg(mWxMsgData) do
        begin
          tmpNode := GetNode('PicUrl');
          PicUrl := tmpNode.NodeValue; // 图片链接
          tmpNode := GetNode('MediaId');
          MediaId := tmpNode.NodeValue; // 图片消息媒体id，可以调用多媒体文件下载接口拉取数据。
          tmpNode := GetNode('MsgId');
          MsgId := tmpNode.NodeValue; // 消息id，64位整型
        end;
        mWxMsgType := wmt_image;

        // 语音消息
      end
      else if aNode.NodeValue = 'voice' then
      begin
        mWxMsgData := TWxVoiceMsg.Create;
        GlobalFieldAnalyze;
        with TWxVoiceMsg(mWxMsgData) do
        begin
          tmpNode := GetNode('MediaId'); // 语音消息媒体id，可以调用多媒体文件下载接口拉取数据。
          MediaId := string(tmpNode.NodeValue);
          tmpNode := GetNode('Format'); // 语音格式，如amr，speex等
          Format := string(tmpNode.NodeValue);
          tmpNode := GetNode('MsgId');
          i64 := StrToInt64(string(tmpNode.NodeValue));
          MsgId := i64; // 消息id，64位整型
        end;
        mWxMsgType := wmt_voice;

        // 视频消息 或者 小视频消息
      end
      else if (aNode.NodeValue = 'video') or (aNode.NodeValue = 'shortvideo')
      then
      begin
        mWxMsgData := TWxMediaMsg.Create;
        GlobalFieldAnalyze;
        with TWxMediaMsg(mWxMsgData) do
        begin
          tmpNode := GetNode('MediaId'); // 视频消息媒体id，可以调用多媒体文件下载接口拉取数据。
          MediaId := string(tmpNode.NodeValue);
          tmpNode := GetNode('ThumbMediaId'); // 视频消息缩略图的媒体id，可以调用多媒体文件下载接口拉取数据。
          ThumbMediaId := string(tmpNode.NodeValue);
          tmpNode := GetNode('MsgId');
          i64 := StrToInt64(string(tmpNode.NodeValue));
          MsgId := i64; // 消息id，64位整型
        end;
        if (aNode.NodeValue = 'video') then
          mWxMsgType := wmt_video
        else
          mWxMsgType := wmt_shortvideo;

        // 位置消息
      end
      else if aNode.NodeValue = 'location' then
      begin
        mWxMsgData := TWxLocationMsg.Create;
        GlobalFieldAnalyze;
        with (TWxLocationMsg(mWxMsgData)) do
        begin
          tmpNode := GetNode('Location_X'); // 地理位置维度
          Location_X := StrToFloat(string(tmpNode.NodeValue));
          tmpNode := GetNode('Location_Y'); // 地理位置经度
          Location_Y := StrToFloat(string(tmpNode.NodeValue));
          tmpNode := GetNode('Scale'); // 地图缩放大小
          Scale := StrToInt(string(tmpNode.NodeValue));
          tmpNode := GetNode('Label'); // 地理位置信息
          PosLabel := string(tmpNode.NodeValue);
          tmpNode := GetNode('MsgId');
          i64 := StrToInt64(string(tmpNode.NodeValue));
          MsgId := i64; // 消息id，64位整型
        end;
        mWxMsgType := wmt_location;

        // 链接消息
      end
      else if aNode.NodeValue = 'link' then
      begin
        mWxMsgData := TWxLinkMsg.Create;
        GlobalFieldAnalyze;
        with TWxLinkMsg(mWxMsgData) do
        begin
          tmpNode := GetNode('Title'); // 消息标题
          Title := string(tmpNode.NodeValue);
          tmpNode := GetNode('Description'); // 消息描述
          Description := string(tmpNode.NodeValue);
          tmpNode := GetNode('Url'); // 消息链接
          Url := string(tmpNode.NodeValue);
          tmpNode := GetNode('MsgId');
          i64 := StrToInt64(string(tmpNode.NodeValue));
          MsgId := i64; // 消息id，64位整型
        end;
        mWxMsgType := wmt_link;

        // 事件消息
      end
      else if aNode.NodeValue = 'event' then
      begin
        mWxMsgData := TWxEventMsg.Create;
        GlobalFieldAnalyze;
        aNode := GetNode('Event');

        // 订阅事件（包含扫描订阅事件）
        if (aNode.NodeValue = 'subscribe') then
        begin
          tmpNode := GetNode('EventKey');
          if (tmpNode <> nil) then
          begin
            TWxEventMsg(mWxMsgData).SetEventType(wet_ScanQRCodeSubscribe);
            with TWxEventScanQRCodeData(TWxEventMsg(mWxMsgData).EventData) do
            begin
              EventKey := string(tmpNode.NodeValue);
              // 事件KEY值，qrscene_为前缀，后面为二维码的参数值
              tmpNode := GetNode('Ticket');
              Ticket := string(tmpNode.NodeValue); // 二维码的ticket，可用来换取二维码图片
            end;
          end
          else
            TWxEventMsg(mWxMsgData).SetEventType(wet_subscribe)

            // 取消订阅事件
        end
        else if (aNode.NodeValue = 'unsubscribe') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_unsubscribe)

          // 已经订阅后触发扫码事件
        end
        else if (aNode.NodeValue = 'SCAN') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_Scan);
          with TWxEventScanQRCodeData(TWxEventMsg(mWxMsgData).EventData) do
          begin
            tmpNode := GetNode('EventKey');
            EventKey := string(tmpNode.NodeValue);
            // 事件KEY值，qrscene_为前缀，后面为二维码的参数值
            tmpNode := GetNode('Ticket');
            Ticket := string(tmpNode.NodeValue); // 二维码的ticket，可用来换取二维码图片
          end;

          // 上报位置信息事件
        end
        else if (aNode.NodeValue = 'LOCATION') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_reportLocation);
          with TWxEventLocationData(TWxEventMsg(mWxMsgData).EventData) do
          begin
            tmpNode := GetNode('Latitude');
            Latitude := StrToFloat(string(tmpNode.NodeValue)); // 地理位置纬度
            tmpNode := GetNode('Longitude');
            Longitude := StrToFloat(string(tmpNode.NodeValue)); // 地理位置经度
            tmpNode := GetNode('Precision');
            Precision := StrToFloat(string(tmpNode.NodeValue)); // 地理位置精度
          end;

          // 菜单点击事件
        end
        else if (aNode.NodeValue = 'CLICK') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_MenuClick);
          tmpNode := GetNode('EventKey');
          TWxEventMenuData(TWxEventMsg(mWxMsgData).EventData).EventKey :=
            string(tmpNode.NodeValue);

          // 菜单跳转链接事件
        end
        else if (aNode.NodeValue = 'VIEW') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_View);
          tmpNode := GetNode('EventKey');
          TWxEventMenuData(TWxEventMsg(mWxMsgData).EventData).EventKey :=
            string(tmpNode.NodeValue);

          // 未知事件
        end
        else
          raise Exception.Create('未知事件：' + string(aNode.NodeValue));

        mWxMsgType := wmt_event;
      end;
    end
    else
    begin
      FXml.SaveToXML(sXml);
      raise Exception.Create('无效的微信消息：' + sXml);
    end;
  end;
{$ENDREGION}

begin
  if mWxMsgData <> nil then
    FreeAndNil(mWxMsgData);

  mWxMsgType := wmt_known;

  FXml.LoadFromStream(inputXmlData);
  if (FXml.DocumentElement.nodeName = 'xml') then
  begin
    // 判断传递过来的消息是否加密了
    aNode := GetNode('Encrypt');
    if (aNode <> nil) then
    begin
      // 工作在明文加密混合模式下
      tmpNode := GetNode('MsgType');
      if (tmpNode <> nil) then
      begin
        mWxMsgEncodeType := wmet_fix;

        DecodeMsg;

        // 纯密文模式
      end
      else
      begin
        mWxMsgEncodeType := wmet_encrypt;
        DecryptRtn := FWxMsgCrypt.DecryptMsg(mWxToken, mTimeStamp, mNonce,
          string(aNode.NodeValue), mMsgSignature, mWxAppID, mWxEncodingAESKey,
          sDecryptMsg);
        if (DecryptRtn <> WXBizMsgCrypt_OK) then
          raise Exception.Create('微信消息解密失败！错误代码：' +
            IntToStr(Integer(DecryptRtn)));
        FXml.LoadFromXML(sDecryptMsg);
        if (FXml.DocumentElement.nodeName = 'xml') then
          DecodeMsg
        else
          raise Exception.Create('微信消息解码后的格式不正确：' + sDecryptMsg);
      end;

      // 明文模式
    end
    else
    begin
      mWxMsgEncodeType := wmet_raw;
      DecodeMsg;
    end;

  end
  else
  begin
    FXml.SaveToXML(sXml);
    raise Exception.Create('无效的微信消息：' + sXml);
  end;

  if mWxMsgType = wmt_known then
  begin
    FXml.SaveToXML(sXml);
    raise Exception.Create('无法解析微信消息类型：' + sXml);
  end;
end;

destructor TWxMsgAnalyze.Destroy;
begin
  FWxMsgCrypt.Free;
  if mWxMsgData <> nil then
    FreeAndNil(mWxMsgData);
  inherited;
end;

function TWxMsgAnalyze.EncodeXmlData(const wxid: Integer;
  const sMsg: string): string;
var
  sMsgEncrypt: string;
  ret: WXBizMsgCryptErrorCode;
begin
  sMsgEncrypt := '';
  ret := FWxMsgCrypt.EncryptMsg(sMsg, mWxToken, mWxAppID, mWxEncodingAESKey,
    sMsgEncrypt);
  if (ret <> WXBizMsgCrypt_OK) then
    raise Exception.Create('加密微信消息失败！错误代码：' + IntToStr(Integer(ret)))
  else
    Result := sMsgEncrypt;
end;

procedure TWxMsgAnalyze.InitParams(sWxToken, sWxAppId, sWxEncodingAESKey,
  sMsgSignature, sTimeStamp, sNonce: string);
begin
  mWxToken := sWxToken;
  mWxAppID := sWxAppId;
  mWxEncodingAESKey := sWxEncodingAESKey;
  mMsgSignature := sMsgSignature;
  mTimeStamp := sTimeStamp;
  mNonce := sNonce;
end;

end.
