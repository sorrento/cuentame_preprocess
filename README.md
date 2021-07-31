# cuentame_preprocess
Splitting boooks in capsules and rename title and author

## TO DO

- Verificar que los libros que queremos procesar no están ya en la nube
- Borrar del cloud las que tienen cápsulas pero no tienen summary; mostrar qué libros son
- Obtnener una lista de los libros de la nube (como para mostrar en la estantería real)

## Instrucciones

0. Tengo libros listos en la carpeta `libros_cuentame`
1. Ahí hay una carpeta con todo lo de un autor: ir borrando de allí los que coja
2. Poner lo que voy a cargar en `_Ahora` Separar en SP y EN para hacerlo por separado
3. Carpeta `NEXT`para los que quiero qu vayan en la próxima remesa   
4. Tratamiento en __Calibre__
    - Importar aproximadamente 20 libros del mismo idioma a Calibre
    - Ponerle portada a los que falten
    - Convertir a txt    
5. Recorrer el script `Preprocesos.R`
6. Mandar la carpeta `MATHEMATICA` a Dropbox (`libros/cuentame/MATHEMATICA/`), para que pueda usarla el script `Covers.nb`
  
## Función

1. Convertir aproximadamente 20 libros en txt con Calibre
3. Utilizar `Preprocess.R` para
    - Generar nombres falsos de libro y autores, 
    - Separar en cápsulas de tamaño correcto
    - Subir las cápsulas a la BBDD mongo
    - Genera una carpeta `MATHEMATICA` con los ficheros de los covers y el summary para ser insertado con Mathematica (JSON) porque sino no se coge la imagen

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
  - https://www.back4app.com/ (slow to charge dashboard)
  - milenko@halat.cl
- BBDD: 
  - https://www.mongodb.com/es/cloud/atlas (google account access) (https://mlab.com/, is obsolete)
  
