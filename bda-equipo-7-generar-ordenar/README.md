# Equipo 7 · Generar y ordenar datos con MapReduce

Ejemplos de Hadoop 3.3.6 que se trabajan aquí: **`randomtextwriter`**, **`randomwriter`** y **`sort`**.

Todo se ejecuta en el contenedor `hadoop` de la práctica *Hadoop Standalone en contenedor Debian* (Debian 12, OpenJDK 17, Hadoop 3.3.6 en `/opt/hadoop`, usuario `hadoop`).

**Integrantes:** _(nombres del equipo)_ · **Probado por el equipo el:** _(fecha)_

> ⚠️ **Aviso importante.** `randomtextwriter` y `randomwriter` escriben **10 GB** por defecto y pueden llenar el disco del contenedor. En esta guía el tamaño siempre se limita a **10 MB** con un parámetro `-D`. No ejecutes estos programas sin él.

---

## Cómo leer esta guía

Se trabaja en dos lugares distintos y no hay que confundirlos:

- 💻 **En tu computadora** (PowerShell): comandos `docker ...`, Git y la carpeta del repositorio.
- 🐳 **Dentro del contenedor**: donde se ejecuta Hadoop. Si tu prompt dice `hadoop@hadoop` o `root@hadoop`, estás aquí.

Cada bloque de código está marcado con 💻 o 🐳. **Nunca** ejecutes `docker rm hadoop`: borra el contenedor con todo lo instalado.

---

## Qué hace cada ejemplo

| Programa | Qué hace | Entrada | Salida |
|---|---|---|---|
| `randomtextwriter` | Genera texto aleatorio (palabras de una lista fija) | Ninguna (entrada ficticia) | SequenceFile con pares `Text`/`Text` en `part-m-*` |
| `randomwriter` | Genera bytes aleatorios | Ninguna (entrada ficticia) | SequenceFile con pares `BytesWritable`/`BytesWritable` en `part-m-*` |
| `sort` | Ordena por clave los datos que generaron los anteriores | Carpeta con SequenceFile | SequenceFile ordenado en `part-r-*` |

## Qué pasa por dentro

```
randomtextwriter / randomwriter  (solo MAP, 0 reducers)

  entrada ficticia 1 ──► Map 1 ──► (clave aleatoria, valor aleatorio) ... ──► part-m-00000
  entrada ficticia 2 ──► Map 2 ──► (clave aleatoria, valor aleatorio) ... ──► part-m-00001

  Nº de mappers = totalbytes / bytespermap


sort  (Map identidad ► Shuffle y sort ► Reduce identidad)

  part-m-0000N        Map                 Shuffle y sort            Reduce
  (clave, valor) ──► emite igual ──► Hadoop reparte por clave ──► escribe igual ──► part-r-00000
                                     y ORDENA las claves           (claves ya
                                                                    ordenadas)
```

- Los generadores **no leen datos**: cada mapper recibe una entrada ficticia que solo sirve para arrancarlo y produce pares aleatorios hasta llegar a su cuota. Como no hay reduce, la salida se llama `part-m-*` (m = map).
- `sort` **no contiene código de ordenamiento** en el Map ni en el Reduce: ambos son identidad. El ordenamiento lo hace Hadoop entre las dos fases (*shuffle y sort*). La salida se llama `part-r-*` (r = reduce).
- `sort` espera por defecto claves y valores `BytesWritable`. Para ordenar la salida de `randomtextwriter` (que es `Text`) hay que indicarlo con `-outKey` y `-outValue`.

## Estructura del repositorio

```
bda-equipo-7-generar-ordenar/
├── README.md
├── datos/LEEME.md          ← este tema no necesita datos de entrada: se generan
├── scripts/ejecutar.sh     ← todos los comandos en orden (se ejecuta en el contenedor)
├── resultados/             ← resumen y muestras de la salida
├── ejercicio/
│   ├── ejercicio.md        ← mini ejercicio para compañeros
│   └── solucion.md
└── presentacion.pdf
```

---

## Paso a paso

### Paso 0 · 💻 Arrancar el contenedor

```powershell
docker start hadoop
```

Enciende el contenedor si estaba detenido, sin abrir su terminal. Si dice `No such container`, primero hay que hacer la práctica *Hadoop Standalone en contenedor Debian*.

