unit u_tmimage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, stdCtrls, ExtCtrls, FileCtrl, Forms, math, u_parametry,
  LCLIntf, LazFileUtils, Controls, Graphics, u_Lapka;

const LSHAKES_CONST = 10; //ile razy ma lshakes potrzasnac niewlasciwym obrazkiem (powinna byc parzysta - kosmetyka)

type

  { TMojImage }

  (* ********************************************************************************************************************************* *)
  (* MojImage - obrazek z identyfikatorem, mający możliwosc wystawiania 'Lapki' (podpowiedzi), jednoznacznie identyfikowany przez ID,  *)
  (* co umożliwiać będzie jego identyfikacje z obrazkiem zgadywanym/wzorcowym na gorze ekranu. Obrazek można przesuwać -coNaMouse[...] *)
  (* ********************************************************************************************************************************* *)

  TMojImage = Class(TImage)

    class procedure RozmiescObrazki_v2(tab: array of TMojImage; Sek:array of SmallInt);
    class function IleWierszy(ileObrazkow: SmallInt): SmallInt;                 //w ilu wierszach rozmiescic obrazki
    class function IleKolumnWWierszu(ileObrazkow, wiersz: SmallInt): SmallInt;  //po ile obrazkow ma przypadac na wiersz 1, a ile na wiersz 2

    //Na mechanizm nadawania jednoznacznego id obrazka:
    private FliczbaOb : Integer; static;
    public class property liczbaOb : Integer read FliczbaOb;

    //na mechanizm oznaczania obrazka, ktory wszedl do Obszaru Gornego OG:
    private FinArea : Boolean;
    procedure setInArea(AValue: Boolean);
    public property inArea : Boolean read FinArea write setInArea;

    //Na mechanizm wystawiania Lapki;
    private FJestLapka : Boolean;
    procedure setJestLapka(aValue: Boolean);
    public property JestLapka : Boolean read FJestLapka write setJestLapka;

    private
      Lapka1, Lapka2 : TLapka;      //Lapka/Podpowiedz wystawiana przez Obrazek (jesli jest to wlasciwy obrazek przebywajacy w OG)
//      Lapka2 : TLapka;      //na potrzebt WybierzObrazek - 2-ga Lapka - (dwie) Lapki ("biala" i "czarna", żeby bylo widać na bialym tle ramki na obrazek) 2019.12.25
      mTimer: TTimer;      //Timer na odsuwanie od LG Ramki blednie polozonego obrazka
      lKrok : SmallInt;    //licznba Krokow /index mTimer'a
      TBlink: TTimer;      //Timer do mrugania 'Wskazem'
      lShakes: SmallInt;    //liczba mrugniec TBlink timerem (potem nie mruga, tylko stale wyswietlanie)
      TShake : TTimer;     //Timer do 'wstrzasania' obrazkiem; powiazany z pokazWskaz();
      shakeSwitch : Boolean; //zeby wracal na miejsce przy wstrzasaniu
      poz,poz2:TPoint;   //uzywane przy przesuwaniu obrazkow
      dx,dy : SmallInt;  //przesuniecie obrazka
      idOb  : Integer;   //na identyfikacje (powiazanie obrazek_'zgadywany' <--> obrazek_pod_kreska)
      Xo,Yo : Integer;   //inicjalne polozenie obrazka w OD (naliczone przez proc. rozmieszczajaca RozmiescObrazki_v2()
      plikNzw : string;  //nazwa pliku z obrazkiem; do wykorzystania przy ewentualnym odgrywaniu dzwieku (if any) i LPodpis (w podpisie jesli trzeba)
      arrowHead,
      arrowShaft:TShape;  //do wygenerowania strzalki/'wskazu' pod obrazkiem, wskazujacej, ze obrazek powinien zostac wyprowadzony z OG
      zeWskazem: Boolean; //Czy po zakonczeniu Potrzasania do obrazka ma byc doklejony Wskaz
      mamWskaz : Boolean; //czy obrazek ma doklejony Wskaz pod spodem
      LPodpis  : TLabel;  //podpis pod obrazkiem, pokazywany (opcjonalnie) na FOperacje



      function DajMaxymWymiarPoziomy(ileObrazkow:Integer):Integer;
      function DajMaxymWymiarPionowy(ileObrazkow:Integer):Integer;

      function ObrazekJestWOkregu(const Obrazek:TMojImage; const widacKolo: Boolean):Boolean; //Czy lewy gorny rog obrazka wszedl w obreb podpowiedzi(Okrego wystawianego przez Ramke)

      procedure coNaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
      procedure coNaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure coNaMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure coNaMouseLeave(Sender: TObject);
      procedure coNaMouseEnter(Sender: TObject);
      procedure odsunOdRamki(); //Odsuniecie obrazka od LG Ramki w dol(jesli dziecko polozy go nieprtawidlowy obrazek - wodotrysk...)
      procedure Odjedz();       //wywoluje mTimer na odjezdzanie
      procedure coNaTimer(Sender:Tobject);
      procedure coNaBlinkTimer(Sender:Tobject);
      procedure coNaTShakeTimer(Sender: TObject); //wstrzasanie obrazkiem
      procedure PotrzasnijPrivate();   //Wstrzasniecie (shake) obrazkiem, kiedy znajdzie sie w OG, a tam juz jest ten prawidlowy

      procedure dodajWskazNaEtapieKonstruktora();   //bedzie pokazywana strzalka pod obrazkiem, jezeli w OG oprocz wlasciwego obrazka sa jeszcze inne - sugestia, zeby sciagnac w dól
      procedure dodajPodpisNaEtapieKonstruktora();  //bedzie pokazywany ewentualny podpis pod każdym obrazkiem w OD -> 2020-04-28

    protected
    procedure Paint; override; //zeby narysowac obramowanie - technikalia...proby...  uwaga na Invalidate();

    public
        constructor WlasnyCreate_ze_Skalowaniem(var Zrodlo:TFileListBox; Index:Integer; ileRozmieszczam:SmallInt); //tworzenie obrazka proporcjonalnego do fizycznego źródla (ten sam aspect ratio)
        constructor WlasnyCreate_Generic(); //na wykreowanie 1 szt. TImWzorzec (obrazek-wzorzec na górze ekranu w OG)
        destructor  Destroy(); override;
        destructor  Destructor_Generic();  //do likwidacji 1 szt. TImWzorzec
        function getIdOb():SmallInt;
        procedure UstawKolorObramowaniaLapki(BiezaceTlo:TColor);
        procedure WlaczHandlery();
        procedure BlokujHandlery();
        function getXo():SmallInt;
        function getYo():SmallInt;
        procedure setXo(wart:SmallInt);
        procedure setYo(wart:SmallInt);
        function DajEwentualnyPlikWav():String;
        procedure PokazWskaz();
        procedure ZdejmijWskaz();
        procedure PotrzasnijBezWskazu();
        procedure PotrzasnijZeWskazem();
        procedure WypozycjonujLPodpis();     //zapewnia pozycje LPodpis pod obrazkiem
        procedure PokazUkryjLPodpis(czyPokazac:Boolean);

  End;  //TMojImage



implementation
uses u_operacje, u_ramka;

{ TMojImage }


procedure TMojImage.setInArea(AValue: Boolean);
begin
  if FinArea=AValue then Exit;
  FinArea:=AValue;
end;

