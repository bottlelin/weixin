{ ******************************************************* }
{ }
{ ��˼΢ƽ̨ }
{ }
{ ��Ȩ���� (C) 2016 ʯ��ׯ��˼�����������޹�˾ }
{ }
{ ******************************************************* }
{ �����Ԫ�ṩ΢����Ϣ�����������������룬���� }
{ ҵ���� }
{ ******************************************************* }

unit uWxMsgAnalyze;

interface

uses
  System.Classes, Xml.xmldom, Xml.XMLIntf, Xml.XMLDoc, Xml.adomxmldom,
  uWxMsgCrypt;

type
{$REGION '����΢����Ϣ���Ͷ���'}
  TWxMsgType = (wmt_known, // δ֪��Ϣ
    wmt_text, // �ı���Ϣ
    wmt_image, // ͼƬ��Ϣ
    wmt_voice, // ������Ϣ
    wmt_video, // ��Ƶ��Ϣ
    wmt_shortvideo, // С��Ƶ��Ϣ
    wmt_location, // λ����Ϣ
    wmt_link, // ������Ϣ
    wmt_event // �¼���Ϣ
    );
{$ENDREGION}
{$REGION '΢����Ϣ���ܷ�ʽ'}
  TWxMsgEncodeType = (wmet_raw, // ����
    wmet_fix, // ���
    wmet_encrypt // ����
    );
{$ENDREGION}
{$REGION '����΢����Ϣ���Ͷ�����'}

  /// <summary>
  /// ������Ϣ�Ļ����࣬�������ı�����Ƶ������λ����Ϣ���Ƕ��ġ�ȡ������
  /// </summary>
  TWxMsgBase = class abstract
  public
    ToUserName: string; // ������΢�ź�
    FromUserName: string; // ���ͷ��ʺţ�һ��OpenID��
    CreateTime: TDateTime; // ��Ϣ����ʱ��
  end;

  /// <summary>
  /// �ı���Ϣ
  /// </summary>
  TWxTextMsg = class(TWxMsgBase)
  public
    Content: string; // �ı���Ϣ����
    MsgId: Int64; // ��Ϣid
  end;

  /// <summary>
  /// ͼƬ��Ϣ
  /// </summary>
  TWxImageMsg = class(TWxMsgBase)
  public
    PicUrl: string; // ͼƬ����
    MediaId: string; // ͼƬ��Ϣý��id�����Ե��ö�ý���ļ����ؽӿ���ȡ���ݡ�
    MsgId: Int64; // ��Ϣid
  end;

  /// <summary>
  /// ������Ϣ
  /// </summary>
  TWxVoiceMsg = class(TWxMsgBase)
  public
    MediaId: string; // ������Ϣý��id�����Ե��ö�ý���ļ����ؽӿ���ȡ���ݡ�
    Format: string; // ������ʽ����amr��speex��
    MsgId: Int64; // ��Ϣid
  end;

  /// <summary>
  /// ��Ƶ��С��Ƶ��Ϣ
  /// </summary>
  TWxMediaMsg = class(TWxMsgBase)
  public
    MediaId: string; // ��Ƶ��Ϣý��id�����Ե��ö�ý���ļ����ؽӿ���ȡ���ݡ�
    ThumbMediaId: string; // ��Ƶ��Ϣ����ͼ��ý��id�����Ե��ö�ý���ļ����ؽӿ���ȡ���ݡ�
    MsgId: Int64; // ��Ϣid
  end;

  /// <summary>
  /// ����λ����Ϣ
  /// </summary>
  TWxLocationMsg = class(TWxMsgBase)
  public
    Location_X: Double; // ����λ��ά��
    Location_Y: Double; // ����λ�þ���
    Scale: Integer; // ��ͼ���Ŵ�С
    PosLabel: string; // ����λ����Ϣ
    MsgId: Int64; // ��Ϣid
  end;

  /// <summary>
  /// ������Ϣ
  /// </summary>
  TWxLinkMsg = class(TWxMsgBase)
  public
    Title: string; // ��Ϣ����
    Description: string; // ��Ϣ����
    Url: string; // ��Ϣ����
    MsgId: Int64; // ��Ϣid
  end;

