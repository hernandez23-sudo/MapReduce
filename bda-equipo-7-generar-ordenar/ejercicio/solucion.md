# Solución del mini ejercicio

Los números exactos (registros, tamaños) cambian en cada ejecución porque los datos son aleatorios; lo que no cambia es la relación entre ellos.

## Pasos (🐳 dentro del contenedor)

**Paso 1. Variables y carpeta**

```bash
JAR=/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
rm -rf /tmp/ejercicio7 && mkdir -p /tmp/ejercicio7
```

**Paso 2. Generar el texto (2 MB, 2 mappers)**

```bash
hadoop jar $JAR randomtextwriter \
  -D mapreduce.randomtextwriter.totalbytes=2097152 \
  -D mapreduce.randomtextwriter.bytespermap=1048576 \
  /tmp/ejercicio7/texto
```

**Paso 3. Ver qué se generó**

```bash
ls -lh /tmp/ejercicio7/texto
hadoop fs -text /tmp/ejercicio7/texto/part-m-* | wc -l
```

Se esperan `_SUCCESS` y archivos `part-m-0000N` (normalmente dos, uno por mapper). El segundo comando da el número total de registros. **Anótalo.**

**Paso 4. Ordenar**

```bash
hadoop jar $JAR sort -r 1 \
  -outKey org.apache.hadoop.io.Text -outValue org.apache.hadoop.io.Text \
  /tmp/ejercicio7/texto /tmp/ejercicio7/ordenado
```

**Paso 5. Comprobar**

```bash
hadoop fs -text /tmp/ejercicio7/ordenado/part-r-00000 | wc -l
hadoop fs -text /tmp/ejercicio7/ordenado/part-r-00000 | cut -f1 | LC_ALL=C sort -c && echo "ORDENADO"
```

- El número de registros es **igual** al del Paso 3: `sort` no pierde ni agrega registros.
- Debe aparecer `ORDENADO`. `LC_ALL=C` hace que `sort` compare por bytes, igual que Hadoop.

**Paso 6. Limpiar**

```bash
rm -rf /tmp/ejercicio7
```

## Respuestas a las preguntas

1. La `m` significa que el archivo lo escribió un **Map** (trabajo sin reduce, como los generadores) y la `r` que lo escribió un **Reduce** (como `sort`).
2. Aparece un error de tipos, parecido a `Type mismatch in key from map: expected org.apache.hadoop.io.BytesWritable, received org.apache.hadoop.io.Text`. `sort` espera por defecto claves y valores `BytesWritable`, pero `randomtextwriter` generó `Text`. Se corrige con `-outKey` y `-outValue`.
3. Hadoop se niega con un error del tipo `Output directory ... already exists`. No sobrescribe carpetas de salida para no destruir resultados anteriores por accidente; hay que borrar la carpeta o usar otro nombre.
4. `totalbytes / bytespermap`: 10 MB / 5 MB = **2 mappers**; 10 MB / 1 MB = **10 mappers**.
5. Lo ordena Hadoop entre las dos fases, en el *shuffle y sort*: ordena las claves que salen del Map antes de entregarlas al Reduce. El Map y el Reduce de `sort` son identidad (emiten lo mismo que reciben).
