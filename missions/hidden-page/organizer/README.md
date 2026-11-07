# Hidden Page — guía del organizador

No distribuir esta guía a participantes. La misión modela un error de
publicación: el `robots.txt` revela una ruta de práctica y Nginx sirve sin
autorización un archivo de bandera montado como secreto en tiempo de ejecución.
`robots.txt` no es un mecanismo de control de acceso.

## Preparación

Desde la raíz de la misión (`missions/hidden-page/`):

1. Copia `.env.example` a `.env` con `cp .env.example .env`.
2. Configura `LAB_HOST_IP` con la dirección de la interfaz del laboratorio del
   defensor. Para una prueba local, `127.0.0.1` es suficiente.
3. Ejecuta `sh prepare-flag.sh` para generar la bandera privada de esta
   instancia. No la copies a documentación ni al contexto de build.
4. Valida y despliega:

   ```sh
   docker compose config
   docker compose up -d --build
   docker compose ps
   docker compose logs --tail=50
   ```

El único puerto publicado es TCP/8080 y queda ligado a `LAB_HOST_IP`. La
aplicación escucha en 8080 dentro del contenedor como UID 101; el sistema de
archivos es de solo lectura y solo `/tmp` es escribible temporalmente.

## Estado inicial y detección

La página pública está en `/`. La pista está en `/robots.txt`; la ruta expuesta
es `/briefing/continuity.txt`. Prueba solo en la propia instancia:

```sh
curl -i "http://${LAB_HOST_IP}:8080/"
curl -i "http://${LAB_HOST_IP}:8080/robots.txt"
curl -i "http://${LAB_HOST_IP}:8080/briefing/continuity.txt"
docker compose logs --tail=50
```

La última solicitud debe devolver la bandera. Los logs de acceso salen por
stdout y deben mostrar el URI y su código HTTP, sin copiar la bandera al log.

## Mitigación y verificación

En `nginx.conf`, cambia únicamente la ubicación de
`/briefing/continuity.txt` para que deniegue el acceso:

```nginx
location = /briefing/continuity.txt {
    deny all;
}
```

Reconstruye y valida desde el host asignado:

```sh
docker compose up -d --build
curl -sS -o /dev/null -w '%{http_code}\n' "http://${LAB_HOST_IP}:8080/"
curl -sS -o /dev/null -w '%{http_code}\n' "http://${LAB_HOST_IP}:8080/briefing/continuity.txt"
docker compose logs --tail=50
```

La página pública debe responder `200`; la ruta restringida debe responder
`403`. Confirma en los logs tanto la solicitud como su nuevo resultado. Retirar
la referencia de `robots.txt` puede reducir la pista, pero no sustituye el
bloqueo de la ruta.

## Reset

Restaura en `nginx.conf` la ubicación vulnerable mostrada en la configuración
inicial del repositorio y ejecuta:

```sh
docker compose down
docker compose up -d --build
```

Esto elimina el contenedor y sus logs al recrearlo, pero conserva la bandera
privada para la misma instancia. Para una nueva instancia, conserva la bandera
actual hasta terminar la ronda; después elimina `organizer/flag.txt` y ejecuta
`sh prepare-flag.sh` para generar otra. No uses `docker compose down -v`.

## Comprobación reproducible

- Inicial: `/` devuelve `200`; `/briefing/continuity.txt` devuelve `200` y la
  bandera solo a quien la consulta; los logs registran la ruta.
- Mitigado: `/` sigue devolviendo `200`; la ruta de práctica devuelve `403`;
  los logs muestran la solicitud bloqueada.
- Reset: vuelve a responder la ruta de práctica y la página pública permanece
  disponible.

No escanees otras direcciones ni conectes la misión a redes externas. La prueba
de puerto debe limitarse al host y puerto publicados de esta instancia.