{$REGION '���ǡ��¼�����Ϣ����ʱ��������¼����͵Ķ���'}

  /// <summary>
  /// ���ϱ��¼���Ϣʱ�������ĳһ���¼�����
  /// </summary>
  TWxEventType = (wet_known, // δ֪�¼�
    wet_subscribe, // �����¼�
    wet_unsubscribe, // ȡ�������¼�
    wet_ScanQRCodeSubscribe, // û��עʱɨ���龰��ά�룬ͬʱ��ɶ���
    wet_Scan, // �ѹ�ע��ɨ���龰��ά��
    wet_reportLocation,
    // �û�ͬ���ϱ�����λ�ú�ÿ�ν��빫�ںŻỰʱ�������ڽ���ʱ�ϱ�����λ�ã����ڽ���Ự��ÿ5���ϱ�һ�ε���λ��
    wet_MenuClick, // �˵�����¼�
    wet_View // ����˵���ת����ʱ���¼�
    );
{$ENDREGION}
{$REGION '��ʱ���¼�����Ϣ����ʱ��������¼����Ͷ���Ķ���'}

  /// <summary>
  /// ɨ���龰��ά��ʱ�ϱ�������
  /// </summary>
  TWxEventScanQRCodeData = class
  public
    EventKey: string; // �¼�KEYֵ��qrscene_Ϊǰ׺������Ϊ��ά��Ĳ���ֵ
    Ticket: string; // ��ά���ticket����������ȡ��ά��ͼƬ
  end;

  /// <summary>
  /// �û�ͬ���ϱ�����λ�ú�ĸ�������
  /// </summary>
  TWxEventLocationData = class
  public
    Latitude: Double; // ����λ��γ��
    Longitude: Double; // ����λ�þ���
    Precision: Double; // ����λ�þ���
  end;

  /// <summary>
  /// ����˵��ĸ������ݻ��ߵ���˵���ת����ʱ�ĸ�������
  /// </summary>
  TWxEventMenuData = class
  public
    EventKey: string;
  end;
{$ENDREGION}

  /// <summary>
  /// �¼���Ϣ
  /// </summary>
  TWxEventMsg = class(TWxMsgBase)
  private
    FEventType: TWxEventType;
    FEventData: TObject;
    procedure SetEventType(const Value: TWxEventType);
    procedure FreeEventData;
  public
    // �����������¼�������subscribe(����)��unsubscribe(ȡ������)�ȵ�
    property EventType: TWxEventType read FEventType write SetEventType;
    // ����EventType����EventData���ͣ������wet_subscribe����wet_unsubscribe��ôEventData=nil��
    property EventData: TObject read FEventData;

    constructor Create;
    destructor Destroy; override;
  end;

