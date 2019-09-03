
/* c206.c **********************************************************}
{* Téma: Dvousměrně vázaný lineární seznam
**
**                   Návrh a referenční implementace: Bohuslav Křena, říjen 2001
**                            Přepracované do jazyka C: Martin Tuček, říjen 2004
**                                            Úpravy: Kamil Jeřábek, září 2018
**
** Implementujte abstraktní datový typ dvousměrně vázaný lineární seznam.
** Užitečným obsahem prvku seznamu je hodnota typu int.
** Seznam bude jako datová abstrakce reprezentován proměnnou
** typu tDLList (DL znamená Double-Linked a slouží pro odlišení
** jmen konstant, typů a funkcí od jmen u jednosměrně vázaného lineárního
** seznamu). Definici konstant a typů naleznete v hlavičkovém souboru c206.h.
**
** Vaším úkolem je implementovat následující operace, které spolu
** s výše uvedenou datovou částí abstrakce tvoří abstraktní datový typ
** obousměrně vázaný lineární seznam:
**
**      DLInitList ...... inicializace seznamu před prvním použitím,
**      DLDisposeList ... zrušení všech prvků seznamu,
**      DLInsertFirst ... vložení prvku na začátek seznamu,
**      DLInsertLast .... vložení prvku na konec seznamu,
**      DLFirst ......... nastavení aktivity na první prvek,
**      DLLast .......... nastavení aktivity na poslední prvek,
**      DLCopyFirst ..... vrací hodnotu prvního prvku,
**      DLCopyLast ...... vrací hodnotu posledního prvku,
**      DLDeleteFirst ... zruší první prvek seznamu,
**      DLDeleteLast .... zruší poslední prvek seznamu,
**      DLPostDelete .... ruší prvek za aktivním prvkem,
**      DLPreDelete ..... ruší prvek před aktivním prvkem,
**      DLPostInsert .... vloží nový prvek za aktivní prvek seznamu,
**      DLPreInsert ..... vloží nový prvek před aktivní prvek seznamu,
**      DLCopy .......... vrací hodnotu aktivního prvku,
**      DLActualize ..... přepíše obsah aktivního prvku novou hodnotou,
**      DLSucc .......... posune aktivitu na další prvek seznamu,
**      DLPred .......... posune aktivitu na předchozí prvek seznamu,
**      DLActive ........ zjišťuje aktivitu seznamu.
**
** Při implementaci jednotlivých funkcí nevolejte žádnou z funkcí
** implementovaných v rámci tohoto příkladu, není-li u funkce
** explicitně uvedeno něco jiného.
**
** Nemusíte ošetřovat situaci, kdy místo legálního ukazatele na seznam
** předá někdo jako parametr hodnotu NULL.
**
** Svou implementaci vhodně komentujte!
**
** Terminologická poznámka: Jazyk C nepoužívá pojem procedura.
** Proto zde používáme pojem funkce i pro operace, které by byly
** v algoritmickém jazyce Pascalovského typu implemenovány jako
** procedury (v jazyce C procedurám odpovídají funkce vracející typ void).
**/

/* Vypracovala: Katerina Fortova (xforto00)
** Datum vypracovani: rijen 2018
**/


#include "c206.h"

int errflg;
int solved;

void DLError() {
/*
** Vytiskne upozornění na to, že došlo k chybě.
** Tato funkce bude volána z některých dále implementovaných operací.
**/
    printf ("*ERROR* The program has performed an illegal operation.\n");
    errflg = TRUE;             /* globální proměnná -- příznak ošetření chyby */
    return;
}

void DLInitList (tDLList *L) {
/*
** Provede inicializaci seznamu L před jeho prvním použitím (tzn. žádná
** z následujících funkcí nebude volána nad neinicializovaným seznamem).
** Tato inicializace se nikdy nebude provádět nad již inicializovaným
** seznamem, a proto tuto možnost neošetřujte. Vždy předpokládejte,
** že neinicializované proměnné mají nedefinovanou hodnotu.
**/

    // inicializace prvniho, aktivniho a posledniho prvku seznamu na NULL
    L->First = NULL;
    L->Act = NULL;
    L->Last = NULL;

}

void DLDisposeList (tDLList *L) {
/*
** Zruší všechny prvky seznamu L a uvede seznam do stavu, v jakém
** se nacházel po inicializaci. Rušené prvky seznamu budou korektně
** uvolněny voláním operace free.
**/

    tDLElemPtr elementd; // pomocna promenna

    while (L->First != NULL)
    {
      elementd = L->First;
      L->First = L->First->rptr; // nasmerovani ukazatele na prvni prvek seznamu na misto ukazatele na dalsi prvek
      free(elementd); // uvolneni pameti
    }
    // uvedeni prazdneho seznamu do inicializovaneho stavu
    L->Act = NULL;
    L->Last = NULL;

}

