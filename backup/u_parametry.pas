unit u_parametry;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType,  SysUtils, Variants, Classes,
  Graphics, Controls, Forms,
  Dialogs, StdCtrls, FileCtrl, EditBtn, ExtCtrls, LazFileUtils, types, Math;


var a:TControl;

type

 TZbior = set of 0..255; //zbior z wybranymi przez usera obrazkami

 { TMojDirectoryEdit }

 //Wlasna klasa pochodna od TDirectoryEdit - na potrzeby wyboru katalogu - podrasowany, zeby katalog nie 'uciekal'  ;) bo mylace :
 TMojDirectoryEdit = class(TDirectoryEdit)
   procedure RunDialog(); override;   //to sie wykonuje po kliknieciu (nie wykonuje sie onClick...)
   public constructor WlasnyCreate();
   private
     procedure CoNaDEKatalogChange(Sender: TObject);  //w wyniku RunDialog() zmieni sie katalog, a wtedy wykopnuje sie onChang...e
 end;

  { TFParametry }

  TFParametry = class(TForm)
    BDomyslne: TButton;
    BMinus: TButton;
    BOK: TButton;
    BPlus: TButton;
    BSelUp: TButton;
    BSelDown: TButton;
    CBOdgrywaj: TCheckBox;
    CBPodp: TCheckBox;
    CBShrink: TCheckBox;
    CBNazwa: TCheckBox;
    ComboBoxKolor: TComboBox;
    DEKatalogSkib : TMojDirectoryEdit;
    {}
    EPoziom: TEdit;
    FListBox1: TFileListBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    Label1: TLabel;
    Label9: TLabel;
    LKatalog: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    LCount: TLabel;
    RB2W: TRadioButton;
    RB1W: TRadioButton;
    RBPochwala: TRadioButton;
    RBNoAward: TRadioButton;
    RBOklaski: TRadioButton;
    RBOkrzyk: TRadioButton;
    procedure BDomyslneClick(Sender: TObject);
    procedure BMinusClick(Sender: TObject);
    procedure BOKClick(Sender: TObject);
    procedure BPlusClick(Sender: TObject);
    procedure BSelDownClick(Sender: TObject);
    procedure BSelUpClick(Sender: TObject);
    procedure CBNazwaChange(Sender: TObject);
    procedure CBOdgrywajChange(Sender: TObject);
    procedure CBPodpChange(Sender: TObject);
    procedure CBShrinkChange(Sender: TObject);
    procedure ComboBoxKolorChange(Sender: TObject);
    procedure ComboBoxKolorDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure DEKatalogMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure EPoziomChange(Sender: TObject);
    procedure FListBox1SelectionChange(Sender: TObject; User: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RB2WChange(Sender: TObject);
    procedure RBOkrzykMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    type TPowod = (spacje, dlugosc);
    //procedure SprawdzPoprawnoscZasobow(var ZasobyPoprawne: boolean; var bledny_wyraz: string);
  private
    procedure UstawDomyslnie();
    { Private declarations }
  public
    procedure UstawSelekcjeCiagla(indP, indK: integer);  //ustawienie ciaglej selekcji (jeden ciagly obszar w ListBox)
    procedure UsunSelekcje();   //calkowirte zdjecie wszelkiej selekcji
    procedure UstawZbior(var Zbior:TZbior);     //do Zbioru wrzucane sa indeksy wyselekcjonowanych plikow (ma zwierac tylko te indeksy)
    procedure UstawSelekcjeWgZbioru(const Zbior:TZbior);
    function  DajLicznoscZbioru(const ZBior:TZbior):Integer;
  end;

var
  FParametry: TFParametry;
  Zbior: TZbior; //zbior wyselekcjonowanych w danej chwili elementw TListBox i TFileLIstBox, system-wide

implementation

uses  u_operacje,u_tmimage;

var
  Zmieniono_Katalog:Boolean;       //zeby bylo wiadomo, jesli user wybierze 'wlasny' katalog z Zasobami
  Zmieniono_Poziom: Boolean;       //zeby bylo wiadomo, jezeli user zmieni poziom (liczbe wyswietlanych obrazkow)
  Zmieniono_Shrink: Boolean;       //zeby bylo wiadomo, jezeli user zmienil chec pomniejszania/zwiekszania obrazkow
  Zmieniono_2_na_1_Wierz: Boolean; //zeby bylo wiadomo, jezeli user zmienil rozmieszczenie 4-ch obrazkow z defaultopwych 2 na 1 wiersz
  Zmieniono_Nazwa:Boolean;         //zeby bylo wiadomo, jesli user zmienil pokaywanie/nie pokazywanie nazw/podpisow pod obrazkiem gornym
  {}
  SesjaStartuje: boolean = True;  //zeby zroznicowac zachowanie i komunikat jezeli znajdziemy blad w Zasobach
  LiczbaObrazkow: integer;        //ile obrazkow w wybranym katalogu

  Zbior_pop : TZbior;       //Zbior 'poprzedni' - na sprawdzenie czy po wejsciu na FParametry dokonano zmian w selekcji

{$R *.lfm}

{ TFParametry }

const
  {kolory:}
  //clPink = 16742655;
  clPink = $FF00FF; //RGB=(255,0,255) $-kod szesnastkowy



procedure TFParametry.UstawDomyslnie();
var biezacy :string;
    LWP :SmallInt; //liczba wybranych plikow/obrazkow
Begin
  biezacy := GetCurrentDir(*UTF8*) + DirectorySeparator + 'Zasoby';//tutaj getCurrentDir robil problemy jesli polski znak w sciezce do katalogu - np do Pulpit -> c:\users\dumańska\pulpit - nie znajdowal....
  //Tworzenie wlasnej kontrolki do wyboru katalogow:
  DEKatalogSkib := TMojDirectoryEdit.WlasnyCreate();
  DEKatalogSkib.Parent:=FParametry;
  DEKatalogSkib.Left  :=FListBox1.Left;
  DEKatalogSkib.Top   :=LKatalog.Top+LKatalog.Height+2;
  DEKatalogSkib.Width :=FListBox1.Width+50;
  DEKatalogSkib.Directory := biezacy;

  //Naczytanie plikow do TFIleLIstBox1 i ustawienie startowej selekcji:
  FListBox1.Directory := biezacy;

  UsunSelekcje();

  LWP := Min(MAX_OBR_OD,FListBox1.Count);

  FListBox1.MultiSelect := True; //nie ustawiac Multiselect w Design-time bo zawsze pokaze ostatni item jako wybrany....
  UstawSelekcjeCiagla(0,LWP-1);
  EPoziom.Text:=IntToStr(LWP);

  //Podpowiedz:
  CBPodp.Checked :=True;
  //Nagroda :
  RBPochwala.Checked := True;
  //na wypadek, gdyby byl zablokowamy :
  BOK.Enabled := True;
  //Kolor FOperacje na czarny:
  ComboBoxKolor.ItemIndex := 9;
  ComboBoxKolorChange(ComboBoxKolor);
End;


procedure TFParametry.UstawSelekcjeCiagla(indP, indK: integer);
(* Wyselekcjonowanie CIAGLEGO (liczby plikow) obszaru w okienku z plikami *)
var i:integer;
Begin
  UsunSelekcje();
  for i:=indP to indK do begin
    FListBox1.Selected[i] := True;
  end;
  UstawZbior(Zbior); //zeby w Zbiorze miec informacje o (tylko i wylacznie) wyselekcjonowanych
End;



procedure TFParametry.UsunSelekcje();
(* Calkowite usuniecie selekcji z okienka z plikami *)
var
  i: integer;
Begin
  for i := 0 to FListBox1.Count - 1 do  begin
    FListBox1.Selected[i] := False;
  end;
  ZBior := [];
End;

procedure TFParametry.UstawZbior(var ZBior:TZbior);
(* Wyselekcjonowano np. recznie pliki -> ich indeksy wrzucane sa do Zbioru *)
(* Zbior nie zawiera nic inneg0, tylko indeksy biezaco wyselekcjonowanych. *)
var
  i: integer;
Begin
  Zbior := [];
  for i:=0 to FListBox1.Count-1 do begin
    if FListBox1.Selected[i] then
      Zbior := ZBior + [i];
  end;
  //writeln(popcnt(dword(yy)));
End;


procedure TFParametry.BDomyslneClick(Sender: TObject);
begin
  UstawDomyslnie();
end;


procedure TFParametry.BOKClick(Sender: TObject);
var BylyZmiany : Boolean;
Begin
  BylyZmiany := Zmieniono_Katalog  or Zmieniono_Poziom or Zmieniono_Shrink or
                Zmieniono_Nazwa or Zmieniono_2_na_1_Wierz or (Zbior<>Zbior_pop);
  If not BylyZmiany then
    Close //wtedy na FOperacje pozostaje dotychczasowy uklad
  Else begin
    if Zbior=[] then begin
      MessageDlg('Nie wybrano żadnego obrazka.' + #13#10 +
        'Wybierz obrazki lub naciśnij klawisz ''Wartości domyślne'' !', mtError, [mbOK], 0);
      Exit;
    end;
    if LiczbaObrazkow > 0 then begin
      if DajLicznoscZbioru(Zbior) < (MAX_OBR_OD+1) then begin
        FOperacje.liczbaObrWKatalogu := FParametry.FListBox1.Count;
        FOperacje.Naczytaj();  // bo inaczej na ekranie pozostana stare obrazki z poprzedniego katalogu
        Close;
      end
      else begin
        MessageDlg('Zbyt dużo wybranych obrazków.' + #13#10 + '        ' + 'Popraw!',  mtWarning, [mbOK], 0);
        if not PELNA_WERSJA then
          Application.MessageBox('Większa liczba obrazków dostępna jest w pełnej wersji aplikacji.','DopasujObrazek');
      end;
    end
    else
      MessageDlg('Brak obrazków typu JPG,GIF,BMP w wybranym katalogu.' + #13#10 +
        'Wybierz inny katalog lub naciśnij klawisz ''Wartości domyślne'' !', mtError, [mbOK], 0);
  End;
End;  (* Procedure *)

procedure TFParametry.BPlusClick(Sender: TObject);
var
  level: smallint;
Begin
  level := StrToInt(EPoziom.Text);
  if level < MAX_OBR_OD then
  begin
    level := level + 1;
    EPoziom.Text := IntToStr(level);
    UsunSelekcje();
    UstawSelekcjeCiagla(0, Min(level - 1, FListBox1.Count - 1));
    Zmieniono_Poziom := True; //dajemy znac, ze byla zmiana
  end
  else begin
    if not PELNA_WERSJA then begin
      MessageDlg('Próba przekroczenia limitu '+ IntToStr(MAX_OBR_OD)+' obrazków.', mtWarning, [mbOK], 0);
      Application.MessageBox('Większa liczba obrazków dostępna jest w pełnej wersji aplikacji.','DopasujObrazek');
    end;
  end;
End;

procedure TFParametry.BSelDownClick(Sender: TObject);
(* Przesuniecie wyselekcjonowanego obszaru (w okienku plikow) o 1 pozycje w dol *)
var zbRob:TZbior;
    i : Integer;
Begin
  if FListBox1.Selected[FListBox1.Count - 1] then
    EXIT; //jezeli koncowy item nalezy do selekcji, to nizej nie schodzimy
  //Przygotowanie zbioru roboczego, z 'przesunieciem':
  zbRob := [];
  for i := 0 to FListBox1.Count - 1 do begin
    if i in Zbior then begin
      zbRob := zbRob + [i+1]; //element 'przesuniety' o 1 w dol
    end;
  end;
  UsunSelekcje();
  Zbior := zbRob;
  UstawSelekcjeWgZbioru(Zbior);
End;


procedure TFParametry.BSelUpClick(Sender: TObject);
(* Przesuniecie wyselekcjonowanego obszaru (w okienku plikow) o 1 pozycje w gore *)
var zbRob:TZbior;
    i:Integer;
Begin
  if FListBox1.Selected[0] then
    EXIT; //jezeli pierwszy item nalezy do selekcji, to wyzej nie wchodzimy
  //Przygotowanie zbioru roboczego, z 'przesunieciem':
  zbRob := [];
  for i:=1 to FListBox1.Count-1 do begin  //jesli przetrwal Exit, to mamy pewnosc, ze item 0-wy nie jest selected i mozna tak zaczynac petle
    if i in Zbior then begin
      zbRob := zbRob + [i-1]; //element 'przesuniety' o 1 w dol
    end;
  end;
  UsunSelekcje();
  Zbior := zbRob;
  UstawSelekcjeWgZbioru(Zbior);
End;

procedure TFParametry.CBNazwaChange(Sender: TObject);
begin
  Zmieniono_Nazwa := not Zmieniono_Nazwa; //not - zeby wychwycic bezprduktywne 'pstrykanie' w jednej sesji
end;

procedure TFParametry.CBOdgrywajChange(Sender: TObject);
begin
  FOperacje.BGraj.Visible := CBOdgrywaj.Checked; //nawet jak nie ma dzwieku, to co? Niech sie pokazuje...
end;



procedure TFParametry.CBPodpChange(Sender: TObject);
Begin
  if CBPodp.Checked=FALSE then begin     //Gaszenie ewentualnych juz zapalonych Lapek
    With FOperacje do begin
      tabOb[nrWylos].JestLapka:= False;
      Ramka.JestLapka := False;
    end;
  end;
  FOperacje.BPodp.Visible := CBPodp.Checked;
End;

procedure TFParametry.CBShrinkChange(Sender: TObject);
Begin
  Zmieniono_Shrink := not Zmieniono_Shrink; //not - zeby wychwycic bezprduktywne 'pstrykanie' w jednej sesji
End;


procedure TFParametry.UstawSelekcjeWgZbioru(const Zbior:TZbior);
var i:integer;
Begin
  for i:=0 to FListBox1.Count - 1 do begin
    if i in Zbior then begin
      FListBox1.Selected[i] := True;
    end;
  end;
End;

function TFParametry.DajLicznoscZbioru(const Zbior:TZbior): Integer;
(* Ile obrazkow wyselekconowano *)
var i,licznik:Integer;
Begin
  licznik:=0;
  for i:=0 to FListBox1.Count-1 do
    if i in ZBior then licznik:=licznik+1;
  Result := licznik;
End;

procedure TFParametry.BMinusClick(Sender: TObject);
var level: smallint;
begin
  level := StrToInt(EPoziom.Text);
  if level > 1 then
  begin
    level := level - 1;
    EPoziom.Text := IntToStr(level);
    UsunSelekcje();
    UstawSelekcjeCiagla(0, Min(level - 1, FListBox1.Count - 1));
    Zmieniono_Poziom := True; //dajemy znac, ze byla zmiana
  end;
end;

procedure TFParametry.ComboBoxKolorChange(Sender: TObject);
var
  i: integer;
begin
  case ComboBoxKolor.ItemIndex of
    0: FOperacje.Color := clTeal;
    1: FOperacje.Color := clGreen;
    2: FOperacje.Color := clBlue;
    3: FOperacje.Color := Random($1000000);
    4: FOperacje.Color := clAqua;
    5: FOperacje.Color := clYellow;
    6: Foperacje.Color := clPink;
    7: Foperacje.Color := clDefault;
    //male 'oszustwo' - wybralism pikerem clGray, ale FOperacje ustawiamy na clDefault, bo Gray jest za szary, a w ComboBoxie clDefault prezentujae sie jako bialy kwadrat...
    8: Foperacje.Color := clWhite;
    9: FOperacje.Color := clBlack;
  end;
  //Zmieny kolorow obiektow na FOperacje, tak, zeby mozna nadal bylo je widac:
  FOperacje.LNazwa.Font.Color := skib_InvertColor(FOperacje.Color);
  if Ramka <> nil then begin
    Ramka.UstawKolorObramowania(FOperacje.Color);
    Ramka.Brush.Color := Ramka.Pen.Colorxxxxx; //na potrzeby WybierzObrazek - zmiana tla Ramki - 2019.09.29
  end;
  for i := 1 to TMojImage.liczbaOb do
    if FOperacje.tabOb[i].JestLapka then
      FOperacje.tabOb[i].UstawKolorObramowaniaLapki(FOperacje.Color);
end;

procedure TFParametry.ComboBoxKolorDrawItem(Control: TWinControl;
  Index: integer; ARect: TRect; State: TOwnerDrawState);
var
  ltRect: TRect;

  procedure FillColorfulRect(aCanvas: TCanvas; myRect: TRect);
  //paint random color
  // Fills the rectangle with random colours
  var
    y: integer;
  begin
    for y := myRect.Top to myRect.Bottom - 1 do
    begin
      aCanvas.Pen.Color := Random($1000000);
      aCanvas.Line(myRect.Left, y, myRect.Right, y);
    end;
  end;

Begin
  ComboBoxKolor.Canvas.FillRect(ARect);
  //first paint normal background
  ComboBoxKolor.Canvas.TextRect(ARect, 22, ARect.Top, ComboBoxKolor.Items[Index]);
  //paint item text

  ltRect.Left := ARect.Left + 2;
  //rectangle for color
  ltRect.Right := ARect.Left + 20;
  ltRect.Top := ARect.Top + 1;
  ltRect.Bottom := ARect.Bottom - 1;

  ComboBoxKolor.Canvas.Pen.Color := clBlack;
  ComboBoxKolor.Canvas.Rectangle(ltRect);
  //draw a border

  if InflateRect(ltRect, -1, -1) then
    //resize rectangle by one pixel
    if Index = 3 then
      FillColorfulRect(ComboBoxKolor.Canvas, ltRect)
    //paint random color
    else begin
      case Index of
        0: ComboBoxKolor.Canvas.Brush.Color := clteal;
        1: ComboBoxKolor.Canvas.Brush.Color := clGreen;
        2: ComboBoxKolor.Canvas.Brush.Color := clBlue;
        4: ComboBoxKolor.Canvas.Brush.Color := clAqua;
        5: ComboBoxKolor.Canvas.Brush.Color := clYellow;
        6: ComboBoxKolor.Canvas.Brush.Color := clPink;
        7: ComboBoxKolor.Canvas.Brush.Color := clGray;//clDefault;
        8: ComboBoxKolor.Canvas.Brush.Color := clWhite;
        9: ComboBoxKolor.Canvas.Brush.Color := clBlack;
      end;
      ComboBoxKolor.Canvas.FillRect(ltRect);
      //paint colors according to selection
    end;
End; (* ComboBox1DrawItem *)


procedure TMojDirectoryEdit.CoNaDEKatalogChange(Sender: TObject);
(* Gdy wymieniamy/zmieniamy katalog z zasobami - zmieniamy tez na formie glownej*)
var LWP : Integer; //liczba wybranych plikow/obrazkow
    rob : string;
Begin
  With FParametry do begin
    Zmieniono_Katalog := True;  //zeby bylo wiadomo w momencie kiedy nacisniemy OK; OnChange wywoluje sie TYLKO jesli rzeczywiscie zmieniono katalog...
    FListBox1.Directory := Self.Directory;

    SciezkaZasoby := FListBox1.Directory + DirectorySeparator;

    //policzenie obrazkow w tym katalogu :
    LiczbaObrazkow := FListBox1.Count;
    LCount.Caption := IntToStr(LiczbaObrazkow); //kosmetyka

    //jesli wybrano katalog z Zerowa liczba obrazkow blokujemy klawisze, zeby nie bylo Errorsow:
    if LiczbaObrazkow < 1 then begin
      //SPRAWDZENIE, CZY ROZPAKOWANO:
      rob := GetCurrentDirUTF8;
      //MessageDlg(rob + #13#10 +  ' GetCurrentDirUTF8', mtError, [mbOK], 0);
      if (Pos('system32',rob)<> 0) or (Pos('\Temp',rob)<>0) then begin
        MessageDlg('Nie można znaleźć obrazków.' + #13#10 +
        'Prawdopodobnie nie rozpakowano aplikacji do osobnego folderu.'+ #13#10+
        'Rozpakuj (wyodrębnij) aplikację!', mtError, [mbOK], 0);
        HALT;
      end
      else
        MessageDlg('Brak obrazków typu JPG,PNG,BMP,GIF w wybranym katalogu.' + #13#10 +
          'Wybierz inny katalog lub naciśnij klawisz ''Wartosści domyślne'' !', mtError, [mbOK], 0)
    end
    else begin
      //SprawdzPoprawnoscZasobow(ZasobyPoprawne, bledny_wyraz);

      //Teraz trick-korekcja - ustawiam selekcje jak nizej, bo ten onChange wywoluje TFileLIstBoxOnChache, a tam liczba wyselekcjonowanych ustawia sie na 1 (jeden)
      LWP := Min(MAX_OBR_OD,FListBox1.Count);
      UstawSelekcjeCiagla(0,LWP-1);
      EPoziom.Text:=IntToStr(LWP);
    end;
  End; //With
End; (* DEKatalogChange *)


procedure TFParametry.DEKatalogMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin

end;


procedure TFParametry.EPoziomChange(Sender: TObject);
(* Reakcja/zabezpieczenie na sytuacje, kiedy poprze Ctrl-Click na FileListBox1 *)
(* przekraczamy dozwolona liczbę plików do pokazania                           *)
var poziom:SmallInt;
Begin
  poziom:=StrToInt(EPoziom.Text);
  if poziom>MAX_OBR_OD then begin
    MessageDlg('Przekroczono limit '+ IntToStr(MAX_OBR_OD)+' obrazków.' + #13#10 +  'Zmniejsz liczbę wybranych obrazków!', mtError, [mbOK], 0);
    if not PELNA_WERSJA then
      Application.MessageBox('Większa liczba obrazków dostępna jest w pełnej wersji aplikacji.','DopasujObrazek');;
  end;
  if poziom<4 then
    CBShrink.Checked:=True     //jak zjedziemy do 3 i mniej, to nalezaloby pomniejszyc....
  else
    CBShrink.Checked:=False;   //a jak duzo, to nie pomniejszamy - niech user sam wymusza...
End;


procedure TFParametry.FListBox1SelectionChange(Sender: TObject; User: boolean);
(* Co sie dzieje, kiedy klikniemy w kontrolce (selekconouja sie pliki) *)
(* Bez wzgledu na sposob klikniecia (Ctrl-Click lub tylko CLick) zmieni sie liczba wyselekcjonowanych plikow - odzwierciedlam *)
Begin
 if SesjaStartuje then EXIT;  //zeby nie wykonywal sie na OnCreate Formy

 UstawZbior(Zbior);
 EPoziom.Text := IntToStr(DajLicznoscZbioru(Zbior));
End;


procedure TFParametry.FormCreate(Sender: TObject);
Begin
  //wypelnianie comboboxa na kolory tla formy Foperacje :
  ComboBoxKolor.Items.Clear;             //Delete all existing choices
  ComboBoxKolor.Items.Add('  Teal');        //Add an choice
  ComboBoxKolor.Items.Add('  Zielony');
  ComboBoxKolor.Items.Add('  Niebieski');
  ComboBoxKolor.Items.Add('  Losowy');
  ComboBoxKolor.Items.Add('  Aqua');
  ComboBoxKolor.Items.Add('  Żółty');
  ComboBoxKolor.Items.Add('  Różowy');
  ComboBoxKolor.Items.Add('  Szary');
  ComboBoxKolor.Items.Add('  Biały');
  ComboBoxKolor.Items.Add('  Czarny');

  //Teraz domyslne ustawienia parametrow programu :
  UstawDomyslnie;
  DEKatalogSkib.CoNaDEKatalogChange(FParametry);
End; (* FormCreate *)


procedure TFParametry.FormShow(Sender: TObject);
Begin
  LCount.Caption := IntToStr(FListBox1.Count);
  {}
  Zmieniono_Katalog     := False;
  Zmieniono_Poziom      := False;
  Zmieniono_Shrink      := False;
  Zmieniono_2_na_1_Wierz:= False;
  Zmieniono_Nazwa       := False;
  {}
  Zbior_pop := ZBior;  //zeby przy wychodzeniu z formy moc porownac i stwierdzic, czy zmieniono selekcje
  //Jezeli moglem zobaczyc (onShow) te forme, to znaczy, ze sesja z programem juz trwa (nie jest to 'zaraz po starcie'
  SesjaStartuje := False;   //zeby wiedziec jaki generowac kom. kiedy bledy w katalogu z Zasobami
End;

procedure TFParametry.RB2WChange(Sender: TObject);
Begin
  Zmieniono_2_na_1_Wierz:=not Zmieniono_2_na_1_Wierz;
End;


procedure TFParametry.RBOkrzykMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
Begin
  if RBOkrzyk.Checked and not FileExists('c:\windows\media\tada.wav') then
  begin
    MessageDlg('Nie mogę znaleźć odpowiednigo pliku na tym komputerze!',
      mtError, [mbOK], 0);
    RBOkrzyk.Checked := False;
    //powrot do stanu sprzed klikniecia (ale tylko z tym RButtonem)
    RBOklaski.Checked := True;    //wymuszam opcje - 'Oklaski' (zeby sobie ulatwic nie sprawdzam co bylo przedtem...)
  end;
End;


procedure TMojDirectoryEdit.RunDialog();
(* Nadpisanie, zeby zawsze na rozpoczeciu wybierania ustawial sie nie na ostatnim katalogu, ale na Zasoby *)
begin
  //dzieki temu ponizej user sie nie bedzie 'gubil' - zawsze przy ponownym wyborze wroci do Zasoby
  Self.Directory:=GetCurrentDirUTF8+DirectorySeparator+'Zasoby';
  inherited RunDialog();
end;


constructor TMojDirectoryEdit.WlasnyCreate();
begin
  inherited Create(nil);
  Self.RootDir := GetCurrentDirUTF8+DirectorySeparator+'Zasoby'; //zeby na ekranie bylo widac, ale to nie jest wazne - wazne jest to samo w RunDialog() !!!
  Self.OnChange:= CoNaDEKatalogChange;
end;


begin
  Zbior := [];
end.