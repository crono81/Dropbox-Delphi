object Form1: TForm1
  Left = 278
  Top = 162
  AutoScroll = False
  Caption = 'Form1'
  ClientHeight = 489
  ClientWidth = 465
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 48
    Width = 387
    Height = 13
    Caption = 
      'Generated token (this token can be saved to use it later, even i' +
      'f the app is closed)'
  end
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 137
    Height = 25
    Caption = 'Authorize application'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 8
    Top = 88
    Width = 137
    Height = 25
    Caption = 'List files'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Edit1: TEdit
    Left = 8
    Top = 64
    Width = 449
    Height = 21
    TabOrder = 2
  end
  object Button3: TButton
    Left = 8
    Top = 120
    Width = 137
    Height = 25
    Caption = 'Download file'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 152
    Top = 88
    Width = 137
    Height = 25
    Caption = 'Upload file'
    TabOrder = 4
    OnClick = Button4Click
  end
  object StringGrid1: TStringGrid
    Left = 8
    Top = 152
    Width = 449
    Height = 329
    ColCount = 6
    FixedCols = 0
    RowCount = 2
    TabOrder = 5
    ColWidths = (
      40
      64
      76
      76
      78
      79)
  end
  object IdLogEvent1: TIdLogEvent
    Active = True
    OnReceived = IdLogEvent1Received
    OnSent = IdLogEvent1Sent
    Left = 152
    Top = 8
  end
end
