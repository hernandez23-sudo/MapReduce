# Resultados

Esta carpeta se llena después de ejecutar `scripts/ejecutar.sh` en el contenedor y copiar la salida con:

```powershell
docker cp hadoop:/tmp/equipo7/muestras/. .\resultados\
```

(💻 en tu computadora, desde la carpeta del repositorio.)

## Qué debe aparecer aquí

| Archivo | Qué contiene |
|---|---|
| `resumen.txt` | Archivos generados y su tamaño, número de registros antes y después de ordenar, y la verificación de orden |
| `texto-aleatorio-primeras-20.txt` | Primeros 20 registros de la entrada de `sort` (desordenados) |
| `texto-ordenado-primeras-20.txt` | Primeros 20 registros de la salida de `sort` (ordenados) |
| `binario-ordenado-primeras-5.txt` | Primeras 5 claves de la salida de `randomwriter` + `sort` (bytes en hexadecimal) |

## Qué se espera ver en `resumen.txt`

- El número de registros de texto es **el mismo** antes y después de ordenar (`sort` no pierde ni agrega registros).
- La entrada de texto aparece como **DESORDENADO**.
- Las dos salidas de `sort` aparecen como **ORDENADO**.

Los números exactos (registros, tamaños) cambian en cada ejecución porque los datos son aleatorios.

> Si lo prefieren, agreguen también capturas de pantalla de la ejecución (por ejemplo `captura-sort.png`).
