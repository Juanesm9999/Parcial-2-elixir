# Parcial-2-elixir

Observatorio Sismológico de la Universidad del Quindío: reporte de sismos por ciudad.

## Estructura

```
Parcial-2-elixir/
├── README.md
├── punto-1/
│   ├── reporte-sismos.exs     # main: genera, muestra y guarda el reporte
│   ├── coordinador.exs        # coordinación de procesos (spawn, send, receive)
│   ├── lector.exs             # lectura de archivos y separación válidos/rechazados
│   ├── reporte.exs            # cálculo recursivo y texto del reporte
│   ├── structs.exs            # structs Ciudad y Movimiento con sus validaciones
│   ├── util.exs                # módulo Util (mostrar_mensaje, mostrar_error)
│   └── resources/
│       ├── ciudades.txt
│       └── movimientos.txt
└── punto-2/
    ├── nodo-cliente/
    │   ├── nodo-cliente.exs
    │   └── util.exs
    └── nodo-servidor/
        ├── nodo-servidor.exs
        ├── structs.exs, lector.exs, coordinador.exs, reporte.exs, util.exs
        └── resources/
            ├── ciudades.txt
            └── movimientos.txt

`reporte-sismos.exs` carga los demás módulos con `Code.require_file`, así que **no hace falta compilar `util.exs`**.

---

## Punto 1 – Reporte local

**Carpeta desde la que se ejecuta:** `punto-1`

```
cd punto-1
elixir reporte-sismos.exs
```

- **Archivos de entrada:** `punto-1/resources/ciudades.txt` y `punto-1/resources/movimientos.txt` (campos separados por `@`, sin encabezado).
- **Reporte generado:** `punto-1/resources/reporte_sismos.txt`. Se reemplaza en cada generación exitosa.
- Si alguno de los archivos de entrada no se puede leer, se indica cuál y se conserva el reporte anterior.
- Si falla la escritura del reporte, se muestra el error en consola.

### Cómo funciona

1. `Coordinador.obtener_datos/0` inicia **dos procesos trabajadores con `spawn`** (uno para ciudades y otro para movimientos) **antes** de esperar las respuestas.
2. Cada trabajador lee su archivo y envía al coordinador, con `send`, un mensaje `{:resultado_archivo, archivo, ruta, resultado}` que identifica el archivo y trae el resultado o el error.
3. El coordinador recibe con `receive`, de forma recursiva y **en cualquier orden**, hasta tener los dos resultados. Solo genera el reporte si ambos son exitosos.
4. `Reporte.calcular_estadisticas/1` recorre los movimientos de cada ciudad con **recursividad explícita** y calcula en un mismo recorrido la cantidad, el movimiento de mayor magnitud y la suma de profundidades. El promedio se calcula como `suma / cantidad`.

### Validaciones

- Las líneas vacías se ignoran.
- **Ciudad:** debe tener 3 campos (`idCiudad@nombre@numeroHabitantes`), ninguno vacío, y el número de habitantes debe ser un entero mayor que cero.
- **Movimiento:** debe tener 6 campos, ninguno vacío; las horas deben ser horas del día con formato `HH:MM:SS`; la magnitud debe poder convertirse en decimal y la profundidad debe ser un número mayor o igual a cero.
- Se rechaza todo movimiento cuyo `idCiudad` no exista en el catálogo de ciudades válidas.
- Si varios movimientos tienen la misma magnitud máxima, se muestra el primero que aparece en el archivo.

## Punto 2 – Consulta entre nodos

Se necesitan *dos terminales. Primero se inicia el servidor y después el cliente. Ambos nodos deben usar **la misma cookie* (my_cookie).

*Terminal 1 – servidor* (carpeta punto-2/nodo-servidor):


cd punto-2/nodo-servidor
elixir --sname nodoservidor@localhost --cookie cookie nodo-servidor.exs


*Terminal 2 – cliente* (carpeta punto-2/nodo-cliente):


cd punto-2/nodo-cliente
elixir --sname nodocliente@localhost --cookie cookie nodo-cliente.exs


| Nodo | Nombre del nodo | Proceso registrado |
|---|---|---|
| Servidor | nodoservidor@localhost | :servicio_sismos |
| Cliente | nodocliente@localhost | :servicio_respuesta |

*Cookie:* se configura con --cookie my_cookie en los dos comandos. Si las cookies son diferentes, Node.connect/1 devuelve false y el cliente muestra «No se pudo conectar con el nodo servidor».

### Solicitudes que envía el cliente (en este orden)

Cada mensaje tiene la forma {destino_respuesta, solicitud}, con destino_respuesta = {:servicio_respuesta, :nodocliente@localhost}.

| # | Solicitud | Caso que prueba |
|---|---|---|
| 1 | {:reporte_ciudad, "C01"} | ciudad con movimientos (Armenia) |
| 2 | {:reporte_ciudad, "C03"} | ciudad sin movimientos (Circasia) |
| 3 | {:reporte_ciudad, "C99"} | ciudad inexistente → «La ciudad no está registrada» |
| 4 | :reporte_general | reporte de todas las ciudades y rechazados |
| 5 | :fin | el servidor confirma con :fin y el cliente termina |

### Verificación

1. Con el servidor encendido (terminal 1), ejecutar el cliente (terminal 2). Se muestran las cuatro respuestas en orden y el cliente termina al recibir :fin.
2. *Sin cerrar el servidor*, ejecutar otra vez el mismo comando del cliente en la terminal 2. El servidor sigue atendiendo, porque después de responder :fin vuelve a esperar solicitudes con una llamada recursiva.
3. Para detener el servidor: Ctrl + C dos veces en la terminal 1.

El servidor lee los archivos en cada solicitud (dos trabajadores concurrentes, igual que el punto 1), reutilizando structs.exs, lector.exs, coordinador.exs y reporte.exs. Si un archivo no se puede leer, responde con un mensaje que lo identifica y sigue atendiendo.

## Lo que no fue visto en clase 

| Elemento | Lo visto en clase | Por qué se usa |
|---|---|---|
| `File.read` con `{:ok, _}` / `{:error, _}` | En clase se usó `File.stream!` | Permite saber si el archivo no se pudo leer sin que el programa se caiga. |
| `Integer.parse` / `Float.parse` | En clase se usó `String.to_integer` / `String.to_float` | Devuelven un resultado en lugar de lanzar error, lo que permite rechazar la línea. |
| `@enforce_keys` | No se vio en clase | Obliga a pasar todos los campos al crear el struct. |
| `Time.from_iso8601` | No se vio en clase | Convierte el texto `"HH:MM:SS"` en un dato `Time` y valida que sea una hora del día. |
| `:erlang.float_to_binary(numero, decimals: 2)` | No se vio en clase | Muestra siempre dos decimales (14.00); `Float.round` mostraría 14.0. |
| `map_size` en una guarda y `Map.values` | No se vio en clase | Para saber cuándo llegaron las dos respuestas y revisar cuáles fallaron. |
| `Enum.reverse` | No se vio en clase | Las líneas se agregan al inicio de la lista (`[registro \| validos]`) y al final se invierten para conservar el orden del archivo. |
| `inspect` | No se vio en clase | Solo para mostrar una solicitud desconocida en el servidor. |
| inspect | Solo para mostrar una solicitud desconocida en el servidor. |

**Nota sobre `Task`:** en clase se vio `Task.async` / `Task.await` (Procesos paralelos). El enunciado pide `spawn`, `send` y `receive`, por eso los trabajadores se implementaron con esas funciones.

---

## Reflexión sobre el uso de inteligencia artificial

> Pendiente.