### Paso 1 · 💻 Copiar el script al contenedor

Desde la carpeta del repositorio:

```powershell
docker cp .\scripts\ejecutar.sh hadoop:/tmp/ejecutar.sh
docker exec -u root hadoop chmod a+r /tmp/ejecutar.sh
docker exec -u root hadoop sed -i 's/\r$//' /tmp/ejecutar.sh
```

- `docker cp` copia el archivo de tu computadora al contenedor (lo deja en `/tmp`).
- `chmod a+r` asegura que el usuario `hadoop` pueda leerlo (`docker cp` lo deja a nombre de `root`).
- `sed` quita los saltos de línea de Windows (`\r`), que hacen fallar a Bash. Si el archivo ya estaba bien, no cambia nada.

### Paso 2 · 💻 Entrar al contenedor (en una terminal nueva)

```powershell
docker exec -it -u hadoop hadoop bash
```

El prompt debe cambiar a `hadoop@hadoop:~$`. Desde aquí, todo es 🐳.

### Paso 3 · 🐳 Comprobar el entorno y el espacio libre

```bash
hadoop version | head -n 1
df -h /tmp
```

Debe decir `Hadoop 3.3.6`. En `df` revisa que haya al menos **1 GB libre** en `/tmp`.

### Paso 4 · 🐳 Investigar cómo limitar el tamaño

```bash
JAR=/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
javap -p -constants -cp $JAR org.apache.hadoop.examples.RandomTextWriter | grep mapreduce
javap -p -constants -cp $JAR org.apache.hadoop.examples.RandomWriter | grep mapreduce
hadoop jar $JAR sort
```

- `javap` (viene con el JDK) lista las constantes de la clase de cada programa, entre ellas los **nombres de los parámetros** que acepta, como `mapreduce.randomtextwriter.totalbytes` y `mapreduce.randomtextwriter.bytespermap`.
- `hadoop jar $JAR sort` sin argumentos solo muestra cómo se usa.
- **Si en el `javap` no aparece ningún parámetro con `totalbytes`, no sigas** con los pasos siguientes: ese es el que evita los 10 GB.

### Paso 5 · 🐳 Opción A: ejecutar todo de golpe

```bash
bash /tmp/ejecutar.sh
```

Genera 10 MB de texto y 10 MB de bytes, ordena ambos, verifica el orden y guarda un resumen en `/tmp/equipo7/muestras/`. Pasa al Paso 7 para copiar los resultados.

### Paso 6 · 🐳 Opción B: paso a paso (para la demo)

**6.1 Preparar variables y carpeta de trabajo**

```bash
JAR=/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
BASE=/tmp/equipo7
rm -rf $BASE && mkdir -p $BASE
```

`JAR` es la ruta del paquete de ejemplos. El `rm -rf` es porque Hadoop **no escribe en una carpeta de salida que ya existe**.

**6.2 Generar texto aleatorio (10 MB, 2 mappers)**

```bash
hadoop jar $JAR randomtextwriter \
  -D mapreduce.randomtextwriter.totalbytes=10485760 \
  -D mapreduce.randomtextwriter.bytespermap=5242880 \
  $BASE/texto-aleatorio
```

- `-D nombre=valor` pasa un parámetro al programa. **Debe ir justo después del nombre del programa y antes de la carpeta de salida**; si va después, Hadoop lo ignora y escribe 10 GB.
- `totalbytes` = 10 MB en total. `bytespermap` = 5 MB por mapper, así que se lanzan 2 mappers.
- Al final, en los contadores, `Bytes Written` debe ser cercano a 10 MB.

**6.3 Ver qué se generó**

```bash
ls -lh $BASE/texto-aleatorio
hadoop fs -text $BASE/texto-aleatorio/part-m-00000 | head -n 3 | cut -c1-200
hadoop fs -text $BASE/texto-aleatorio/part-m-* | wc -l
```

- Debe haber `_SUCCESS` y archivos `part-m-0000N` (uno por mapper; si ves solo uno, tu versión no tomó `bytespermap`, no pasa nada).
- Son SequenceFile (binario), por eso se leen con `hadoop fs -text`. Cada línea es `clave<TAB>valor`.
- El último comando cuenta los registros.

**6.4 Comprobar que está desordenado**