{$ENDREGION}

  /// <summary>
  /// ΢����Ϣ�����࣬��TComponent���ͼ̳���Ҫ����ΪTXMLDocumnet����ʱ������TComponent��Ϊ���࣬���������쳣
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
    /// ���������΢����Ϣ�������ɹ������mWxMsgType��mWxMsgData�ֶ�
    /// ����ʧ��mWxMsgType=wmt_known��mWxMsgData=nil���׳��쳣
    ///
    /// ��Ҫע����ǣ����ô˺���ǰ�����ȵ���InitParams������ʼ��������
    ///
    /// </summary>
    /// <param name="inputXmlData">xml�ֽ���</param>
    procedure DecodeXmlData(inputXmlData: TStream);

    /// <summary>
    /// ����΢����Ϣ����������ʹ�ü��ܸ�ʽ������Ϣʱ���ظ�����ϢҲ��Ҫ���м��ܡ�
    /// </summary>
    /// <param name="wxid">΢�ź����ݿ�ID</param>
    /// <param name="sMsg">΢����Ϣ����</param>
    /// <returns>���ܺ��΢����Ϣ</returns>
    function EncodeXmlData(const wxid: Integer; const sMsg: string): string;

    /// <summary>
    /// ����֮ǰ�ȳ�ʼ����������ֶ�����
    /// </summary>
    /// <param name="sWxToken">΢�ź�Token����</param>
    /// <param name="sWxAppId">΢�ź�AppId</param>
    /// <param name="sWxEncodingAESKey">΢�ź�EncodingAESKey����</param>
    /// <param name="sMsgSignature">��΢����Ϣ���ݹ�������֤�ַ���</param>
    /// <param name="sTimeStamp">��΢����Ϣ���ݹ�����TimeStamp</param>
    /// <param name="sNonce">��΢����Ϣ���ݹ�����Nonce</param>
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
      // û��עʱɨ���龰��ά�룬ͬʱ��ɶ���
      wet_ScanQRCodeSubscribe:
        begin
          FreeAndNil(TWxEventScanQRCodeData(FEventData));
        end;
      // �ѹ�ע��ɨ���龰��ά��
      wet_Scan:
        begin

        end;
      // �û�ͬ���ϱ�����λ�ú�ÿ�ν��빫�ںŻỰʱ�������ڽ���ʱ�ϱ�����λ�ã����ڽ���Ự��ÿ5���ϱ�һ�ε���λ��
      wet_reportLocation:
        begin

        end;
      // �˵�����¼����������������ת
      wet_MenuClick:
        begin

        end;
      // ����˵���ת����ʱ���¼�
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
      // ���ͷ�ԭ���Ķ���
      FreeEventData;

      // �����¶���
      FEventType := Value;
      case FEventType of
        // û��עʱɨ���龰��ά�룬ͬʱ��ɶ���
        wet_ScanQRCodeSubscribe:
          begin
            FEventData := TWxEventScanQRCodeData.Create;
          end;
        // �ѹ�ע��ɨ���龰��ά��
        wet_Scan:
          begin

          end;
        // �û�ͬ���ϱ�����λ�ú�ÿ�ν��빫�ںŻỰʱ�������ڽ���ʱ�ϱ�����λ�ã����ڽ���Ự��ÿ5���ϱ�һ�ε���λ��
        wet_reportLocation:
          begin

          end;
        // �˵�����¼����������������ת
        wet_MenuClick:
          begin

          end;
        // ����˵���ת����ʱ���¼�
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