procedure TMojImage.setJestLapka(aValue: Boolean);
(* Generowanie Lapek-podpowiedzi *)
(* Generowanie 2-ch(!) Lapek, bardzo blisko siebie - 1 piksel odstepu.                                      *)
(* 2 lapki, zeby po najechaniu na ramke ktoras byla widoczna na jej tle, dzieki swoim kolorom (patrz nizej) *)
(* Lapki maja rozne kolory - Lapka1 ma przeciwny do tla formy; Lapka2 ma przeciwny do tla ramki.            *)
Begin
  if aValue = FJestLapka then EXIT;
  FJestLapka := aValue;
  {}
  if FJestLapka then begin //Zaczynamy mrugac Lapka
    if (Lapka1.Parent = Nil) then begin
      Lapka1.Parent := Self.Parent; //zeby bylo widac, jesli nie ma jeszcze Parenta; {parentem Self-a jest FOperacje)
      Lapka2.Parent := Self.Parent; //j.w.
    end;

    //Lapki maja rozne, "przeciwne" kolory, zeby daly sie zobaczyc na roznych tłach (Formy i Ramki):
    Lapka1.UstawKolorObramowania(Self.Parent.Color); //przeciwny do tla Formy
    Lapka2.UstawKolorObramowania(Ramka.Brush.Color); //przeciwny do tla Ramki

    //Lapki w odstepie 1 piksela:
    Lapka1.PolozNaXY_i_Wymiaruj(Left-5,Top-5, Width+10,Height+10);
    Lapka2.PolozNaXY_i_Wymiaruj(Left-6,Top-6, Width+12,Height+12);

    Lapka1.SendToBack(); //bo inaczej Lapka przykrywa obrazek i nie da się przesuiwac obrazka ...
    Lapka2.SendToBack(); //j.w.

    Lapka1.Mrugaj();
    Lapka2.Mrugaj();
  end
  else begin      //chowamy Lapke
    Lapka1.Zgas();
    Lapka2.Zgas();
  end;
End;

procedure TMojImage.coNaMouseLeave(Sender: TObject);
Begin
   Cursor:=crDefault;
End;

procedure TMojImage.coNaMouseEnter(Sender: TObject);
begin
  if not TShake.Enabled then
    Cursor:=crHandPoint;
end;


type
  TGraphicControlAccess = class(TGraphicControl)
end;

procedure TMojImage.Paint;
begin
  inherited Paint();
  with TGraphicControlAccess(Self).Canvas do  begin
    Brush.Style := bsClear;
    //Pen.Color   := clRed;
    Pen.Color   := clGray;
    Rectangle(ClientRect);
  end;
end;


procedure TMojImage.coNaMouseMove(Sender: TObject; Shift: TShiftState; X,  Y: Integer);
Begin
  If ssLeft in Shift then Begin  //LewyKlawiszMyszy wscisniety
    //ponizsze 2 instrukcje na wszelki wypadek, bo wskaz czasami zostaje podczas przesuwania, pomimo zdejmijWskaz() na OnMouseDown
    //arrowHead.Visible :=False;
    //arrowShaft.Visible:=False;
    //Ruch Obrazkiem
    GetCursorPos(poz2);
    dx := (poz2.x - poz.x);
    Left := left + dx;  //obrazka=Image1 ruszac nie trzeba, bo jest osadzony na PObrazek
    dy := (poz2.y - poz.y);
    Top:= Top  + dy;

    //"Przeciaganie"/pozycjonowanie podpisu pod obrazkiem:
    //LPodpis.Left := Left;
    //LPodpis.Top  := Top + Height;
    WypozycjonujLPodpis();
    LPodpis.BringToFront(); //kosmetyka - zeby nie byl zaslaniany przez inne obrazki

    //ruch Lapka 'obrazkową':
    if JestLapka then begin
      Lapka1.Left:=Lapka1.Left+dx;
      Lapka1.Top :=Lapka1.Top+dy;

      Lapka2.Left:=Lapka2.Left+dx;
      Lapka2.Top :=Lapka2.Top+dy;

    end;

    //2020.01.14 - blokowanie wyjscia poza bande (ekran):
    //lewa i prawa banda:
    If (Left<0) or ((Left+Width)>(FOperacje.Left+FOperacje.Width)) then begin
      Left := Left - dx;
      LPodpis.Left := Left + 2;  //kosmetyka
      //zeby Lapka zobrazowala sie nie przesunieta (if any):
      if JestLapka then begin
        JestLapka:=false;
        JestLapka:=true;
      end;
    End;
    //gorna i dolna banda:
    IF (Top<0) or ((Top+Height)>(FOperacje.Top+FOperacje.Height)) then begin
      Top := Top - dy;
      if JestLapka then begin
        JestLapka:=false;
        JestLapka:=true;
      end;
    End;
    //koniec blokowania wyjscia poza bande

    {}
    GetCursorPos(poz);
  end;
End;

procedure TMojImage.coNaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Begin
  Self.ZdejmijWskaz();  //zdjecie strzalki spod obrazka (if any):
  GetCursorPos(poz);    //niezbedne do prowadzenia Obrazka po ekranie
  Self.BringToFront();
End;

procedure PorzadkujEkranPoZwyciestwie();
(* ************************************************************************** *)
(* Obrazki, oprócz zwycięskiego, zostaja polozone na swoje pierwotne miejsca. *)
(* Przywracane sa klawisze nawigacyjne, zeby mozna bylo przejsc do nast.cwicz.*)
(* Odgrywana jest Nagroda.                                                    *)
(* ************************************************************************** *)
var i:SmallInt;
Begin
With FOperacje do begin
  BPodp.Visible := False; //zeby NIC zbednego nie pozostalo na ekranie (cieszymy sie Zwyciestwem!)
  {}
  Timer5sek.Enabled := False;  //jezeli bylo automatyczne granie, to zatrzymujemy
  GrajDing(0);
  DajNagrode(); //wewnatrz opoznienie ze wzgledu na Ding //MPlayer.Play(tadaPath,1);
  {}
  for i:=1 to TMojImage.liczbaOb do begin
    tabOb[i].inArea := False;
    tabOb[i].BlokujHandlery();
    tabOb[i].Cursor := crDefault;
    if tabOb[i].getIdOb()<>idWylos then begin //nie przemieszczamy zwycieskiego obrazka, bo on lezy w Ramce na gorze i to jest ok
      tabOb[i].Left := tabOb[i].getXo();
      tabOb[i].Top  := tabOb[i].getYo();
    end;
    tabOb[i].WypozycjonujLPodpis();
  end;
  //
  Sprawdzacz.Resetuj();
  //Pokazanie klawiszy nawigacyjnych:
  TimerKlawisze.Enabled:=True;
End;  //With
End; (* Procedure *)

function TMojImage.ObrazekJestWOkregu(const Obrazek: TMojImage; const widacKolo: Boolean): Boolean;
(* ************************************************************************************** *)
(* Czy lewy gorny rog Obrazka wszedl w obreb podpowiedzi(okregu wystawianego przez Ramke) *)
(* Uzywana przy okreslaniu Zwyciestwa lub blednego polozenia obrazka przez dziecko.       *)
(* Jezeli nie ma podpowiedzi (Lapki), to ten okreg zakladam jest o polowe mniejszy.       *)
(* ************************************************************************************** *)
var R : SmallInt;  //srodek i promien okregu Lapki - dla uproszczenia zapisow
Begin
  R := Ramka.LR; //promien Lapki; Lapki moze nie byc widac, ale zachowujemy sie jak by byla
  if NOT widacKolo then begin             //jak nie ma Lapki, to pomniejszamy ten 'wirtualny' promien - lepszy efekt,
    if TMojImage.liczbaOb in [1..8] then  //ale pomniejszamy tylko wtdy, kiedy obrazki dostatecznie wielkie, bo inaczej problemy/niejedniznacznosc...
      R := R div 2;
  end;
  With Ramka do begin
    if (sqr(LXo-Obrazek.Left)+sqr(LYo-Obrazek.Top)) < sqr(R) then     //z rownania okregu
      Result := True
    else
      Result := False;
  end;
