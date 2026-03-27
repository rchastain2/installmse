# InstallMSE

Installateur de *MSEide* conçu pour des installations multiples.

L'installation comprend les étapes suivantes :

1. clonage du dépôt *git* de *MSEide+MSEgui*
2. compilation de *MSEide*
3. configuration *MSEide*
4. création d'un script de lancement
5. création d'un raccourci sur le bureau (Linux)

## Usage

```Bash
./installmse [--dir=DIR]
```

Où **DIR** est l'emplacement du dossier *mseide-xxxxxxxxxx*.

Exemple :

```Bash
./installmse --dir=/home/roland/Applications 2> installmse.debug
```

Par défaut le dossier est créé dans le répertoire courant.

## Compilation

```Bash
git clone https://github.com/rchastain2/installmse.git
cd installmse
git clone https://github.com/mse-org/mseide-msegui.git
make
```

Par défaut l'installateur est compilé en mode passif : Il crée les scripts mais ne lance pas les commandes.

Compilation en mode actif :

```Bash
make RELEASE=1
```
