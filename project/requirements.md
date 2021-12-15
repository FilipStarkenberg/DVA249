# Applikationens funktioner

## Applikationen ska hantera följande delar

### Nätverksinformation
    Visa följande information väl strukturerat (se Bild 2)
        Datorns namn
        Namn på alla nätverksinterface (inte loopback)
            IP-adress
            MAC-adress
            Gateway (Default Route)
            Status (uppe/nere)

### Användare
    Skapa användare
    Lista alla "login-användare" (användare som kan logga in, inte systemanvändare)
    Visa alla attribut för en användare (se Bild 3)
        Alla attribut som finns med i /etc/passwd och
        vilka grupper användaren tillhör
    Ändra attribut för en användare
        Alla attribut som finns med i /etc/passwd
        Ändra lösenord för en användare
    Ta bort en användare (glöm inte att ta bort användarens hemkatalog)

### Grupper
    Skapa nya grupp
    Lista systemets alla grupper (grupper som tillhör login-användare och grupper skapade av användare, inte systemgrupper)
    Lista vilka användare som tillhör en specifik grupp (även användare som har gruppen som primärgrupp ska skrivas ut)
    Lägga till en användare i en grupp
    Ta bort en användare från en grupp
    Ta bort en grupp (endast grupper skapade av användare, inte systemgrupper)

### Mappar
    Skapa mappar
    Lista innehåll i mappar
    Lista och ändra attribut för mappar i hela filsystemet
        Ägare (owner)
        Grupp (group)
        Rättigheter (permissions)
        Sticky bit
        Setgid
        Senast ändrad (last modified)
    Ta bort en mapp

# Allmänna kriterier

## De allmänna kriterierna för applikationen är

> Ni ska använda er av en huvudmeny och eventuellt undermenyer för de olika funktionerna (se Bild 1).
> 
> Applikationen ska "snurra i en loop", efter ett val är genomfört ska huvudmenyn visas igen (applikationen ska inte startas om efter varje utfört val).
> 
> Alla menyer och utskrifter ska ha en bra genomtänkt formatering, dvs. se till att det ser "snyggt" ut, är läsbart och har tydliga avgränsningar.
> 
> Kommunikation till användaren är viktig. 
> Det ska framgå när ett val är genomfört (t.ex. "användaren skapad" och "grupp borttagen").
> 
> Se till att, i scriptet, kolla efter eventuella felmeddelanden från kommandon och hantera det på ett bra sätt.
> 
> Applikationen (skriptet) ska vara skrivet helt i BASH och ska fungera på en nyinstallerad Ubuntu-maskin, använd bara kommandon som är standard i Ubuntu.
> 
> Koden ska vara indenterad.
> 
> Applikationen ska bara gå att köra med "sudo" (root-rättigheter), kolla i början av scriptet att scriptet körs av root user (uid=0).

>Tilltänkta användare av applikationen (scriptet) är användare som inte är så duktiga på Linux.
>
>Det är därför viktigt att ni, för alla funktioner, tänker till och underlättar för användaren. 
>
>Ett exempel är när ni hanterar rättigheter för mappar (directories). 
>
>Att bara skriva ut t.ex. rwxrwSrwT är inte så begripligt. 
>
>Ni måste hitta ett annat sätt att tala om vilka rättigheter de olika grupperna har (owner, group, other), att sticky bit är på/av, setgid på/av, osv.