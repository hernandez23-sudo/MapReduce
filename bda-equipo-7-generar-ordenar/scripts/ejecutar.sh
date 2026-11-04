#!/usr/bin/env bash
# ============================================================================
# Equipo 7 · Generar y ordenar datos (randomtextwriter, randomwriter, sort)
#
# 🐳 EJECUTAR DENTRO DEL CONTENEDOR, como usuario hadoop:
#       bash /tmp/ejecutar.sh
#
# Genera ~10 MB de datos. NO quites los parámetros -D: sin ellos los
# programas escriben 10 GB y pueden llenar el disco del contenedor.
# ============================================================================
set -u

JAR=/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
BASE=/tmp/equipo7
TOTAL=10485760        # 10 MB en bytes
POR_MAPPER=5242880    # 5 MB por mapper  ->  2 mappers

# Revisa si las claves de un SequenceFile están ordenadas (orden por bytes)
verificar_orden() {   # $1 = archivo SequenceFile
  if hadoop fs -text "$1" | cut -f1 | LC_ALL=C sort -c 2>/dev/null; then
    echo "ORDENADO"
  else
    echo "DESORDENADO"
  fi
}

echo "Equipo 7 - $(date)"
echo "Espacio libre en /tmp:"
df -h /tmp

# Hadoop no escribe en carpetas de salida que ya existen: se empieza limpio
rm -rf "$BASE"
mkdir -p "$BASE/muestras"

echo
echo ">>> 1/4 randomtextwriter (texto aleatorio, ~10 MB, 2 mappers)"
hadoop jar "$JAR" randomtextwriter \
  -D mapreduce.randomtextwriter.totalbytes=$TOTAL \
  -D mapreduce.randomtextwriter.bytespermap=$POR_MAPPER \
  "$BASE/texto-aleatorio" || { echo "FALLÓ randomtextwriter"; exit 1; }

echo
echo ">>> 2/4 sort sobre el texto (1 reducer, claves y valores Text)"
hadoop jar "$JAR" sort -r 1 \
  -outKey org.apache.hadoop.io.Text -outValue org.apache.hadoop.io.Text \
  "$BASE/texto-aleatorio" "$BASE/texto-ordenado" || { echo "FALLÓ sort (texto)"; exit 1; }

echo
echo ">>> 3/4 randomwriter (bytes aleatorios, ~10 MB)"
hadoop jar "$JAR" randomwriter \
  -D mapreduce.randomwriter.totalbytes=$TOTAL \
  "$BASE/binario-aleatorio" || { echo "FALLÓ randomwriter"; exit 1; }

echo
echo ">>> 4/4 sort sobre los bytes (1 reducer; por defecto claves y valores BytesWritable)"
hadoop jar "$JAR" sort -r 1 \
  "$BASE/binario-aleatorio" "$BASE/binario-ordenado" || { echo "FALLÓ sort (binario)"; exit 1; }

echo
echo ">>> Resumen y verificación"
{
  echo "Equipo 7 - $(date)"
  echo
  echo "Archivos generados:"
  ls -lh "$BASE"/texto-aleatorio "$BASE"/texto-ordenado "$BASE"/binario-aleatorio "$BASE"/binario-ordenado
  echo
  echo "Tamaño de cada carpeta:"
  du -sh "$BASE"/texto-aleatorio "$BASE"/texto-ordenado "$BASE"/binario-aleatorio "$BASE"/binario-ordenado
  echo
  echo "Registros de texto antes de ordenar:   $(hadoop fs -text "$BASE"/texto-aleatorio/part-m-* | wc -l)"
  echo "Registros de texto después de ordenar: $(hadoop fs -text "$BASE"/texto-ordenado/part-r-00000 | wc -l)"
  echo
  echo "Entrada de texto (part-m-00000):  $(verificar_orden "$BASE"/texto-aleatorio/part-m-00000)   <- se espera DESORDENADO"
  echo "Salida de sort, texto:            $(verificar_orden "$BASE"/texto-ordenado/part-r-00000)   <- se espera ORDENADO"
  echo "Salida de sort, bytes:            $(verificar_orden "$BASE"/binario-ordenado/part-r-00000)   <- se espera ORDENADO"
} | tee "$BASE/muestras/resumen.txt"

# Muestras pequeñas para copiar a la computadora
hadoop fs -text "$BASE/texto-aleatorio/part-m-00000"  2>/dev/null | head -n 20 | cut -c1-150 > "$BASE/muestras/texto-aleatorio-primeras-20.txt"
hadoop fs -text "$BASE/texto-ordenado/part-r-00000"   2>/dev/null | head -n 20 | cut -c1-150 > "$BASE/muestras/texto-ordenado-primeras-20.txt"
hadoop fs -text "$BASE/binario-ordenado/part-r-00000" 2>/dev/null | head -n 5  | cut -c1-100 > "$BASE/muestras/binario-ordenado-primeras-5.txt"

echo
echo "Muestras guardadas en $BASE/muestras"
echo "Para copiarlas a tu computadora (💻 PowerShell):"
echo "  docker cp hadoop:$BASE/muestras/. .\\resultados\\"