```bash
hadoop fs -text $BASE/texto-aleatorio/part-m-00000 | cut -f1 | LC_ALL=C sort -c 2>&1 | cut -c1-100
```

`cut -f1` se queda con la clave y `sort -c` comprueba si están en orden. Debe mostrar algo como `sort: -:2: disorder: ...`, que indica la primera clave fuera de orden. `LC_ALL=C` hace que compare por bytes, igual que Hadoop.

**6.5 Ordenar con `sort`**

```bash
hadoop jar $JAR sort -r 1 \
  -outKey org.apache.hadoop.io.Text -outValue org.apache.hadoop.io.Text \
  $BASE/texto-aleatorio $BASE/texto-ordenado
```

- `-r 1` fija **1 reducer**, y con uno la salida queda ordenada de forma global. Indicarlo evita depender del valor automático, que en modo local puede resultar en 0 reducers (sin reduce no hay ordenamiento global).
- `-outKey` y `-outValue` indican que las claves y valores son `Text`.

**6.6 Verificar el resultado**

```bash
ls -lh $BASE/texto-ordenado
hadoop fs -text $BASE/texto-ordenado/part-r-00000 | cut -f1 | head -n 5
hadoop fs -text $BASE/texto-ordenado/part-r-00000 | cut -f1 | LC_ALL=C sort -c && echo "ORDENADO"
hadoop fs -text $BASE/texto-ordenado/part-r-00000 | wc -l
```

Ahora el archivo se llama `part-r-00000`, `sort -c` no muestra ningún error y aparece `ORDENADO`. El número de registros debe ser igual al de 6.3: `sort` no pierde ni agrega registros.

**6.7 Lo mismo con bytes aleatorios**

```bash
hadoop jar $JAR randomwriter \
  -D mapreduce.randomwriter.totalbytes=10485760 \
  $BASE/binario-aleatorio

hadoop jar $JAR sort -r 1 $BASE/binario-aleatorio $BASE/binario-ordenado

hadoop fs -text $BASE/binario-ordenado/part-r-00000 | cut -f1 | cut -c1-60 | head -n 5
```

Aquí no hace falta `-outKey` ni `-outValue`, porque `randomwriter` y `sort` usan `BytesWritable` por defecto. Las claves se ven como bytes en hexadecimal porque son datos aleatorios, no texto.

### Paso 7 · 💻 Copiar los resultados a tu computadora

Si usaste la Opción A (el script), en una terminal de tu computadora:

```powershell
docker cp hadoop:/tmp/equipo7/muestras/. .\resultados\
```

Copia el resumen y las muestras pequeñas a la carpeta `resultados/`. **No copies** las carpetas completas de salida: son binarias y pesadas.

### Paso 8 · 🐳 Limpiar

```bash
rm -rf /tmp/equipo7
```

Libera el espacio del contenedor.

---

## Solución de problemas

| Síntoma | Causa | Solución |
|---|---|---|
| `Output directory ... already exists` | Hadoop no sobrescribe carpetas de salida | `rm -rf` de esa carpeta (🐳) o usa otro nombre |
| `Type mismatch in key from map: expected ...BytesWritable, received ...Text` | Se ordenó texto sin `-outKey`/`-outValue` | Agregar `-outKey org.apache.hadoop.io.Text -outValue org.apache.hadoop.io.Text` |
| `$'\r': command not found` | El script tiene saltos de línea de Windows | Repetir el `sed` del Paso 1 |
| `Permission denied` al ejecutar el script | El archivo quedó a nombre de `root` | Repetir el `chmod` del Paso 1 y usar `bash /tmp/ejecutar.sh` |
| La carpeta crece mucho o el disco se llena | Faltó o está mal puesto el `-D ...totalbytes` | `Ctrl+C`, `rm -rf /tmp/equipo7` y revisar que `-D` vaya antes de la carpeta de salida |

## Qué aprendimos

- Un trabajo MapReduce puede tener **solo Map** (`part-m-*`) o Map y Reduce (`part-r-*`).
- El ordenamiento lo hace el *shuffle*, no el código del Map ni del Reduce.
- Los tipos de clave y valor (`Text`, `BytesWritable`) deben coincidir entre los programas encadenados.
- Los programas generadores escriben 10 GB por defecto: siempre hay que limitar el tamaño.