void DLInsertFirst (tDLList *L, int val) {
/*
** Vloží nový prvek na začátek seznamu L.
** V případě, že není dostatek paměti pro nový prvek při operaci malloc,
** volá funkci DLError().
**/

    tDLElemPtr elementd = malloc(sizeof(struct tDLElem)); // alokace pameti pro novy prvek

    if (elementd == NULL) // alokace selhala
    {
      DLError();
      return;
    }

    elementd->data = val; // prirazeni dat
    elementd->lptr = NULL; // prvek nalevo od prvniho prvku ma hodnotu NULL
    elementd->rptr = L->First; //prvek napravo od pomocneho ukazuje na prvni prvek seznamu

    if (L->Last == NULL) // prvni vlozeni do seznamu
    {
      L->Last = elementd; // vlozeny prvek je posledni prvek seznamu
    }

    else
    {
      L->First->lptr = elementd; // ukazatel nalevo od prvniho prvku ukazuje na nas vlozeny prvek
    }

    L->First = elementd; // prvnim prvkem seznamu je nas vlozeny prvek

}

void DLInsertLast(tDLList *L, int val) {
/*
** Vloží nový prvek na konec seznamu L (symetrická operace k DLInsertFirst).
** V případě, že není dostatek paměti pro nový prvek při operaci malloc,
** volá funkci DLError().
**/

    tDLElemPtr elementd = malloc(sizeof(struct tDLElem));

    if (elementd == NULL)
    {
      DLError();
      return;
    }

    elementd->data = val;
    elementd->rptr = NULL;
    elementd->lptr = L->Last;

    if (L->Last == NULL)
    {
      L->First = elementd;
    }

    else
    {
      L->Last->rptr = elementd;
    }

    L->Last = elementd;

}

void DLFirst (tDLList *L) {
/*
** Nastaví aktivitu na první prvek seznamu L.
** Funkci implementujte jako jediný příkaz (nepočítáme-li return),
** aniž byste testovali, zda je seznam L prázdný.
**/

    L->Act = L->First;

}

void DLLast (tDLList *L) {
/*
** Nastaví aktivitu na poslední prvek seznamu L.
** Funkci implementujte jako jediný příkaz (nepočítáme-li return),
** aniž byste testovali, zda je seznam L prázdný.
**/

    L->Act = L->Last;

}

void DLCopyFirst (tDLList *L, int *val) {
/*
** Prostřednictvím parametru val vrátí hodnotu prvního prvku seznamu L.
** Pokud je seznam L prázdný, volá funkci DLError().
**/

    if (L->Last == NULL) // prazdny seznam
    {
      DLError();
      return;
    }

    *val = L->First->data; // do parametru val se priradi data z prvniho prvku seznamu

}

void DLCopyLast (tDLList *L, int *val) {
/*
** Prostřednictvím parametru val vrátí hodnotu posledního prvku seznamu L.
** Pokud je seznam L prázdný, volá funkci DLError().
**/

    if (L->Last == NULL)
    {
      DLError();
      return;
    }

    *val = L->Last->data;

}

void DLDeleteFirst (tDLList *L) {
/*
** Zruší první prvek seznamu L. Pokud byl první prvek aktivní, aktivita
** se ztrácí. Pokud byl seznam L prázdný, nic se neděje.
**/

    if (L->First == NULL) // seznam je prazdny
    {
      return;
    }

    tDLElemPtr elementd;

    elementd = L->First;

    if (L->First == L->Last)
    {
      L->First = NULL;
      L->Act = NULL;
      L->Last = NULL;
    }

    else
    {
      if (L->First == L->Act) // prvni prvek aktivni
      {
        L->Act = NULL;
      }

      L->First = elementd ->rptr; // prvnim prvek se stava dalsi po puvodnim prvnim prvku tzv. druhy prvek seznamu
      L->First->lptr = NULL;
    }

    free (elementd); // uvolneni prvku

}

void DLDeleteLast (tDLList *L) {
/*
** Zruší poslední prvek seznamu L. Pokud byl poslední prvek aktivní,
** aktivita seznamu se ztrácí. Pokud byl seznam L prázdný, nic se neděje.
**/


    if (L->First == NULL)
    {
      return;
    }

    tDLElemPtr elementd;

    elementd = L->Last;

    if (L->First == L->Last)
    {
      L->First = NULL;
      L->Act = NULL;
      L->Last = NULL;
    }

    else
    {
      if (L->Act == L->Last)
      {
        L->Act = NULL;
      }

      L->Last = elementd ->lptr;
      L->Last->rptr = NULL;
    }

    free (elementd);
}

