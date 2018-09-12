unit Dropbox;

{TODO list:
 - Implement JSON support
}

interface

uses IdHTTP, Classes, IdIntercept, IdLogBase, IdLogEvent, uLkJSON, clipBrd;

type
  TSharingInfo = record
    read_only, traverse_only, no_access: boolean;
    parent_shared_folder_id, modified_by: string;
  end;
  TFieldsDP = record
    name, value: string;
  end;
  TPropertyGroups = record
    template_id: string;
    fields: TFieldsDP;
  end;
  TListResult = record
    tag, name, id, client_modified, server_modified, rev, path_lower,
    path_display, content_hash: string;
    size: integer;
    has_explicit_shared_members: boolean;
    sharing_info: TSharingInfo;
    property_groups: TPropertyGroups;
  end;

  TListResultArray = array of TListResult;

type
  TDropbox = class
  private
    FToken: string;
    FAppKey: string;
    FAppSecret: string;
    FRedirectURI: string;
    FIdLogEvent: TIdLogEvent;
    procedure WebBrowser1NavigateComplete2(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure FormShow(Sender: TObject);
    function ParseResult(json: string; var ResultList: TListResultArray; var cursor: string): boolean;
  protected
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure AuthorizeApp;
    function ListDirectory(Path, Access_Token: string): TListResultArray;
    function Download(const Folder, Nam, LocalFile, Access_Token: String): Boolean;
    function Upload(Const Folder, Nam, LocalFile, Access_Token: String): Boolean;
    property Token: string read FToken;
    property AppKey: string read FAppKey write FAppKey;
    property AppSecret: string read FAppSecret write FAppSecret;
    property RedirectURI: string read FRedirectURI write FRedirectURI;
    property IdLogEvent: TIdLogEvent read FIdLogEvent write FIdLogEvent;
  end;

implementation

uses
  SysUtils, StrUtils, ShellAPI, IdSSLOpenSSL, Forms, Windows, SHDocVw,
  Controls, Dialogs;

const
  URLAuth = 'https://www.dropbox.com/oauth2/authorize';
  UrlListFiles = 'https://api.dropboxapi.com/2/files/list_folder';
  UrlListFilesCont = 'https://api.dropboxapi.com/2/files/list_folder/continue';
  UrlDownload = 'https://content.dropboxapi.com/2/files/download';
  UrlUpload = 'https://content.dropboxapi.com/2/files/upload';

{ TDropbox }

procedure TDropbox.WebBrowser1NavigateComplete2(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
var iIdx, iIdx2: integer;
    Parent: TForm;
    Browser: TWebBrowser;
begin
  if (Pos(RedirectURI, URL) = 1) and (pos('access_token=', URL) > 0) then begin
    iIdx := pos('access_token=', URL) + length('access_token=');
    iIdx2 := PosEx('&', URL, iIdx) - iIdx;
    FToken := copy(URL, iIdx, iIdx2);
    Browser := (Sender as TWebBrowser);
    Parent := TWinControl(Browser).Parent as TForm;
    Parent.Close;
  end else if (Pos(RedirectURI, URL) = 1) then begin
    Browser := (Sender as TWebBrowser);
    Parent := TWinControl(Browser).Parent as TForm;
    Parent.Close;
  end;
end;

procedure TDropbox.FormShow(Sender: TObject);
var Browser: TWebBrowser;
    S: string;
begin
  Browser := TForm(Sender).FindComponent('Browser') as TWebBrowser;
  S := URLAuth + '?' + 'response_type=token';
  S := S + '&' + 'client_id=' + AppKey;
  S := S + '&' + 'redirect_uri=' + RedirectURI;
  S := S + '&' + 'state=01';
  S := S + '&' + 'require_role=personal';
  S := S + '&' + 'force_reapprove=false';
  S := S + '&' + 'disable_signup=false';
  S := S + '&' + 'locale=';
  S := S + '&' + 'force_reauthentication=false';
  Browser.Navigate(S);
end;

procedure TDropbox.AuthorizeApp;
var BrowserForm: TForm;
    Browser: TWebBrowser;
begin
  if (Trim(AppKey) <> '') and {(Trim(AppSecret) <> '') and}
  (Trim(RedirectURI) <> '') then begin
    BrowserForm := TForm.Create(nil);
    with BrowserForm do begin
      Caption := 'Authorize application';
      Position := poScreenCenter;
      Width := 500;
      Height := 500;
      Browser := TWebBrowser.Create(BrowserForm);
      TWinControl(Browser).Name := 'Browser';
      TWinControl(Browser).Parent := BrowserForm;
      Browser.Align := alClient;
      Browser.OnNavigateComplete2 := WebBrowser1NavigateComplete2;
      OnShow := FormShow;
      try
        ShowModal;
      finally
        Browser.Free;
        Free;
      end;
    end;
  end else begin
    ShowMessage('Appkey and RedirectURI must be provided');
  end;
end;

constructor TDropbox.Create;
begin
  FToken := '';
  FAppKey := '';
  FAppSecret := '';
  FRedirectURI := '';
end;

destructor TDropbox.Destroy;
begin

  inherited;
end;

function TDropbox.ParseResult(json: string; var ResultList: TListResultArray; var cursor: string): boolean;
var js, Entries, Item, sub_item: TlkJSONBase;
    i, idx: integer;
    bHasMore: boolean;
begin
  //Clipboard.AsText := response;
  js := TlkJSON.ParseText(json);
  bHasMore := js.Field['has_more'].Value;
  cursor := js.Field['cursor'].Value;
  Entries := js.Field['entries'];
  idx := 0;
  for i := 0 to pred(Entries.Count) do begin
    SetLength(ResultList, length(ResultList) + 1);
    item := Entries.Child[i];
    ResultList[idx].tag := Item.Field['.tag'].Value;
    ResultList[idx].name := Item.Field['name'].Value;
    ResultList[idx].id := Item.Field['id'].Value;
    if ResultList[idx].tag = 'file' then begin
      ResultList[idx].client_modified := Item.Field['client_modified'].Value;
      ResultList[idx].server_modified := Item.Field['server_modified'].Value;
      ResultList[idx].rev := Item.Field['rev'].Value;
      ResultList[idx].content_hash := Item.Field['content_hash'].Value;
      ResultList[idx].size := Item.Field['size'].Value;
      if Item.Field['has_explicit_shared_members'] <> nil then
        ResultList[idx].has_explicit_shared_members := Item.Field['has_explicit_shared_members'].Value;
    end;
    ResultList[idx].path_lower := Item.Field['path_lower'].Value;
    ResultList[idx].path_display := Item.Field['path_display'].Value;
    sub_item := Item.Field['sharing_info'];
    if sub_item <> nil then begin
      ResultList[idx].sharing_info.read_only := sub_item.Field['read_only'].Value;
      ResultList[idx].sharing_info.parent_shared_folder_id := sub_item.Field['parent_shared_folder_id'].Value;
      if ResultList[idx].tag = 'file' then begin
        ResultList[idx].sharing_info.modified_by := sub_item.Field['modified_by'].Value;
      end else begin
        ResultList[idx].sharing_info.traverse_only := sub_item.Field['traverse_only'].Value;
        ResultList[idx].sharing_info.no_access := sub_item.Field['no_access'].Value;
      end;
    end;
    sub_item := Item.Field['property_groups'];
    if sub_item <> nil then begin
      ResultList[idx].property_groups.template_id := sub_item.Field['template_id'].Value;
      sub_item := sub_item.Field['fields'];
      if sub_item <> nil then begin
        ResultList[idx].property_groups.fields.name := sub_item.Field['name'].Value;
        ResultList[idx].property_groups.fields.value := sub_item.Field['value'].Value;
      end;
    end;

    inc(idx);
  end;
  Result := bHasMore;
end;

function TDropbox.ListDirectory(Path, Access_Token: string): TListResultArray;
var IdHTTP1: TIdHTTP;
    response, json, cursor: string;
    JsonToSend: TStringStream;
    ResultList: TListResultArray;
    bHasMore: boolean;
begin
  response := '';
  IdHTTP1 := TIdHTTP.Create(nil);
  IdHTTP1.Request.ContentType := 'application/json';
  IdHTTP1.IOHandler := TIdSSLIOHandlerSocket.Create(IdHTTP1);
  if IdLogEvent <> nil then
    IdHTTP1.Intercept := IdLogEvent;
  with TIdSSLIOHandlerSocket(IdHTTP1.IOHandler) do begin
    SSLOptions.Method := sslvTLSv1;
    SSLOptions.Mode := sslmUnassigned;
    SSLOptions.VerifyMode := [];
    SSLOptions.VerifyDepth := 0;
    PassThrough := True;
  end;
  SetLength(ResultList, 0);
    
  IdHTTP1.Request.CustomHeaders.Add('Authorization: ' + 'Bearer ' + Access_Token);
  try
    //TODO: This line can be modified to perform more complex searches
    json := '{ "path": "' + Path + '", "recursive": false, "include_media_info": false, "include_deleted": false, "include_has_explicit_shared_members": false, "include_mounted_folders": true}';
    JsonToSend := TStringStream.Create(Utf8Encode(json));
    Response    := IdHTTP1.post(UrlListFiles, JsonToSend);

    bHasMore := ParseResult(response, ResultList, cursor);
    while bHasMore do begin
      json := '{ "cursor": "' + cursor + '"}';
      JsonToSend := TStringStream.Create(Utf8Encode(json));
      Response    := IdHTTP1.post(UrlListFiles, JsonToSend);
      bHasMore := ParseResult(response, ResultList, cursor);
    end;

    IdHTTP1.Free;
  except
    on e:exception do begin
      IdHTTP1.Free;
      ShowMessage('Error occurred: ' + e.Message);
    end;
  end;
  Result := ResultList;
end;

function TDropbox.Download(Const Folder, Nam, LocalFile, Access_Token: String): Boolean;
Var
  IdHTTP1: TIdHTTP;
  file_path: String;
  StrResp: TmemoryStream;
  json: string;
Begin
  if Folder = '' Then
    file_path := '/' + Nam
  else
    file_path := trim(Folder + '/' + Nam);
     
  StrResp := TmemoryStream.Create;
  IdHTTP1 := TIdHTTP.Create(nil);
  IdHTTP1.Request.ContentType := 'text/plain';
  IdHTTP1.Request.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
  IdHTTP1.IOHandler := TIdSSLIOHandlerSocket.Create(IdHTTP1);
  if IdLogEvent <> nil then
    IdHTTP1.Intercept := IdLogEvent;
  with TIdSSLIOHandlerSocket(IdHTTP1.IOHandler) do begin
    SSLOptions.Method := sslvTLSv1;
    SSLOptions.Mode := sslmUnassigned;
    SSLOptions.VerifyMode := [];
    SSLOptions.VerifyDepth := 0;
    PassThrough := True;
  end;  
  try
    json := '{"path":"' + file_path +'"}';
    IdHTTP1.Request.CustomHeaders.Add('Authorization: ' + 'Bearer ' + Access_Token);  
    IdHTTP1.Request.CustomHeaders.Add('Dropbox-API-Arg: ' + json); 

    try
      IdHTTP1.get(UrlDownload, StrResp);
    except
      Result := False;
    end;
    Result := IdHTTP1.ResponseCode = 200;
    StrResp.Position := 0;
    If Result Then
      StrResp.SaveToFile(LocalFile);
  finally
    IdHTTP1.Free;
    StrResp.Free;
  end;
end;

function TDropbox.Upload(Const Folder, Nam, LocalFile, Access_Token: String): Boolean;
Var
  IdHTTP1: TIdHTTP;
  file_path, S: String;
  StrResp: TFileStream;
  json: string;
begin
  Result := False;
  if Not FileExists(LocalFile) Then
    exit;
  if Folder = '' Then
    file_path := '/' + Nam
  else
    file_path := trim(Folder + '/' + Nam);

  StrResp := TFileStream.Create(LocalFile, fmOpenRead or fmShareDenyNone);
  IdHTTP1 := TIdHTTP.Create(nil);
  IdHTTP1.Request.ContentType := 'text/plain; charset=dropbox-cors-hack';
  IdHTTP1.Request.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
  IdHTTP1.IOHandler := TIdSSLIOHandlerSocket.Create(IdHTTP1);
  if IdLogEvent <> nil then
    IdHTTP1.Intercept := IdLogEvent;
  with TIdSSLIOHandlerSocket(IdHTTP1.IOHandler) do begin
    SSLOptions.Method := sslvTLSv1;
    SSLOptions.Mode := sslmUnassigned;
    SSLOptions.VerifyMode := [];
    SSLOptions.VerifyDepth := 0;
    PassThrough := True;
  end;
  try
    json := '{"autorename":false, "path":"' + file_path + '", "mute":false, "mode":"overwrite"}';
    IdHTTP1.Request.CustomHeaders.Add('Authorization: ' + 'Bearer ' + Access_Token);  
    IdHTTP1.Request.CustomHeaders.Add('Dropbox-API-Arg: ' + json);     
    try
      S := IdHTTP1.post(UrlUpload, StrResp);
    except
      Result := False;
    end;
    Result := IdHTTP1.ResponseCode = 200;
  finally
    IdHTTP1.Free;
    StrResp.Free;
  end;
end;

end.