End;

{
procedure TMojImage.coNaMouseUp(Sender: TObject; Button: TMouseButton;  Shift: TShiftState; X, Y: Integer);
(* ****************************************************************************** *)
(* Sprawdzenie aktualnego elementu (gdzie jest itp); Jesli trafienie - ZWYCIESTWO *)
(* ****************************************************************************** *)
var o : SmallInt;    //indeks na Obrazki
    i : SmallInt;    //indeks pomocniczy
Begin
  {}
  Sprawdzacz.Sprawdz(Self);  //sprawdzenie, czy upuszczony obiekt wyladowal w OG + zliczanie obrazkow w OG
  //if Sprawdzacz.IlewObsz=0 then EXIT; //zeby nie narobic sie niepotrzebnie...
  {}
  If Sprawdzacz.IlewObsz=1 then begin
    //Okreslam, ktory Obrazek jest w OG (bo nie musi to byc Self(!) )
    for o:=1 to liczbaOb do begin
      if FOperacje.tabOb[o].inArea then
        BREAK;  //w 'o' indeks Obrazka z OG
    end;
    if FOperacje.tabOb[o].idOb=FOperacje.idWylos then begin  //to ten obrazek, o ktory chodzi - wystawiamy Lapke(i) (if any):
      Ramka.JestLapka := FParametry.CBPodp.Checked;                  //Lapka 'ramkowa'
      FOperacje.tabOb[o].JestLapka:=FParametry.CBPodp.Checked;       //Lapka 'obrazkowa'
    end
    else begin
      //w OG jest tylko 1, ale NIEWLASCIWY obrazek:
      if ObrazekJestWOkregu(FOperacje.tabOb[o], Ramka.JestLapka) then begin
        FOperacje.GrajZle(0);     //sygnalizacja 'ZLE', jesli dziecko usiluje dopasowac zly obrazek do Ramki
        FOperacje.GrajNagane(1);  //'nagana-zachęta' do dalszych prob
        self.odsunOdRamki();
      end;
      EXIT;                    //wychodzimy, bo w OG inny obrazek niz ten, co trzeba
    end
  end
  Else begin//w OG inna liczba niz 1 obrazkow - wylaczam ewentualne Lapki z Ramki i Obrazka:
    Ramka.JestLapka:=False;
    for i:=1 to TMojImage.liczbaOb do  //wylaczenie (ewentualnej) z Obrazka (przelatuje po wszystkich, bo nie wiem ktory (if any) ma Lapka)
      if FOperacje.tabOb[i].JestLapka then
        FOperacje.tabOb[i].JestLapka := False;

    {2018-03-25 wskazanie obrazka, ktory trzeba wycofac w dol z OG:}
    WITH FOperacje do begin
      If Sprawdzacz.JestWlasciwy then begin //wskazujemy tylko wtedy, kiedy w OG juz umiejscowiony jest wslasciwy obrazek
        if TMojImage(Sender).idOb<>tabOb[nrWylos].idOb then //zeby nie potrzasac wlasciwym
          TMojImage(Sender).PotrzasnijPrivate()
        else begin   //doklejenie wskazu wszystkim inny z OG (jesli nie maja)
          for i:=1 to TMojImage.liczbaOb do begin
            if tabOb[i].inArea then //zeby nie doklejac tym z OD
              if i<>nrWylos then    //zeby nie doklejac wlasciwemu
                tabOb[i].PokazWskaz();
          end; //for
        end;
        {
        for i:=1 to TMojImage.liczbaOb do begin
          if FOperacje.tabOb[i].inArea then begin
            if i<>FOperacje.nrWylos then begin //zeby nie wskazywac tego wlasciwego
              if not bylShake then begin  //zeby danym obrazkiem wstrzasac tylko raz w danym rozdaniu
                FOperacje.tabOb[i].Potrzasnij();
              end
              else
                PokazWskaz();
            end;
          end;
        end; //for
        }
      End;
    End; //WITH
    {2018-03-25 - koniec}

    EXIT;  //bo za duzo obrazkow w OG
  End;

  {Jezeli sterowanie dojdzie tutaj, to 'czysta' sytuacja - jeden poprawny Obrazek w OG:}
  //Czy Obrazek dostatecznie blisko lewego gornego rogu Ramki:
  With FOperacje do begin  //With dla uproszczenia zapisow
    //Warunek: Lewy Gorny róg obrazka w prostokącie Lapce 'ramkowej' (mniej wiecej)
    if ObrazekJestWOkregu(tabOb[o], Ramka.JestLapka) then begin     //ZWYCIESTWO!!!
         //Dosuniecie obrazka w Ramke:
         tabOb[o].Left := Ramka.Left;
         tabOb[o].Top  := Ramka.Top;
         //zeby nie mrugal pod obrazkiem - czasem widac przy malym obrazku... :
         Ramka.JestLapka   := False;
         tabOb[o].JestLapka:= False;
         PorzadkujEkranPoZwyciestwie();
         EXIT;  //dalej sprawdzac nic nie trzeba :)
      end;
  End; //With

End; (* coNaMouseUp *)
}
procedure TMojImage.coNaMouseUp(Sender: TObject; Button: TMouseButton;  Shift: TShiftState; X, Y: Integer);
var o:Byte; //indeks na obrazki
Begin
  Sprawdzacz.Sprawdz(Self);  //--> sprawdzenie, gdzie wylądowal upuszczony obiekt + zliczanie obrazkow w OG
  {}
  WITH FOperacje do Begin //dla uproszczenia zapisow

    //Jezeli to byl ruch 'Do' lub 'W' Obszarze DOLNYM OD:
    If not Self.inArea then begin  //z OG zabrano wlasciwy obrazek - gaszę, jego lapke
      if Self.JestLapka then begin;
        Self.JestLapka :=False; //jesli z OG zabrano wlasciwy obrazek, gasze Lapki
        Ramka.JestLapka:=False;
        EXIT;
      end;
      if Sprawdzacz.IlewObsz<>1 then
        EXIT;

      {Kod ponizej i if'a powyzej mozna by wyrzucic - kwesta gustu - bo to jest mruganie samotnym poprawnym obrazkiem...}
      //Jezeli po zabraniu zlego obrazka z OG w OG pozostal JEDEN i to Prawidlowy obrazek - wlaczam na nim podpowiedz/Lapki (jesli dozwolone):
      if not Sprawdzacz.JestWlasciwy then
        EXIT
      else begin  //wlaczam (ewentualnie) Lapki
        tabOb[nrWylos].JestLapka := FParametry.CBPodp.Checked;
        Ramka.JestLapka := FParametry.CBPodp.Checked;
        EXIT;
      end;
    End;  //If
    {kobiec mrugabia samotnym poprawnym obrazkiem - mozna pominac taka funkcjonalnosc - patrz uwaga wyzzej}

    {TO byl ruch 'do' OG lub 'w' OG:}

    //1.(jesli) To byl ruch niewlasciwym obrazkiem:
    if Self.idOb<>tabOb[nrWylos].idOb then begin
      GrajZle(0);
      Self.PotrzasnijZeWskazem();
      //jezeli w OG jest juz wlasciwy obrazek, to wylaczam jego Lapke (a jak go tam nie ma, to nic sie nie stanie...):
      tabOb[nrWylos].JestLapka:= False;
      Ramka.JestLapka         := False;
      //jesli proba dopasowania zlego obrazka do Ramki:
      if ObrazekJestWOkregu(Self, Ramka.JestLapka) then begin
        DajNagane();  //'nagana-zachęta' do dalszych prob
        //self.odsunOdRamki();
      end;
      EXIT;
    end;

    //2.To ruch wlasciwym obrazkiem (bo sterowanie doszlo az tutaj):
    //wystawienie Lapki (ewentualne); lapke wystawiam tylko jezeli w OG jest 1 (i to wlasciwy) obrazek:
    if Sprawdzacz.IlewObsz=1 then begin
      Ramka.JestLapka := FParametry.CBPodp.Checked;                  //Lapka 'ramkowa'
      Self.JestLapka  := FParametry.CBPodp.Checked;                  //Lapka 'obrazkowa'

      //Ramke wysylam w tlo, zeby bylo na niej widac Lapke 2020-01-04:
      //doswiadczalne - podobna instrukcja w konstruktorze Lapki jest niewystarczajaca - ale wystarczy na BPodp.onClick....
      Ramka.SendToBack();


    end; (* tu jeszcze nie ma Exita, bo moze Zwyciestwo? - patrz nizej*)

    //Warunek: Lewy Gorny róg obrazka w prostokącie Lapce 'ramkowej' (mniej wiecej)
    if ObrazekJestWOkregu(Self, Ramka.JestLapka) and (Sprawdzacz.IlewObsz=1) then begin     //ZWYCIESTWO!!!
      //Dosuniecie obrazka w Ramke:
      Self.Left := Ramka.Left;
      Self.Top  := Ramka.Top;
      //zeby nie mrugal pod obrazkiem - czasem widac przy malym obrazku... :
      Ramka.JestLapka := False;
      Self.JestLapka  := False;
      PorzadkujEkranPoZwyciestwie();
      EXIT;  //dalej sprawdzac nic nie trzeba :)
    end;

    //Jezeli sterowanie doszlo az tutaj, to znaczy, ze ruch byl WLASCIWYM obrazkiem, ale w OG sa jeszcze inne, niewlasciwe. Potrzasamy jednym z nich:
    if Sprawdzacz.IlewObsz>1 then begin
      for o:=1 to FliczbaOb do begin
        if tabOb[o].inArea and (o<>nrWylos) then begin
          tabOb[o].ZdejmijWskaz();
          tabOb[o].PotrzasnijZeWskazem();
          EXIT;
        end;
      end;
    end;

  END; //WITH
End; (* CoNAMouseUp*)



destructor TMojImage.Destroy();
(* uwaga - proba zwolnienia poz, poz2 powoduje runtime error - więc poz, poz2 wyrzucam... *)
Begin
  dec(FliczbaOb);
  FreeAndNil(mTimer);
  FreeAndNil(TBlink);
  FreeAndNil(arrowHead);
  FreeAndNil(arrowShaft);
  FreeAndNil(LPodpis);
  Lapka1.Destroy;
  Lapka2.Destroy;
  inherited destroy;
End;

destructor TMojImage.Destructor_Generic();
(* DO likwidacji obrazka-wzorca (bo nie ma on Lapki i innych *)
(* (tworzony by przez prosty konstruktor) *)
Begin
  inherited Destroy;
End;


function TMojImage.getIdOb(): SmallInt;
begin
  Result := idOb;
end;


procedure TMojImage.UstawKolorObramowaniaLapki(BiezaceTlo: TColor);
(* tylko Po zmianie tla na FParametry trzeba uczynic Lapke widzialną(!) *)
Begin
  Lapka1.UstawKolorObramowania(BiezaceTlo);
  Lapka2.UstawKolorObramowania(Ramka.Brush.Color);

  //Lapka 2 - przeciwna nie do tla Formy, ale do tla Ramki, czyli jak tlo Formy... 2019.12.25 :
  //mozna tak: Lapka2.Pen.Color := JakieJestTlo;
  {mozna tak (b.elegancko):}
  //Lapka2.Pen.Color := clRed;//skib_InvertColor(Ramka.Brush.Color);
  {koniec 2019.12.25}



End;

function TMojImage.getXo(): SmallInt;
begin
  Result := Xo;
end;

function TMojImage.getYo(): SmallInt;
begin
  Result := Yo;
end;

procedure TMojImage.setXo(wart: SmallInt);
begin
  Xo:=wart;
end;

procedure TMojImage.setYo(wart: SmallInt);
begin
  Yo:=wart;
end;

function TMojImage.DajEwentualnyPlikWav(): String;
var plik:string;
    pocz:byte;
Begin
  plik  := ExtractFileNameOnly(plikNzw);
  //Ewentualna rybka (01) -> rybka:
   pocz := pos(' (',plik);   //spacje olewam (bardziej ogolne...)
   if (pocz<>0) then begin
     plik:=Copy(plik,0,pocz-1);
   end;
   {}
  plik  := plik+'.wav';
  Result:= plik;
End;



constructor TMojImage.WlasnyCreate_ze_Skalowaniem(var Zrodlo:TFileListBox; Index:Integer; ileRozmieszczam:SmallInt);
(* ******************************************************************************************************************************************* *)
(* Kreowanie obrazkow tak, zeby w kontrolce obejmujacej (TImage) byla zachowana proporcja bokow jak w obrazku fizycznym (ten sam aspect ratio) *)
(* Maxymalny poziomy rozmiar (a)kontrolki obejmujacej (TImage) determinowany jest przez liczbe obrazkow na dysku (zakres 1..MAX_OBR_OD)        *)
(* Maxymalny rozmiar pionowy (b) determinowany jest przez j.w. (liczba obrazkow) oraz wysokosc Obszaru Dolnego OD                              *)
(* Ustalany jest wymiar obtrazkow (Width, Height), ale nie ich polozenie. Polozenie ustala proc. klasowa RozmiescObrazki_v2()                  *)
(* Parametry: Zrodlo:kontrolka na FParametry zawierajaca pliki obrazkow;                                                                       *)
(*            Index:index kolejnego pliku z obrazkiem w kontrolce Zrodlo                                                                       *)
(*            ileRozmieszczam : ile jest w sumie obrazkow do rozmieszczenia w OD  (ma wplyw na wymiarowanie)                                   *)
(* ******************************************************************************************************************************************* *)

var plik: string;              //plik czytany z dysku
    x,y,
    MaxPoziom,MaxPion : Integer;  //na zwymiarowanie obrazka
    pion,poziom : Real;           //j.w.
    proc : Real;                  //na ewentualne pomniejszenie jezeli z LPodpis
    lOparam : SmallInt;   //liczba obrazkow okreslona przez usera na FParametry (poziom trudnosci) - nie mozna braz TmojIMage.liczbaOb; bo to jest jeszcze nie okreslone

Begin

  inherited Create(nil);

  inc(FliczbaOb);     //liczba obiektow w Klasie
  idOb  := liczbaOb;  //nadanie unikalnego identyfikatora
  inArea:= False;     //bo kreowany obiekt wyladuje w OD (Obszarze Dolnym)

  {Kreowanie Lapki obrazkowej:}
  Lapka1 := TLapka.WlasnyCreate(stRectangle);
  Lapka2 := TLapka.WlasnyCreate(stRectangle);

  //Ladowanie pojedynczego obrazka:
  //w niewidzialnej kontrolce ustawiam sie na tym pliku
  plik := Zrodlo.Items[Index];
  try  //bo wiem z doswiadczenia, ze czasami nie chcialo pokazywac na Win7 (profMarcin)
    Self.Picture.LoadFromFile(SciezkaZasoby + plik);     //pokazuje plik, na ktorym sie ustawilem
    plikNzw := plik; //do wykorzystania przy graniu
  except
  end;


  {Rozpoczynam wyliczanie wymiarow obrazka. Rozwazam prostokat o bokach MaxPoziom  i MaxPion :}
  MaxPoziom := DajMaxymWymiarPoziomy(ileRozmieszczam); //nie ma prawa byc dluzszy niz (bo inne moga sie nie zmiescic)
  MaxPion   := DajMaxymWymiarPionowy(ileRozmieszczam); //j.w.

  //FIZYCZNE wymiary obrazka:
  x:=Self.Picture.Width;
  y:=Self.Picture.Height;

 {1. Zakladamy, ze skalujac obrazek daje sie go zrownac do poziomego boku MaxPoziom: }
  pion:=MaxPoziom*(y/x);
  if pion < MaxPion then begin
    Self.Width :=Trunc(MaxPoziom);
    Self.Height:=Trunc(pion);
  end
 {2. nie daje sie zrownac do poziomego boku, czyli rownamy do pionowego boku MaxPion: }
  else begin
    poziom := MaxPion*(x/y);;
    Self.Width :=Trunc(poziom);
    Self.Height:=Trunc(MaxPion);
  end;

  //Ewentualne pomniejszenie obrazka do 2/3 wyliczonego wymiaru:
  //UWAGA - kohezja !!!
  if FParametry.CBShrink.Checked then begin
    Self.Width :=2*(Self.Width  div 3);
    Self.Height:=2*(Self.Height div 3);
  end;

  Self.Proportional:=True;
 {* KONIEC wymiarowania *}


  //dolozenie Timeraow:
  mTimer := TTimer.Create(nil);
  mTimer.Enabled := False;
  mTimer.Interval:= 30;
  mTimer.OnTimer:=@coNaTimer;

  TBlink := TTimer.Create(nil);
  TBlink.Enabled := False;
  TBlink.Interval:= 300;
  TBlink.OnTimer:=@coNaBlinkTimer;

  TShake := TTimer.Create(nil);
  TShake.Enabled  := False;
  TShake.Interval := 20;
  lShakes := LSHAKES_CONST;
  shakeSwitch:=False;
  TShake.OnTimer:=@coNaTShakeTimer;

  //DOLOZENIE STRZALKI (na razie niewidzialnej) W DOL:
  Self.dodajWskazNaEtapieKonstruktora();
  {}
  //2020-04-28 - na sugestie A.Bathis -patrz nizej:
  //Teraz obsluga przypadku, gdy mamy podpisy - troche zmniejszam, zeby ostatni rzad
  //nie wychodzil poza dol FOperacje, bo moze byc nie widac takiego podpisu (heurystycznie....):
  if FPArametry.CBPictNames.Checked then begin //UWAGA - KOHEZJA
    proc := 0.95;
    lOparam := StrToInt(FParametry.EPoziom.Text);
    //Na laptoptach 1366x768 0.95 moze byc za duzo, ostatni rzad ma niewidoczne Lpodis'y ... :
    if (IleWierszy(lOparam)=3) and (Screen.Height<=768) then proc := 0.50;   //0.90
    if (IleWierszy(lOparam)=3) and (Screen.Height<=720) then proc := 0.45;   //0.85
    self.Height:=trunc(proc*self.Height);
    self.Width :=trunc(proc*self.Width);
  end;
  {}
  Self.dodajPodpisNaEtapieKonstruktora();
  {}
  WlaczHandlery();
End; (* WlasnyCreate_ze_Skalowaniem() *)


constructor TMojImage.WlasnyCreate_Generic();
(* Stosowany tylko do wykreowania 1 szt. TImWzorzec (obrazek-wzorzec na górze ekranu)  *)
(* Uwaga - nie zwieksa property klasowego liczaOb (i nie powinien!!!)                  *)
(* *********************************************************************************** *)
Begin
  inherited Create(nil);
End; (* WlasnyCreate_Generic() *)


procedure TMojImage.WlaczHandlery();
Begin
  OnMouseDown  := @coNaMouseDown;
  OnMouseMove  := @coNaMouseMove;
  OnMouseEnter := @coNaMouseEnter;
  OnMouseLeave := @coNaMouseLeave;
  OnMouseUp    := @coNaMouseUp;
End;


procedure TMojImage.BlokujHandlery();
Begin
  OnMouseMove :=nil;
  OnMouseDown :=nil;
  OnMouseUp   :=nil;
  OnMouseLeave:=nil;
  OnMouseEnter:=nil;
End;

class function TMojImage.IleWierszy(ileObrazkow: SmallInt): SmallInt;
(* ********************************************************************************************* *)
(* Jest ileObrazkow do rozmieszczenia w OD; Jaka powinna byc liczba wierszy?                     *)
(* Zakladam, że ileObrazkow in [1..MAX_OBR_OD] (na poczatek....) ; obrazki max. w 3-ch wierszach *)
(* ********************************************************************************************* *)
Begin
  if ileObrazkow in [1..4] then
    Result := 1
  else
    if ileObrazkow in [5..10] then
      Result := 2
    else
      Result := 3; //jest 11,12,13,14 lub 15 obrazkow, wtedy 3 wiersze

  //A teraz podrasowanie - przypadek, gdy chcemy aby 4 obrazki byly w 2-ch wierszach:
  //UWAGA - KOHEZJA !!!
  if (ileObrazkow=4) and FParametry.RB2W.Checked then
    Result:=2;
End;

class function TMojImage.IleKolumnWWierszu(ileObrazkow, wiersz: SmallInt): SmallInt;
(* **************************************************************************************** *)
(* Jest ileObrazkow do rozmieszczenia w OD; Jaka powinna byc liczba kolumn w DANYM wierszu? *)
(* Zakladam, że ileObrazkow in [1..MAX_OBR_OD] (na poczatek....) ; obrazki max. w 2-ch rzedach po 5 *)
(* **************************************************************************************** *)
Begin
  if IleWierszy(ileObrazkow)=1 then begin
    Result := ileObrazkow;
    Exit;
  end;
  Case ileObrazkow of
    4: Result:=2;
    5: if wiersz=1 then Result:=3 else result:=2;
    6: Result:=3;
    7: if wiersz=1 then Result:=4 else Result:=3;
    8: Result:=4;
    9: if wiersz=1 then Result:=5 else Result:=4;
   10: Result:=5;
   11: if wiersz in [1,2] then Result:=4 else Result:=3;
   12: Result:=4; //bo 3 wiersze X 4 obrazki w kazdym
   13: if wiersz in [1,2] then Result:=5 else Result:=3;
   14: if wiersz in [1,2] then Result:=5 else Result:=4;
   15: Result:=5;
  End;
End;  (* Function *)



function TMojImage.DajMaxymWymiarPoziomy(ileObrazkow: Integer): Integer;
(* **************************************************************************************** *)
(* Jest ileObrazkow do rozmieszczenia w OD; Jaka powinna byc maxymalna szerokosc obrazka?   *)
(* Zakladam, że ileObrazkow in [1..MAX_OBR_OD] (na poczatek....) ; obrazki max. po 5 w rzedzie *)
(* **************************************************************************************** *)
var wLOb    : SmallInt;  //'wewnetrzna' liczba obrazkow; pomocnicza
    imWidth : Integer;   //pomocnicza, dla czytelnosci
Begin
  if IleWierszy(ileObrazkow) = 1 then begin
    wLOb := IleKolumnWWierszu(ileObrazkow,1);
  end
  //przypadek 2 i/lub 3 wierszy - wystarczyc sprawdzic sytuacje tylko w 2-ch gornych wierszach (bo 3-ci nigdy nie dluzzszy niz one):
  else begin
    wLOb := max(IleKolumnWWierszu(ileObrazkow,1) , IleKolumnWWierszu(ileObrazkow,2));
  end;
  imWidth := Trunc(4*FOperacje.Width/(5*wLOb+1));
  Result := imWidth;
End;


function TMojImage.DajMaxymWymiarPionowy(ileObrazkow: Integer): Integer;
(* Opis - patrz funkcja DajMaxymWymiarPoziomy(), tyle że dotyczy Pionu *)
var imHeight : Integer;   //pomocnicza, dla czytelnosci
Begin
  if IleWierszy(ileObrazkow)=1 then  begin //jesli daje sie zmiescic w jednym wierszu, to obrazek moze byc wysoki w pionie:
    imHeight := 4*(FOperacje.Height - FOperacje.SLinia.Top) div 5;  // cztery piąte dostepnej wysokosci - bo wszystko w zmieszczę w 1-dnym wierszu
  end
  else begin
   if IleWierszy(ileObrazkow)=2 then  //mamy 2 wiersze
     imHeight := 2*(FOperacje.Height - FOperacje.SLinia.Top) div 5  // dwie piąte dostepnej wysokosci - zeby zmiescic w 2-ch wierszach
   else   //mamy 3 wiersze
     imHeight := 1*(FOperacje.Height - FOperacje.SLinia.Top) div 4;  // jedna czwarta dostepnej wysokosci - zeby zmiescic w 3-ch wierszach
  end;
  Result := imHeight;
End; (* Function *)


procedure DostosujSlinieDoJednegoWiersza();
(* *********************************************************************************** *)
(* Wywolywana w sytuacji, gdy jest tylko 1 wiersz i NIE pomniejszone obrazki.          *)
(* Wtedy (duza) Ramka i SpeedBtnGraj moglyby przekroczyc SLinie, wiec Slinie obnizamy. *)
(* *********************************************************************************** *)
var Dx : Integer;
    maxHeight : Integer;
    i : SmallInt;
Begin
  if FParametry.CBShrink.Checked then Exit; //obrazki sa pomniejszane, wiec nie ma co kombinowac...
  {}
  //Jaka jest wysokosc najwyzszego obrazka w wierszu 1-szym (do tej wart. dostosujemy obnizenie SLinii):
  maxHeight := -1;
  With FOperacje do begin //dla uproszczenia zapisu
    for i:=1 to TMojImage.liczbaOb do
     if FOperacje.tabOb[i].Height>maxHeight then maxHeight:=FOperacje.tabOb[i].Height;
    //(ewentualnie) obnizamy SLinie:
    Dx := Ramka.Top+maxHeight - FOperacje.SLinia.Top; //uwaga nie bierzemy Ramka.Height, bo obiektu Ramka jeszcz nie ma lub jest, ale z poprzedniego rozdania
    if Dx >= 0 then begin
      if Dx<34 then Dx:=Dx+20; //kosmetyka nieznaczaca; doswiadczalnie; zeby Ramka nie byla zbyt bliski SLinii
      FOperacje.SLinia.Top := FOperacje.Slinia.Top + Dx;
    end;
  end;
End;

class procedure TMojImage.RozmiescObrazki_v2(tab: array of TMojImage; Sek:array of SmallInt) ;
(* ************************************************************************)
(* Ladne umieszczenie obrazkow w OD. Jesli obrazkow jest 1..4 to 1 wiersz.*)
(* Jesli obrazkow jest 5..10 to 2 wiersze.                                *)
(* Jezel 11..MAX_OBR_OD (czyli de facto 11..15 to 3 wiersze.              *)
(* Obrazki ulozone  ukladach :                                            *)
(*  4 obrazkow -> 2x2                                                     *)
(*  5 obrazkow -> 3x2                                                     *)
(*  6 obrazkow -> 3x3                                                     *)
(*  7 obrazkow -> 4x3                                                     *)
(*  8 obrazkow -> 4x4                                                     *)
(*  9 obrazkow -> 5x4                                                     *)
(* 10 obrazkow -> 5x5                                                     *)
(* 11 obrazkow -> 4x4x3                                                   *)
(* 12 obrazkow -> 4x4x4                                                   *)
(* 13 obrazkow -> 5x5x3                                                   *)
(* 14 obrazkow -> 5x5x4                                                   *)
(* 15 obrazkow -> 5x5x5                                                   *)
(* Uwaga: obrazki sa juz zwymiarowane (WidthxHeight) przez Constructor    *)
(* Parametr Sek[] - sekwencja w jakiej maja byc wyswietlane obrazki z     *)
(* tablicy tab[]; sekwencja najczesciej ustalana losowo                   *)
(* ************************************************************************)
var Top_w1, Top_w2, Top_w3,                 //Top_wiersza[1,2,3]
    sumSzer_w1, sumSzer_w2, Sumszer_w3,     //sumaryczba szerokosc obrazkow w danym wierszu
    freeSpace_w1,freeSpace_w2,freeSpace_w3, //przestrzen nie zajeta przez obrazki, wiersz{1,2]
    odstep_w1, odstep_w2, odstep_w3,        //odstep_miedzy obrazkami w wierszu{1,2]
    maxHeight_w1, maxHeight_w2 : Integer;   //max. wys. obrazka w wierszu 1-szym
    {}
    lo_w1, lo_w2, lo_w3 : SmallInt;    //liczba obrazkow w wierszu 1-szym, 2-gim, 3-cim
    start_w2, start_w3  : SmallInt;    //od jakiego INDEKSU(!) tablicy tab zaczyna sie wierz 2-gi, od jakiego 3-ci
    i : SmallInt;

label KONIEC;
const odSLinii = 20; //odstep gormego rzedu od SLinii
Begin
  FOperacje.SLinia.Top := FOperacje.SLiniaTop_original; //przywracam, jesli zmieniona przez poprzedmie wywolanie ww. procedury
  {}
  //Gdyby mial byc tylko jeden wiersz, to obnizam SLinie, bo przy duzym obrazku Ramka moze na nią zachodzic
  if IleWierszy(TMojImage.liczbaOb)=1 then DostosujSlinieDoJednegoWiersza();
  {}
  {1-szy wiersz z obrazkami, charakterystyka:}
  Top_w1 := FOperacje.SLinia.Top + odSLinii;  //dawniej wyliczany jako: imHeight div 10;
  //if IleWierszy(TMojImage.liczbaOb)=1 then Top_w1:=Top_w1 -(odSLinii div 3); //kosmetyka, zeby bylo widac Podpisy pod Wielkimi obrazkami
  //Obliczanie odstepów pomiedzy obrazkami: szerFOperacje-szerSumarycznaObrazkow dzielone przez liczbaObrazkow:
  sumSzer_w1 := 0;
  lo_w1 := IleKolumnWWierszu(TMojImage.liczbaOb,1);
  for i:= 1 to lo_w1 do sumSzer_w1 := sumSzer_w1 + tab[sek[i-1]-1].Width;  //-1 (minus jedynki) sa dla tego, ze tablice przekazywane w parametrach proc. są indeksowane od 0
  freeSpace_w1 := FOperacje.Width-sumSzer_w1;
  odstep_w1 := freeSpace_w1 div (lo_w1+1);
  {}
  //Rozmieszczenie poziome, 1-szy wiersz:
  tab[sek[0]-1].Top :=Top_w1;
  tab[sek[0]-1].Left:=odstep_w1;
  for i:=1 to lo_w1-1 do begin //uwaga - tablica z parametrow numerowana jest od 0; element 0-wy juz umiescilem - patrz. wiersz wyzej
    tab[sek[i]-1].Top  := Top_w1;
    tab[sek[i]-1].Left := (tab[sek[i-1]-1].Left+tab[sek[i-1]-1].Width) + odstep_w1;
  end;


  IF IleWierszy(TMojImage.liczbaOb) = 1  THEN goto KONIEC;


  {2-gi wiersz z obrazkami, charakterystyka:}
  //Jaka jest najwieszka wysokosc obrazka w wierszu 1-szym:
  maxHeight_w1 := -1;
  for i:=0 to lo_w1-1 do if tab[sek[i]-1].Height>maxHeight_w1 then maxHeight_w1:=tab[sek[i]-1].Height;
  (**)
  Top_w2 := Top_w1 + maxHeight_w1 + trunc(150/100*odSLinii); //bylo 190/100
  //Obliczanie odstepów pomiedzy obrazkami: szerFOperacje-szerSumarycznaObrazkow dzielone przez liczbaObrazkow:
  sumSzer_w2 := 0;
  start_w2 := IleKolumnWWierszu(TMojImage.liczbaOb,1); //bo za chwile bedziemy przegladac/iterowac 2-gi wiersz:
  lo_w2    := IleKolumnWWierszu(TMojImage.liczbaOb,2);
  for i:=start_w2 to start_w2+lo_w2-1 do sumSzer_w2 := sumSzer_w2 + tab[sek[i]-1].Width;
  freeSpace_w2 := FOperacje.Width-sumSzer_w2;
  odstep_w2 := freeSpace_w2 div (lo_w2+1);
  {}
  //Rozmieszczenie poziome, 2-gi wiersz:
  tab[sek[start_w2]-1].Top :=Top_w2;
  tab[sek[start_w2]-1].Left:=odstep_w2;
  for i:=start_w2+1 to start_w2+lo_w2-1  do begin;
    tab[sek[i]-1].Top  := Top_w2;// + imHeight + imHeight div 6;
    tab[sek[i]-1].Left := (tab[sek[i-1]-1].Left+tab[sek[i-1]-1].Width) + odstep_w2;
  end;


  IF IleWierszy(TMojImage.liczbaOb) = 2  THEN goto KONIEC; //(konczymy, bo nie ma wiecej wierszy)


(* ********************************************* *)
  {3-gi wiersz z obrazkami, charakterystyka:}
  //Jaka jest najwieszka wysokosc obrazka w wierszu 2-gim:
  maxHeight_w2 := -1;
  for i:=start_w2 to start_w2+lo_w2 do if tab[sek[i]-1].Height>maxHeight_w2 then maxHeight_w2:=tab[sek[i]-1].Height;
  (**)
  Top_w3 := Top_w2 + maxHeight_w2 + trunc(150/100*odSLinii); //bylo 190/100
  //Obliczanie odstepów pomiedzy obrazkami: szerFOperacje-szerSumarycznaObrazkow dzielone przez liczbaObrazkow:
  sumSzer_w3 := 0;
  start_w3 := IleKolumnWWierszu(TMojImage.liczbaOb,1)+IleKolumnWWierszu(TMojImage.liczbaOb,2); //bo za chwile bedziemy przegladac/iterowac 3-cim wierszu:
  lo_w3    := IleKolumnWWierszu(TMojImage.liczbaOb,3);
  for i:=start_w3 to TMojImage.liczbaOb-1 do sumSzer_w3 := sumSzer_w3 + tab[sek[i]-1].Width;
  freeSpace_w3 := FOperacje.Width-sumSzer_w3;
  odstep_w3 := freeSpace_w3 div (lo_w3+1);
  {}
  //Rozmieszczenie poziome, 3-ci wiersz:
  tab[sek[start_w3]-1].Top :=Top_w3;
  tab[sek[start_w3]-1].Left:=odstep_w3;
  for i:=start_w3+1 to TMojImage.liczbaOb-1 do begin;
    tab[sek[i]-1].Top  := Top_w3;// + imHeight + imHeight div 6;
    tab[sek[i]-1].Left := (tab[sek[i-1]-1].Left+tab[sek[i-1]-1].Width) + odstep_w3;
  end;

(* *************************** *)

KONIEC: //tuz przed wyjsciem zapamietanie wyliczonych wyzej 'porządnych' polozen obrazkow w OD (przyda sie w przyszlosci):
  for i:=0 to TMojImage.liczbaOb-1 do begin
    With tab[sek[i]-1] do begin //dla uproszczenia zapisow
      Xo := Left;
      Yo := Top;
      //I dodatkowo pozycjonowanie podpisu pod obrazkiem:
      WypozycjonujLPodpis();
    end;
  end;

End; (* RozmiescObrazki_v2() *)


procedure TMojImage.WypozycjonujLPodpis();
(* LPodpis ma sie znalez pod obrazkiem, wyrownany(?) do lewej *)
Begin
  Self.LPodpis.Top  := Self.Top+Self.Height;
  //Wyrownany do lewej krawedzi obrazka:
  if FParametry.RBLeft.Checked then
    Self.LPodpis.Left := Self.Left
  else    //Wycentrowany centralnie obrazkiem:
   LPodpis.Left:=Self.Left+ ((Self.Width-LPodpis.Width) div 2);
End;

procedure TMojImage.PokazUkryjLPodpis(czyPokazac: Boolean);
Begin
 LPodpis.Visible := czyPokazac;
End;

procedure TMojImage.Odjedz();
(* Steruje procesem 'odjezdzania' obrazka od LG Ramki poza promien Lapki R *)
var R : SmallInt;     //promien okregu/Lapki
Begin
  //Najpierw odsuwamy od (0,0) na odl. polowy promienia w 1-sza cwiartkę.:
  R := Ramka.LR;              //LR->Lapka.'Radius'
  Self.Left:= Ramka.LXo;// + (R div 2); //(R div 2) + Ramka.Left;  //bo w swiecie 'rzeczywistym', gdzie (0,0) to LG Ekranu trzeba dodac poprawke
  Self.Top := Ramka.LYo;// + (R div 2); //(R div 2) + Ramka.Top;   //j.w.

  Self.lKrok := Trunc(0.7*R)+4 ;//- Ramka.LXo; //liczba krokow 1/2 promienia, bo bedziemy odsuwac po 1 piksele (doswiadczlnie, najlepszy(?) efekt)

  //Jesli sa podpowiedzi, to przestaje nimi mrugac, bo 'siada' wydajnosciowo... :
  if Ramka.JestLapka then begin
    Ramka.PrzestanMrugacLapka();
    With FOperacje do begin
      tabOb[idWylos].Lapka1.NieMrugaj();
      tabOb[idWylos].Lapka2.NieMrugaj();
    end;
  end;

  Self.mTimer.Enabled:=True; //rozpoczecie odsuwania
End;  (* Odjedz() *)

procedure TMojImage.coNaTimer(Sender: Tobject);
Begin
  Self.Left:=Self.Left+1;  //odsuwamy co 2 piksele (doswiadczalnie)
  Self.Top :=Self.Top +1;
  lKrok := lKrok-1;
  if lKrok<1 then begin   //zatrzymanie Timera
    mTimer.Enabled:=False;
    if Ramka.JestLapka then //wznawiamy przerwane mrugania
      Ramka.PonowMruganieLapka();
    With FOperacje do begin
      tabOb[idWylos].Lapka1.WznowMruganie();
      tabOb[idWylos].Lapka2.WznowMruganie();
    end;
  end;
End;




procedure TMojImage.odsunOdRamki();
(* ********************************************************************************** *)
(* Odsuniecie obrazka (jesli dziecko polozy nieprtawidlowy obrazek - wodotrysk...)    *)
(* Obrazek zostaje odsuniety od lg Ramki wzdluz prostej 45st. w dol Ramki             *)
(* Odsuwamy poza obreb Okregu bedacego podpowiedzia/Lapką.                            *)
(* ********************************************************************************** *)
var odl : SmallInt;     //odleglosc swiezo opuszczonego obrazka od LG ramki (srodka ukladu)
    R   : SmallInt;     //promien okregu/Lapki
Begin
  If Ramka.JestLapka then begin   //jesli widac Lapke, to bez ceregieli odsuwamy poza Lapke:
    Odjedz();
    Exit;
  end;
  //Jak nie widac Lapki, to odsuwamy dopiero wtedy, kiedy odleglosc obrazka od srodka ukladu jest mniejsza niz polowa promienia Lapki:
  odl:= Trunc( sqrt(sqr(Self.Left-Ramka.Left)+sqr(Self.Top-Ramka.Top)) );
  R  := (Ramka.LW div 2) + 20;  //+20 zeby 'chwytal' troche wiecej, kosmetyka... LW->'Lapka.Width'
  if (odl < (R div 2)) then begin
    Odjedz();
  end
End;



procedure TMojImage.PokazWskaz();
(* Uzywana kiedy w OG oprocz wlasciwego obrazka znajdzie sie jeszcze jakis inny.       *)
(* Wskazanie przez pokazanie strzalki w dol, ze obrazek powinien zostac wysuniety z OG *)
Begin
  arrowShaft.Top  :=Self.Top+Self.Height;//-1;
  arrowShaft.Left :=Self.Left+(Self.Width div 2)-(arrowShaft.Width div 2); //przyklejamy pod obrazek, dokladnie na srodek

  arrowHead.Top:=arrowShaft.Top+arrowShaft.Height-2;
  arrowHead.Left:=arrowShaft.Left+(arrowShaft.Width div 2)-(arrowHead.Width div 2);

  //najwazniejsze - pokazanie 'wlasciwe':
  arrowShaft.Visible:=True;
  arrowHead.Visible :=True;
  arrowShaft.BringToFront;  //kosmetyka, ale znaczaca...
  arrowHead.BringToFront;
  mamWskaz:=True;           //zeby bylo wiadomo, ze 'owskazowany' - potem latwo odtworzyc
End;

procedure TMojImage.ZdejmijWskaz();
(* 'Zdjecie' wskazujacej strzalki spod obiektu *)
Begin
  Self.arrowShaft.Visible:=FALSE;
  Self.arrowHead.Visible :=FALSE;

  //Self.arrowShaft.Brush.Color:=clWhite;
  Self.TBlink.Enabled:=False;
End;



procedure TMojImage.dodajWskazNaEtapieKonstruktora();
(* Dodanie (generacja na etapie Construktora TMojImage) strzalki pokazujacej 'w dol' *)
Begin
  arrowShaft:=TShape.Create(nil) ;
  arrowShaft.Shape:=stRectangle;
  arrowShaft.Width := 20;
  arrowShaft.Height:= 50;
  arrowShaft.Parent :=FOperacje;

  arrowHead:=TShape.Create(nil);
  arrowHead.Shape:=stTriangleDown;
  arrowHead.Width:=50;
  arrowHead.Height:=40;//27;
  arrowHead.Parent:=FOperacje;
  arrowHead.Visible :=False;
  arrowShaft.Visible:=False;;

  mamWskaz:=False;  //bo jeszcze tego wskaza nie widac
End;  (* Procedure *)

procedure TMojImage.dodajPodpisNaEtapieKonstruktora();
(* 2020-04-27  Dowiązanie nazwy obrazka do ewentualnego wypisania pod obrazkiem *)
(* Uwaga - tutaj jeszcze nie ma ostatecznego polozenia - to wyliczam pozniej... *)
Begin
  LPodpis:=TLabel.Create(nil) ;
  LPodpis.Caption := ExtractFileNameOnly(plikNzw);
  LPodpis.Parent  := FOperacje;
  LPodpis.Visible := FParametry.CBPictNames.Checked; //uwaga KOHEZJA, ale trzeba, bo probleiki kosmetyczne
  LPodpis.Font.Size:=11;
  LPodpis.Font.Style:=[fsBold];
End;


procedure TMojImage.coNaBlinkTimer(Sender: Tobject);
Begin
  Self.arrowShaft.Visible:= not arrowShaft.Visible;
  Self.arrowHead.Visible := arrowShaft.Visible;
End;


procedure TMojImage.coNaTShakeTimer(Sender: TObject);
(* Potrząsamy obrazkiem *)
Begin
  lShakes:=lShakes-1;

  if shakeSwitch then
    Self.Top:=Self.Top-7
  else
    Self.Top:=Self.Top+7;
  shakeSwitch := not shakeSwitch; //zeby next. shake byl w przeciwnym kierunku

  if lShakes<1 then  begin
    Cursor:=crHandPoint;
    TShake.Enabled:=False;    //przestajemy 'potrzasac'
    if zeWskazem then         //paremaetr przekazywany z wywolywaczy - kombinacje, bo jak przekazac parametr dla OnTimer?
      PokazWskaz();
    WlaczHandlery();
  end;
End;


procedure TMojImage.PotrzasnijZeWskazem();
(* Potrzasa obrazkiem, i wystawia Wskaz           *)
(* Uzywana przy podpowioedziach, gdy obrazek w OG *)
(* Kombinacje ze zmienna-przelacznikiem, bo jak   *)
(* przekazac parametr dla OnTimer???              *)
Begin
  zeWskazem:=True;
  PotrzasnijPrivate()
End;

procedure TMojImage.PotrzasnijPrivate();
(* Wstrzasniecie (shake) obrazkiem *)
Begin
  lShakes := LSHAKES_CONST; //ile razy wstrzasnac
  if not FinArea then lShakes:=2*LSHAKES_CONST;  //kosmetyka - w OD niech bedzie potrzasa dluzej - latwiej zobaczyc...
  Cursor  := crNone;
  BlokujHandlery();         //zeby nie przesuwac 'skaczacego' obrazka - bo komplikacje...
  TShake.Enabled:=True;     //wstrzas 'wlasciwy'
End;


procedure TMojImage.PotrzasnijBezWskazu();
(* Potrzasa obrazkiem, ale nie wystawia Wskazu    *)
(* Uzywana przy podpowiedziach, gdy obrazek w OD  *)
(* patrz:PotrzasnijZeWskazem()                    *)
Begin
  zeWskazem:=False;
  PotrzasnijPrivate()
End;




Begin

End.

