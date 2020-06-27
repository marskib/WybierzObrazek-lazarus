unit u_parametry;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType,  SysUtils, Variants, Classes,
  Graphics, Controls, Forms,
  Dialogs, StdCtrls, FileCtrl, EditBtn, ExtCtrls, LazFileUtils, types, Math, FileUtil;


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
    CBAutomat: TCheckBox;
    CBShowRamka: TCheckBox;
    CBPictNames: TCheckBox;
    CBOdgrywaj: TCheckBox;
    CBPodp: TCheckBox;
    CBShrink: TCheckBox;
    CBNazwa: TCheckBox;
    CBUpperLower: TCheckBox;
    ComboBoxKolor: TComboBox;
    DEKatalogSkib : TMojDirectoryEdit;
    {}
    EPoziom: TEdit;
    FListBox1: TFileListBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label9: TLabel;
    LKatalog: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    LCount: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    RBCenter: TRadioButton;
    RBLeft: TRadioButton;
    RBNegYes: TRadioButton;
    RBNegNo: TRadioButton;
    RadioGroup1: TRadioGroup;
    RB2W: TRadioButton;
    RB1W: TRadioButton;
    RBPochwala: TRadioButton;
    RBNoAward: TRadioButton;
    RBOklaski: TRadioButton;
    RBOkrzyk: TRadioButton;
    RGPolozeniePodpisu: TRadioGroup;
    procedure BDomyslneClick(Sender: TObject);
    procedure BMinusClick(Sender: TObject);
    procedure BOKClick(Sender: TObject);
    procedure BPlusClick(Sender: TObject);
    procedure BSelDownClick(Sender: TObject);
    procedure BSelUpClick(Sender: TObject);
    procedure BDefColorClick(Sender: TObject);

    procedure CBNazwaChange(Sender: TObject);
    procedure CBOdgrywajChange(Sender: TObject);
    procedure CBPictNamesChange(Sender: TObject);
    //procedure CBOdgrywajChange(Sender: TObject);
    procedure CBPodpChange(Sender: TObject);
    procedure CBShowRamkaChange(Sender: TObject);
    procedure CBShrinkChange(Sender: TObject);
    procedure CBUpperLowerChange(Sender: TObject);
    procedure ComboBoxKolorChange(Sender: TObject);
    procedure DEKatalogMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure EPoziomChange(Sender: TObject);
    procedure FListBox1SelectionChange(Sender: TObject; User: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RB2WChange(Sender: TObject);
    procedure RBLeftChange(Sender: TObject);
    procedure RBOkrzykMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    type TPowod = (spacje, dlugosc);
    //procedure SprawdzPoprawnoscZasobow(var ZasobyPoprawne: boolean; var bledny_wyraz: string);
  private
    procedure WypelnijComoBoxKolory();
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
  Zmieniono_2_na_1_Wiersz: Boolean; //zeby bylo wiadomo, jezeli user zmienil rozmieszczenie 4-ch obrazkow z defaultopwych 2 na 1 wiersz
  Zmieniono_Nazwa: Boolean;        //zeby bylo wiadomo, jesli user zmienil pokaywanie/nie pokazywanie nazw/podpisow pod obrazkiem gornym
  Zmieniono_Podpis:Boolean;        //podpisy pod obrazkami, jezeli user ...... j.w. ......
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
  //ustawienie koloru (nie robimy w proc. wyzej, bo ona jest wywolywania, kiedy jeszcze nie ma Ranki):
  ComboBoxKolor.ItemIndex := 3;
  ComboBoxKolorChange(Nil);
end;


procedure TFParametry.BOKClick(Sender: TObject);
var BylyZmiany : Boolean; //czy byly "powazne" zmiany

Begin
  BylyZmiany := Zmieniono_Katalog  or Zmieniono_Poziom or Zmieniono_Shrink or
                Zmieniono_Nazwa or ZMieniono_Podpis or Zmieniono_2_na_1_Wiersz or (Zbior<>Zbior_pop);
  If not BylyZmiany then begin
    Close; //wtedy na FOperacje pozostaje dotychczasowy uklad
  end
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
          Application.MessageBox('Większa liczba obrazków dostępna jest w pełnej wersji aplikacji.','WybierzObrazek');
      end;
    end
    else
      MessageDlg('Brak obrazków typu JPG,GIF,BMP w wybranym katalogu.' + #13#10 +
        'Wybierz inny katalog lub naciśnij klawisz ''Wartości domyślne'' !', mtError, [mbOK], 0);
  End;

  //Zeby zaczal/przestal grac automatycznie (dokklejka dla WybierzObrazek - 2019.12.21):
  FOperacje.Timer5sek.Enabled := CBAutomat.Checked;
  if CBAutomat.Checked then                  //1-sze odegranie przy wejsciu na FOperacje
    FOperacje.Timer5sekTimer(Self);          //Self - wywolywana proc. będzie wiedziala, co z tym zrobic - zagrac z lekkim opoznieniem

  //jezeli wylaczono wszelkie glosowe formy polecenia, to wymuszam napis:
  if not (CBOdgrywaj.Checked or CBAutomat.Checked) then begin
    CBNazwa.Checked:=True;
    FOperacje.PokazNazwePodObrazkiem();
  end;


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
      Application.MessageBox('Większa liczba obrazków dostępna jest w pełnej wersji aplikacji.','WybierzObrazek');
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

procedure TFParametry.BDefColorClick(Sender: TObject);
(* Przywrocenie domyslnych kolorow tla ekranu i ramki.    *)
(* Kolory dobrane przez Konsultantkę - odcienie szarosci. *)
Begin
  FOperacje.UstawDefaultowyKolorRamki_Ekranu_Napisu();
End;


procedure TFParametry.CBNazwaChange(Sender: TObject);
begin
  Zmieniono_Nazwa := not Zmieniono_Nazwa; //not - zeby wychwycic bezprduktywne 'pstrykanie' w jednej sesji
end;

procedure TFParametry.CBOdgrywajChange(Sender: TObject);
begin
  Foperacje.SpeedBtnGraj.Enabled:=FParametry.CBOdgrywaj.Checked;  //jak nie odgrywamy, to wyszarzony
  if not FParametry.CBOdgrywaj.Checked then  //jak nie wolno powiedziec, to trzeba chociaz pokazac napis
    FParametry.CBNazwa.Checked :=True;
end;

procedure TFParametry.CBPictNamesChange(Sender: TObject);
var i : SmallInt;
Begin
  Zmieniono_Podpis := not Zmieniono_Podpis; //not - zeby wychwycic bezprduktywne 'pstrykanie' w jednej sesji
  {}
  With FOperacje do begin
     for i:=1 to TMojImage.liczbaOb do
       tabOb[i].PokazUkryjLPodpis(CBPictNames.Checked);
  end;
  //RGPolozeniePodpisu.Visible:=CBPictNames.Checked; //gasze/pokazuje stowarzyszony panel
  Panel2.Visible:=CBPictNames.Checked; //gasze/pokazuje stowarzyszony panel
End;



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

procedure TFParametry.CBShowRamkaChange(Sender: TObject);
begin
  Ramka.Visible:= not CBShowRamka.Checked;
  if CBShowRamka.Checked then
    FOperacje.PolozRamkeGhosta(true)
  else
    FOperacje.UkryjRamkeGhosta();
end;


procedure TFParametry.CBShrinkChange(Sender: TObject);
Begin
  Zmieniono_Shrink := not Zmieniono_Shrink; //not - zeby wychwycic bezprduktywne 'pstrykanie' w jednej sesji
  //Zmiejszenie/zwiekszenie ikon(y) glosnika (kosmetyka) 2020-01-10; ikony przechowuje w niewidzialnych SpeeBtn'ach :
  if CBShrink.Checked then
     FOperacje.SpeedBtnGraj.Glyph := FOperacje.SpeedBtn1.Glyph
  else
     FOperacje.SpeedBtnGraj.Glyph := FOperacje.SpeedBtn2.Glyph
End;

procedure TFParametry.CBUpperLowerChange(Sender: TObject);
var i: SmallInt;
Begin
  for i:=1 to TMojImage.liczbaOb do begin
    FOperacje.tabOb[i].UpperLowerLettersLPodpis(CBUpperLower.Checked)
  end;
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
      {}

      jestPlikPodpisy:=False;
      if FileExists(GetCurrentDirUTF8+'\podpisy.txt') then begin
        AssignFile(plikPodpisy,GetCurrentDirUTF8+'\podpisy.txt');
        jestPlikPodpisy := True;
      end;
      {}
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
      Application.MessageBox('Większa liczba obrazków dostępna jest w pełnej wersji aplikacji.','WybierzObrazek');;
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


procedure TFParametry.WypelnijComoBoxKolory();
(* wypelnianie comboboxa na kolory Tla  *)
Begin
  ComboBoxKolor.Items.Clear;             //Delete all existing choices
  ComboBoxKolor.Items.Add(' Aqua');        //0
  ComboBoxKolor.Items.Add(' Biały');       //1
  ComboBoxKolor.Items.Add(' Czarny');      //2
  ComboBoxKolor.Items.Add(' DOMYŚLNY');    //3 -> defaultowy
  ComboBoxKolor.Items.Add(' Niebieski');   //4
  ComboBoxKolor.Items.Add(' Różowy');      //5
  ComboBoxKolor.Items.Add(' Szary');       //6
  ComboBoxKolor.Items.Add(' Teal');        //7
  ComboBoxKolor.Items.Add(' Zielony');     //8
  ComboBoxKolor.Items.Add(' Żółty');       //9
End;

procedure TFParametry.FormCreate(Sender: TObject);
Begin
  UstawDomyslnie();  //Teraz domyslne ustawienia parametrow programu WybierzObrazek
  DEKatalogSkib.CoNaDEKatalogChange(FParametry);
  (**)
  WypelnijComoBoxKolory();
End; (* FormCreate *)


procedure TFParametry.ComboBoxKolorChange(Sender: TObject);
var i: SmallInt;
Begin
  case ComboBoxKolor.ItemIndex of
    0: FOperacje.Color := clAqua;
    1: FOperacje.Color := clWhite;
    2: FOperacje.Color := clBlack;
    3: Begin //przypadek Default'u wymaga szczegolnego potraktowanoia (w defaulcie Ramka ma nie miec obramowania + Czarny text pod obrazkiem*)
         FOperacje.UstawDefaultowyKolorRamki_Ekranu_Napisu();
         Exit; //szczegolne potraktowanie *(patrz wyzej) - dlatego exit
       End;
    4: FOperacje.Color := clBlue;
    5: Foperacje.Color := clPink;
    6: Foperacje.Color := clGray;
    7: Foperacje.Color := clTeal;
    8: FOperacje.Color := clGreen;
    9: FOperacje.Color := clYellow;
  end;
  //Zmiena Ramki tak, zeby mozna nadal bylo ja widac:
  if Ramka <> nil then begin
    Ramka.UstawKolorObramowania(FOperacje.Color);
    Ramka.Brush.Color := Ramka.Pen.Color;
  end;
  (**)
  FOperacje.LNazwa.Font.Color := skib_InvertColor(FOperacje.Color);
  (**)
  FOperacje.DostosujKoloryPozostalychObiektow();
End;


procedure TFParametry.FormShow(Sender: TObject);
Begin
  LCount.Caption := IntToStr(FListBox1.Count);
  {}
  Zmieniono_Katalog     := False;
  Zmieniono_Poziom      := False;
  Zmieniono_Shrink      := False;
  Zmieniono_2_na_1_Wiersz:= False;
  Zmieniono_Nazwa       := False;
  {}
  Zbior_pop := ZBior;  //zeby przy wychodzeniu z formy moc porownac i stwierdzic, czy zmieniono selekcje
  //Jezeli moglem zobaczyc (onShow) te forme, to znaczy, ze sesja z programem juz trwa (nie jest to 'zaraz po starcie'
  //Zeby nie gral automatycznie (if granie ustawione) podczas pobytu na FParametry, bo przeszkadza... :
  FOperacje.Timer5sek.Enabled := False;
  SesjaStartuje := False;   //zeby wiedziec jaki generowac kom. kiedy bledy w katalogu z Zasobami
End;

procedure TFParametry.RB2WChange(Sender: TObject);
Begin
  Zmieniono_2_na_1_Wiersz:=not Zmieniono_2_na_1_Wiersz;
End;

procedure TFParametry.RBLeftChange(Sender: TObject);
(* Podpisy pod oprazkiem lądują na nowych miejscch *)
var i: SmallInt;
Begin
  for i:=1 to TMojImage.liczbaOb do begin
    FOperacje.tabOb[i].WypozycjonujLPodpis();
  end;
End;

procedure TFParametry.RBOkrzykMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
Begin
  if RBOkrzyk.Checked and not FileExists('c:\windows\media\tada.wav') then
  begin
    MessageDlg('Nie mogę znaleźć odpowiednigo pliku na tym komputerze!', mtError, [mbOK], 0);
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
