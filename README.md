# cuentame_preprocess
Splitting boooks in capsules and rename title and author


## Instrucciones

1. Tratamiento en *Calibre*
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


## Otros:
- Borrar los libros que no nos gustan de mongo

## Datos:
- Dashboard back4app:
  - https://www.back4app.com/
  - milenko@halat.cl
- mlab: 
  - https://mlab.com/
  - mhalat
