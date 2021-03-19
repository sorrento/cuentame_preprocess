# cuentame_preprocess
Splitting boooks in capsules and rename title and author


## Instrucciones

1. Tratamiento en __Calibre__
    - Importar aproximadamente 20 libros del mismo idioma a Calibre
    - Ponerle portada a los que falten
    - Convertir a txt
2. Recorrer el script `Preprocesos.R`
3. Mandar la carpeta MATHEMATICA a Dropbox, para que pueda usarla el script `Covers.nb`
  
## Función

1. Convertir aproximadamente 20 libros en txt con Calibre
2. Utilizar `Preprocess.R` para
    - Generar nombres falsos de libro y autores, 
    - Separar en cápsulas de tamaño correcto
    - Subir las cápsulas a la BBDD mongo
    - Genera una carpeta MATHEMATICA con los ficheros de los covers y el summary para ser insertado con Mathematica (JSON) porque sino no se coge la imagen

Mathematica procesa la imagen (`Covers.nb`)

## Función Audiolibros

1. Generar los wav en la app, apretando botón WAV. Se transcribe todo el libro actual a la sd en carpeta `d:\Android\data\com.stupidpeople.dime\files\`
2. Copiar en el pc en la carpeta datos/mp3, con la carpeta de su número de id
3. Ejecutar el script `mp3s.R`

### Edición de tags y carátula

4. Con el script de python (tag_mp3s.py) se editan los tags.
5. Finalmente se les pone la imagen con la aplicación windows **MusicBrainz Picard**
    -  Hay que agruparlas y después arrastrar la foto a la foto del cd abajo a la derecha.
6. La imagen la bajamos manualmente de la página back4app

## Otros:
- Borrar los libros de forma consistente de la BBDD Mongo

## Datos:
- Dashboard back4app:
  - https://www.back4app.com/
  - milenko@halat.cl
- mlab: 
  - https://mlab.com/ [closed, ahora Atlas mongodb]
  
