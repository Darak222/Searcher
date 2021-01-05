#!/bin/sh

helpFunc()
{
    echo "Prototypowy skrypt pozwalający na wyszukiwanie pliku w bazie danych (pliku txt), dodawanie pliku w celu szybkiego wyszukania,"
    echo "sprawdzanie uprawnień do pliku oraz uporządkowania bazy (usunięcie nieistniejących plików lub ścieżek do plików)"
    echo "Parametry skryptu: "
    echo "-h -- Wyświetla pomoc"
    echo "-a -- Dodaje plik do bazy danych wraz z (według wyboru użytkownika) komentarzem i ścieżką do pliku"
    echo "-l -- Wyszukuje plik po zadanej nazwie bądź komentarzu w bazie danych oraz katalogu domowym"
    echo "-d -- Sprawdza czy użytkownik posiada dostęp do pliku oraz czy plik istnieje"
    echo "-r -- Porządkuje bazę danych usuwając nie istniejące pliki lub ścieżki"
}

addFile()
{
    echo "Wprowadź nazwę pliku który chcesz dodać do bazy: "
    read NAZWA_PLIKU

    echo "Czy chcesz dodać komentarz do pliku? y/n"
    read DECISION_1
    COMMENT=''
    if [ "$DECISION_1" == "y" ]; then
        echo "Wprowadź komentarz: "
        read COMMENT
    fi

    echo "Czy chcesz dodać ścieżkę do pliku? y/n"
    read DECISION_2
    SCIEZKA=''
    if [ "$DECISION_2" == "y" ]; then
        echo "Wprowadź ścieżkę: "
        read SCIEZKA
    fi
    echo "$SCIEZKA" >> baza_danych.txt
    echo "$NAZWA_PLIKU" >> baza_danych.txt
    echo "$COMMENT" >> baza_danych.txt
}

searchFile()
{
    echo "Czy chcesz wyszukać plik tylko po jego nazwie? (y przeszuka bazę danych i katalog domowy, natomiast n przeszuka tylko bazę danych)"
    read DECISION_1
    if [ "$DECISION_1" == "y" ]; then
        echo "Podaj nazwę pliku"
    else
        echo "Podaj nazwę pliku lub komentarz"
    fi

    read SEARCH
    iterator=0
    SCIEZKA=""
    NAZWA_PLIKU=""
    COMMENT=""

    while IFS="" read -r p || [ -n "$p" ]
    do
        if [ "$iterator" == "0" ]; then
            SCIEZKA="$p"
        fi
        if [ "$iterator" == "1" ]; then
            NAZWA_PLIKU="$p"
        fi
        if [ "$iterator" == "2" ]; then
            COMMENT="$p"
            ((iterator = -1))
        fi
        if [ "$COMMENT" == "$SEARCH" ]; then
            if [ "$SCIEZKA" != "" ]; then
                echo "ścieżka do pliku: $SCIEZKA, nazwa pliku: $NAZWA_PLIKU"
                exit
            else
                echo "Brak ścieżki w bazie... Przystępuję do wyszukiwania ścieżki..."
                break
            fi
        fi
        if [ "$NAZWA_PLIKU" == "$SEARCH" ]; then
            if [ "$SCIEZKA" != "" ]; then
                echo "ścieżka do pliku: $SCIEZKA, nazwa pliku: $NAZWA_PLIKU"
                exit
            else
                echo "Brak ścieżki w bazie... Przystępuję do wyszukiwania ścieżki..."
                break
            fi
        fi
        ((iterator = iterator + 1))
    done < baza_danych.txt

    if [ "$DECISION_1" == "n" ]; then
        echo "Brak pliku o wskazanej nazwie bądź komentarzu w bazie danych."
        exit
    fi
    if [ "$SCIEZKA" != "" ]; then
        echo "Brak wyszukiwanego pliku w lokalnej bazie danych... Przystępuję do wyszukiwania w katalogu domowym..."
    fi

    touch temp.txt
    find /home -name "$SEARCH"  2>&1 | grep -v 'Permission denied' > temp.txt

    if [ ! -s temp.txt ]; then
        echo "Brak wyników"
    else
        while IFS="" read -r h || [ -n "$h" ]
        do
        echo "$h"
        done < temp.txt
    fi

    rm temp.txt -r
}

checkAccess()
{
    echo "Podaj nazwę pliku dla którego chcesz sprawdzić swoje uprawnienia: "
    read SEARCH
    touch temp.txt
    find /home -name "$SEARCH"  2>&1 | grep -v 'Permission denied' > temp.txt
    if [ ! -s temp.txt ]; then
        echo "Plik nie istnieje lub nie masz do niego dostępu"
    else
        while IFS="" read -r h || [ -n "$h" ]
        do
            echo "Twoje uprawnienia dostępu do pliku $SEARCH"
            ls -l $h
        done < temp.txt
    fi
    rm temp.txt -r
}

removeEmpty()
{
    iterator=0
    SCIEZKA=""
    NAZWA_PLIKU=""
    touch temp.txt
    while IFS="" read -r p || [ -n "$p" ]
    do
        if [ "$iterator" == "0" ]; then
            SCIEZKA="$p"
        fi

        if [ "$iterator" == "1" ] && [ "$SCIEZKA" != "" ]; then
            touch quickcheck.txt
            find "$SCIEZKA" -name "$p"  2>&1 | grep -v 'Permission denied' > quickcheck.txt
            if [ ! -s quickcheck.txt ]; then
                NAZWA_PLIKU=""
            else
                NAZWA_PLIKU="$p"
            fi
            rm quickcheck.txt -r

        fi
        if [ "$iterator" == "2" ] && [ "$SCIEZKA" != "" ] && [ "$NAZWA_PLIKU" != "" ]; then
            echo $SCIEZKA >> temp.txt
            echo $NAZWA_PLIKU >> temp.txt
            echo $p >> temp.txt
            ((iterator = -1))
            SCIEZKA=""
            NAZWA_PLIKU=""
        elif [ "$iterator" == 2 ]; then
            ((iterator = -1))
            SCIEZKA=""
            NAZWA_PLIKU=""   
        fi

        ((iterator = iterator + 1))
    done < baza_danych.txt
    rm baza_danych.txt -r
    touch baza_danych.txt
    while IFS="" read -r h || [ -n "$h" ]
    do
        echo $h >> baza_danych.txt
    done < temp.txt
    rm temp.txt -r
    
}

while getopts ":haldr" option; do
    case $option in
        h) 
            echo "Wybrano opcję pomocy"
            helpFunc
            exit;;
        a)
            echo "Wybrano dodanie lokalizacji pliku"
            addFile
            exit;;
        l)
            echo "Wybrano wyszukiwanie lokalizacji pliku"
            searchFile
            exit;;
        d)
            echo "Wybrano sprawdzenie dostępności wyszukiwanych plików"
            checkAccess
            exit;;
        r)
            echo "Porządkowanie bazy danych..."
            removeEmpty
            exit;;
        \?)
            echo "Błędny kod"
            exit;;

    esac
done

echo "Nie wybrano żadnej z opcji"


