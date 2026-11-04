# Mini ejercicio · Genera, ordena y comprueba

**Antes de empezar:** contenedor `hadoop` encendido (`docker start hadoop`) y una terminal dentro de él (`docker exec -it -u hadoop hadoop bash`). Todos los pasos son 🐳.

## Ejercicio: Genera 2 MB de texto aleatorio, ordénalo con `sort` y demuestra que no se perdió ningún registro

> ⚠️ Recuerda: sin el parámetro `-D` estos programas escriben 10 GB.

### Paso 1. Preparar variables y carpeta de trabajo

Define la variable `JAR` con la ruta del paquete de ejemplos (`/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar`) y crea la carpeta `/tmp/ejercicio7`.

### Paso 2. Generar el texto

Ejecuta `randomtextwriter` con **2 MB en total** (2097152 bytes) y **1 MB por mapper** (1048576 bytes). La salida debe ir a `/tmp/ejercicio7/texto`.

Pista: los parámetros son `mapreduce.randomtextwriter.totalbytes` y `mapreduce.randomtextwriter.bytespermap`, y `-D` va antes de la carpeta de salida.

### Paso 3. Ver qué se generó

Lista la carpeta de salida. Cuenta cuántos archivos `part-m-*` hay y cuántos registros tienen en total.

Pista: los archivos son SequenceFile, así que no se leen con `cat`.

### Paso 4. Ordenar

Ejecuta `sort` con **1 reducer** sobre `/tmp/ejercicio7/texto` y deja la salida en `/tmp/ejercicio7/ordenado`.

Pista: el texto es de tipo `Text`, y `sort` espera `BytesWritable` por defecto.

### Paso 5. Comprobar el resultado

1. Cuenta los registros de `/tmp/ejercicio7/ordenado`. ¿Coinciden con los del Paso 3?
2. Comprueba que las claves quedaron ordenadas, sin usar Hadoop.

Pista: `cut`, `sort -c` y `LC_ALL=C`.

### Paso 6. Limpiar

Borra `/tmp/ejercicio7`.

## Preguntas para reflexionar

1. La salida de `randomtextwriter` se llama `part-m-00000` y la de `sort` se llama `part-r-00000`. ¿Qué indica la `m` y qué indica la `r`?
2. Ejecuta el `sort` del Paso 4 **sin** `-outKey` ni `-outValue`. Anota el mensaje de error y explica por qué aparece.
3. Ejecuta de nuevo el Paso 2 sin borrar la carpeta de salida. ¿Qué responde Hadoop y por qué?
4. Con `totalbytes` = 10 MB, ¿cuántos mappers se lanzan si `bytespermap` es 5 MB? ¿Y si fuera 1 MB?
5. El `sort` no tiene código de ordenamiento ni en el Map ni en el Reduce. Entonces, ¿quién ordena los datos?