{$REGION 'XmlNode����'}
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
{$REGION '����΢����Ϣ�����ֶ�'}
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
{$REGION '��Ϣ����'}
  procedure DecodeMsg;
  begin
    aNode := GetNode('MsgType');
    if (aNode <> nil) then
    begin
      // �ı���Ϣ
      if aNode.NodeValue = 'text' then
      begin
        mWxMsgData := TWxTextMsg.Create;
        GlobalFieldAnalyze;
        tmpNode := GetNode('Content');
        TWxTextMsg(mWxMsgData).Content := tmpNode.NodeValue;
        tmpNode := GetNode('MsgId');
        TWxTextMsg(mWxMsgData).MsgId := tmpNode.NodeValue;
        mWxMsgType := wmt_text;

        // ͼƬ��Ϣ
      end
      else if aNode.NodeValue = 'image' then
      begin
        mWxMsgData := TWxImageMsg.Create;
        GlobalFieldAnalyze;
        with TWxImageMsg(mWxMsgData) do
        begin
          tmpNode := GetNode('PicUrl');
          PicUrl := tmpNode.NodeValue; // ͼƬ����
          tmpNode := GetNode('MediaId');
          MediaId := tmpNode.NodeValue; // ͼƬ��Ϣý��id�����Ե��ö�ý���ļ����ؽӿ���ȡ���ݡ�
          tmpNode := GetNode('MsgId');
          MsgId := tmpNode.NodeValue; // ��Ϣid��64λ����
        end;
        mWxMsgType := wmt_image;

        // ������Ϣ
      end
      else if aNode.NodeValue = 'voice' then
      begin
        mWxMsgData := TWxVoiceMsg.Create;
        GlobalFieldAnalyze;
        with TWxVoiceMsg(mWxMsgData) do
        begin
          tmpNode := GetNode('MediaId'); // ������Ϣý��id�����Ե��ö�ý���ļ����ؽӿ���ȡ���ݡ�
          MediaId := string(tmpNode.NodeValue);
          tmpNode := GetNode('Format'); // ������ʽ����amr��speex��
          Format := string(tmpNode.NodeValue);
          tmpNode := GetNode('MsgId');
          i64 := StrToInt64(string(tmpNode.NodeValue));
          MsgId := i64; // ��Ϣid��64λ����
        end;
        mWxMsgType := wmt_voice;

        // ��Ƶ��Ϣ ���� С��Ƶ��Ϣ
      end
      else if (aNode.NodeValue = 'video') or (aNode.NodeValue = 'shortvideo')
      then
      begin
        mWxMsgData := TWxMediaMsg.Create;
        GlobalFieldAnalyze;
        with TWxMediaMsg(mWxMsgData) do
        begin
          tmpNode := GetNode('MediaId'); // ��Ƶ��Ϣý��id�����Ե��ö�ý���ļ����ؽӿ���ȡ���ݡ�
          MediaId := string(tmpNode.NodeValue);
          tmpNode := GetNode('ThumbMediaId'); // ��Ƶ��Ϣ����ͼ��ý��id�����Ե��ö�ý���ļ����ؽӿ���ȡ���ݡ�
          ThumbMediaId := string(tmpNode.NodeValue);
          tmpNode := GetNode('MsgId');
          i64 := StrToInt64(string(tmpNode.NodeValue));
          MsgId := i64; // ��Ϣid��64λ����
        end;
        if (aNode.NodeValue = 'video') then
          mWxMsgType := wmt_video
        else
          mWxMsgType := wmt_shortvideo;

        // λ����Ϣ
      end
      else if aNode.NodeValue = 'location' then
      begin
        mWxMsgData := TWxLocationMsg.Create;
        GlobalFieldAnalyze;
        with (TWxLocationMsg(mWxMsgData)) do
        begin
          tmpNode := GetNode('Location_X'); // ����λ��ά��
          Location_X := StrToFloat(string(tmpNode.NodeValue));
          tmpNode := GetNode('Location_Y'); // ����λ�þ���
          Location_Y := StrToFloat(string(tmpNode.NodeValue));
          tmpNode := GetNode('Scale'); // ��ͼ���Ŵ�С
          Scale := StrToInt(string(tmpNode.NodeValue));
          tmpNode := GetNode('Label'); // ����λ����Ϣ
          PosLabel := string(tmpNode.NodeValue);
          tmpNode := GetNode('MsgId');
          i64 := StrToInt64(string(tmpNode.NodeValue));
          MsgId := i64; // ��Ϣid��64λ����
        end;
        mWxMsgType := wmt_location;

        // ������Ϣ
      end
      else if aNode.NodeValue = 'link' then
      begin
        mWxMsgData := TWxLinkMsg.Create;
        GlobalFieldAnalyze;
        with TWxLinkMsg(mWxMsgData) do
        begin
          tmpNode := GetNode('Title'); // ��Ϣ����
          Title := string(tmpNode.NodeValue);
          tmpNode := GetNode('Description'); // ��Ϣ����
          Description := string(tmpNode.NodeValue);
          tmpNode := GetNode('Url'); // ��Ϣ����
          Url := string(tmpNode.NodeValue);
          tmpNode := GetNode('MsgId');
          i64 := StrToInt64(string(tmpNode.NodeValue));
          MsgId := i64; // ��Ϣid��64λ����
        end;
        mWxMsgType := wmt_link;

        // �¼���Ϣ
      end
      else if aNode.NodeValue = 'event' then
      begin
        mWxMsgData := TWxEventMsg.Create;
        GlobalFieldAnalyze;
        aNode := GetNode('Event');

        // �����¼�������ɨ�趩���¼���
        if (aNode.NodeValue = 'subscribe') then
        begin
          tmpNode := GetNode('EventKey');
          if (tmpNode <> nil) then
          begin
            TWxEventMsg(mWxMsgData).SetEventType(wet_ScanQRCodeSubscribe);
            with TWxEventScanQRCodeData(TWxEventMsg(mWxMsgData).EventData) do
            begin
              EventKey := string(tmpNode.NodeValue);
              // �¼�KEYֵ��qrscene_Ϊǰ׺������Ϊ��ά��Ĳ���ֵ
              tmpNode := GetNode('Ticket');
              Ticket := string(tmpNode.NodeValue); // ��ά���ticket����������ȡ��ά��ͼƬ
            end;
          end
          else
            TWxEventMsg(mWxMsgData).SetEventType(wet_subscribe)

            // ȡ�������¼�
        end
        else if (aNode.NodeValue = 'unsubscribe') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_unsubscribe)

          // �Ѿ����ĺ󴥷�ɨ���¼�
        end
        else if (aNode.NodeValue = 'SCAN') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_Scan);
          with TWxEventScanQRCodeData(TWxEventMsg(mWxMsgData).EventData) do
          begin
            tmpNode := GetNode('EventKey');
            EventKey := string(tmpNode.NodeValue);
            // �¼�KEYֵ��qrscene_Ϊǰ׺������Ϊ��ά��Ĳ���ֵ
            tmpNode := GetNode('Ticket');
            Ticket := string(tmpNode.NodeValue); // ��ά���ticket����������ȡ��ά��ͼƬ
          end;

          // �ϱ�λ����Ϣ�¼�
        end
        else if (aNode.NodeValue = 'LOCATION') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_reportLocation);
          with TWxEventLocationData(TWxEventMsg(mWxMsgData).EventData) do
          begin
            tmpNode := GetNode('Latitude');
            Latitude := StrToFloat(string(tmpNode.NodeValue)); // ����λ��γ��
            tmpNode := GetNode('Longitude');
            Longitude := StrToFloat(string(tmpNode.NodeValue)); // ����λ�þ���
            tmpNode := GetNode('Precision');
            Precision := StrToFloat(string(tmpNode.NodeValue)); // ����λ�þ���
          end;

          // �˵�����¼�
        end
        else if (aNode.NodeValue = 'CLICK') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_MenuClick);
          tmpNode := GetNode('EventKey');
          TWxEventMenuData(TWxEventMsg(mWxMsgData).EventData).EventKey :=
            string(tmpNode.NodeValue);

          // �˵���ת�����¼�
        end
        else if (aNode.NodeValue = 'VIEW') then
        begin
          TWxEventMsg(mWxMsgData).SetEventType(wet_View);
          tmpNode := GetNode('EventKey');
          TWxEventMenuData(TWxEventMsg(mWxMsgData).EventData).EventKey :=
            string(tmpNode.NodeValue);

          // δ֪�¼�
        end
        else
          raise Exception.Create('δ֪�¼���' + string(aNode.NodeValue));

        mWxMsgType := wmt_event;
      end;
    end
    else
    begin
      FXml.SaveToXML(sXml);
      raise Exception.Create('��Ч��΢����Ϣ��' + sXml);
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
    // �жϴ��ݹ�������Ϣ�Ƿ������
    aNode := GetNode('Encrypt');
    if (aNode <> nil) then
    begin
      // ���������ļ��ܻ��ģʽ��
      tmpNode := GetNode('MsgType');
      if (tmpNode <> nil) then
      begin
        mWxMsgEncodeType := wmet_fix;

        DecodeMsg;

        // ������ģʽ
      end
      else
      begin
        mWxMsgEncodeType := wmet_encrypt;
        DecryptRtn := FWxMsgCrypt.DecryptMsg(mWxToken, mTimeStamp, mNonce,
          string(aNode.NodeValue), mMsgSignature, mWxAppID, mWxEncodingAESKey,
          sDecryptMsg);
        if (DecryptRtn <> WXBizMsgCrypt_OK) then
          raise Exception.Create('΢����Ϣ����ʧ�ܣ�������룺' +
            IntToStr(Integer(DecryptRtn)));
        FXml.LoadFromXML(sDecryptMsg);
        if (FXml.DocumentElement.nodeName = 'xml') then
          DecodeMsg
        else
          raise Exception.Create('΢����Ϣ�����ĸ�ʽ����ȷ��' + sDecryptMsg);
      end;

      // ����ģʽ
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
    raise Exception.Create('��Ч��΢����Ϣ��' + sXml);
  end;

  if mWxMsgType = wmt_known then
  begin
    FXml.SaveToXML(sXml);
    raise Exception.Create('�޷�����΢����Ϣ���ͣ�' + sXml);
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
    raise Exception.Create('����΢����Ϣʧ�ܣ�������룺' + IntToStr(Integer(ret)))
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