void DLPostDelete (tDLList *L) {
/*
** Zruší prvek seznamu L za aktivním prvkem.
** Pokud je seznam L neaktivní nebo pokud je aktivní prvek
** posledním prvkem seznamu, nic se neděje.
**/

    if (L->Act == NULL || L->Act == L->Last) // seznam neaktivni nebo aktivnim posledni prvek
    {
      return;
    }

    tDLElemPtr elementd;

    elementd = L->Act->rptr;
    L->Act->rptr = elementd->rptr; // prirazeni ukazatele na pravy prvek za aktivnim co chceme zrusit

    if (L->Last == elementd) // posledni prvek je zaroven nas ruseny prvek
    {
      L->Last = L->Act; // posledni prvek se stava aktivnim
    }

    else
    {
      elementd->rptr->lptr = L->Act; // preskoceni prvku
    }

    free(elementd); // uvolneni prvku

}

void DLPreDelete (tDLList *L) {
/*
** Zruší prvek před aktivním prvkem seznamu L .
** Pokud je seznam L neaktivní nebo pokud je aktivní prvek
** prvním prvkem seznamu, nic se neděje.
**/

    if (L->Act == NULL || L->First == L->Act)
    {
      return;
    }

    tDLElemPtr elementd;

    elementd = L->Act->lptr;
    L->Act->lptr = elementd->lptr;

    if (L->First == elementd)
    {
      L->First = L->Act;
    }

    else
    {
      elementd->lptr->rptr = L->Act;
    }

    free(elementd);

}

void DLPostInsert (tDLList *L, int val) {
/*
** Vloží prvek za aktivní prvek seznamu L.
** Pokud nebyl seznam L aktivní, nic se neděje.
** V případě, že není dostatek paměti pro nový prvek při operaci malloc,
** volá funkci DLError().
**/

    if (L->Act == NULL) // neaktivni seznam
    {
      return;
    }

    tDLElemPtr elementd = malloc(sizeof(struct tDLElem)); // alokace pameti pro prvek

    if (elementd == NULL) // alokace selhala
    {
      DLError();
      return;
    }

    elementd->data = val; // nahrani dat do prvku
    elementd->rptr = L->Act->rptr; // ukazatel na dalsi prvek
    elementd->lptr = L->Act; // ukazatel na predchozi prvek
    L->Act->rptr = elementd; // napravo od aktivniho prvku vlozime prvek

    if (L->Act == L->Last) // aktivni prvek je poslednim
    {
      L->Last = elementd; // poslendim prvek je vlozeny prvek
    }

    else
    {
      elementd->rptr->lptr = elementd; // preskoceni
    }

}

void DLPreInsert (tDLList *L, int val) {
/*
** Vloží prvek před aktivní prvek seznamu L.
** Pokud nebyl seznam L aktivní, nic se neděje.
** V případě, že není dostatek paměti pro nový prvek při operaci malloc,
** volá funkci DLError().
**/

    if (L->Act == NULL)
    {
      return;
    }

    tDLElemPtr elementd = malloc(sizeof(struct tDLElem));

    if (elementd == NULL)
    {
      DLError();
      return;
    }

    elementd->data = val;
    elementd->lptr = L->Act->lptr;
    elementd->rptr = L->Act;
    L->Act->lptr = elementd;

    if (L->First == L->Act)
    {
      L->First = elementd;
    }

    else
    {
      elementd->lptr->rptr = elementd;
    }
}

void DLCopy (tDLList *L, int *val) {
/*
** Prostřednictvím parametru val vrátí hodnotu aktivního prvku seznamu L.
** Pokud seznam L není aktivní, volá funkci DLError ().
**/

    if (L->Act == NULL) // alokace selhala
    {
      DLError();
      return;
    }

    *val = L->Act->data; // vraceni hodnoty aktivniho prvku

}

void DLActualize (tDLList *L, int val) {
/*
** Přepíše obsah aktivního prvku seznamu L.
** Pokud seznam L není aktivní, nedělá nic.
**/

    if (L->Act == NULL)
    {
      return;
    }

    L->Act->data = val; // prepsani dat prvku

}

void DLSucc (tDLList *L) {
/*
** Posune aktivitu na následující prvek seznamu L.
** Není-li seznam aktivní, nedělá nic.
** Všimněte si, že při aktivitě na posledním prvku se seznam stane neaktivním.
**/

    if (L->Act == NULL)
    {
      return;
    }

    L->Act = L->Act->rptr; // posunuti aktivity na dalsi prvek za aktivnim nyni

}


void DLPred (tDLList *L) {
/*
** Posune aktivitu na předchozí prvek seznamu L.
** Není-li seznam aktivní, nedělá nic.
** Všimněte si, že při aktivitě na prvním prvku se seznam stane neaktivním.
**/

    if (L->Act == NULL)
    {
      return;
    }

    L->Act = L->Act->lptr;

}

int DLActive (tDLList *L) {
/*
** Je-li seznam L aktivní, vrací nenulovou hodnotu, jinak vrací 0.
** Funkci je vhodné implementovat jedním příkazem return.
**/

    return ((L->Act) ? 1 : 0);

}

/* Konec c206.c*/
