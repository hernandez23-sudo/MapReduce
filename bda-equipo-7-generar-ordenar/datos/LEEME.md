# Datos de entrada

Este tema **no necesita archivos de entrada**: los datos se generan dentro del contenedor.

- `randomtextwriter` y `randomwriter` crean los datos desde cero (texto y bytes aleatorios).
- `sort` ordena lo que generaron los dos anteriores.

Por eso esta carpeta solo tiene este aviso. Los datos generados **no se suben al repositorio**: son archivos binarios (SequenceFile) que cambian en cada ejecución porque son aleatorios. Lo que sí queda guardado es el comando para generarlos (`scripts/ejecutar.sh`) y una muestra pequeña de la salida en `resultados/`.

Tamaño con el que se trabaja en esta guía: **10 MB** por programa (parámetro `-D ...totalbytes=10485760`).
