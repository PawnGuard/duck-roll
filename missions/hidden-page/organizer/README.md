# Hidden Page — guía del organizador

Solo para organizadores y defensores durante la fase de mitigación. La historia,
los paths y los controles de esta misión siguen la sección 12 de
`docs/workshopGuideOverview.md`.

## Preparar y desplegar una pareja

Desde `missions/hidden-page/`:

1. Copia `.env.example` a `.env`.
2. Configura `PAIR_ID`, `LAB_HOST_IP` y `HOST_PORT`. Reserva `8101+N` por
   pareja; `8101` es adecuado para una prueba local. El host port se publica
   únicamente en `LAB_HOST_IP`.
3. Ejecuta `sh prepare-mission.sh`. Esto genera una bandera por ronda, un hash
   de contraseña para Nginx y un archivo privado con la credencial de
   `support-staff`. Estos archivos quedan fuera de Git y de la imagen.
4. Valida y despliega:

   ```sh
   docker compose config
   docker compose up -d --build
   docker compose ps
   docker compose logs --tail=50 company-web
   ```

`company-web` es el único contenedor de la misión. Nginx escucha en 8080 dentro
del contenedor para no requerir privilegios; Compose lo publica como
`LAB_HOST_IP:HOST_PORT`. El contenedor corre como UID 101, con filesystem de
solo lectura, capacidades retiradas y límites de 128 MB / 0.25 CPU. La bandera
se monta como secreto y se incorpora al dashboard en `/tmp` al arrancar.

## Estado vulnerable y walkthrough

1. `GET /robots.txt` muestra `Disallow: /internal/incident-dashboard/`.
2. Abre esa ruta directamente. El endpoint devuelve `200` sin autenticación;
   no está enlazado desde la navegación pública.
3. Lee las siete filas de incidentes. La bandera de esta ronda aparece en
   Incident `INC-2407`, dentro de Notes, con el formato de un tracking reference.
4. Entrega la bandera verbalmente al organizador; no hay formulario de envío.
5. Revisa los logs:

   ```sh
   docker compose logs --tail=100 company-web
   ```

Las solicitudes estáticas dejan el URI, el código y la IP de origen en el log
de acceso de Nginx. Durante una búsqueda de paths se espera ver varias respuestas
404 seguidas por un `200` al dashboard.

La alternativa `gobuster`/`ffuf` debe limitarse al host y puerto asignados y a
una lista de palabras común, aprobada por el organizador. El recorrido por
`robots.txt` es suficiente para completar la misión.

## Pistas escalonadas

1. “AURELION's Support Center is public — but is everything on it actually
   linked from the site?”
2. “Check what the site itself says shouldn't be crawled.”
3. “Once you're on the dashboard, read the notes column carefully, not just
   the status column.”

## Mitigación y verificación

El defensor debe proteger todo `/internal/`, no solo borrar la pista de
`robots.txt`. En `nginx.conf`, añade autenticación a la ubicación del dashboard:

```nginx
location ^~ /internal/ {
    root /tmp;
    index index.html;
    try_files $uri $uri/ =404;
    auth_basic "AURELION Support Center";
    auth_basic_user_file /run/secrets/support_staff_htpasswd;
}
```

Después reconstruye y prueba desde el host de la pareja:

```sh
docker compose up -d --build
curl -sS -o /dev/null -w '%{http_code}\n' \
  "http://${LAB_HOST_IP}:${HOST_PORT}/internal/incident-dashboard/"
curl -sS -o /dev/null -w '%{http_code}\n' --user support-staff \
  "http://${LAB_HOST_IP}:${HOST_PORT}/internal/incident-dashboard/"
curl -sS -o /dev/null -w '%{http_code}\n' \
  "http://${LAB_HOST_IP}:${HOST_PORT}/"
docker compose logs --tail=100 company-web
```

La primera petición debe responder `401`. La segunda pide la contraseña en el
terminal; entrégala al defensor desde el archivo privado
`organizer/support-staff-credentials.txt`. Con credenciales válidas devuelve
`200`; la página pública también debe seguir en `200`. Confirma en los logs la
petición anónima bloqueada y el acceso autenticado correcto. No pegues la
contraseña o la bandera en canales compartidos.

Quitar `Disallow` de `robots.txt` o eliminar la página no es una mitigación
válida: si la solicitud anónima aún obtiene el dashboard, el defensor no pasa.

## Reset por pareja

Confirma que el argumento coincide con `PAIR_ID` en `.env` y ejecuta:

```sh
sh reset-mission.sh local
```

Reemplaza `local` por el `PAIR_ID` configurado. El script baja solo el proyecto
`hidden-page-<PAIR_ID>`, borra únicamente los tres archivos privados generados
por esta misión, crea una bandera y credencial nuevas, y reconstruye el estado
vulnerable desde los archivos versionados. No usa `down -v`; la misión no
necesita volúmenes persistentes.

## Aceptación

- `/robots.txt` lista la ruta exacta del dashboard.
- El dashboard responde `200` sin autenticación antes de la mitigación.
- Se muestran siete incidentes y solo Incident `INC-2407` contiene la bandera.
- El dashboard no está enlazado desde la navegación pública; `GET /dashboard`
  redirige al path interno y permite comprobar la técnica de búsqueda de paths
  con términos comunes.
- Después de la mitigación, la petición anónima responde `401` y `support-staff`
  obtiene `200`.
- La raíz pública y `/support/` siguen respondiendo `200`.
- Editar solo `robots.txt` no bloquea la ruta y debe rechazarse como defensa.
- El reset vuelve al dashboard anónimo vulnerable, cambia la bandera y mantiene
  disponible el sitio público.

## HID y límites de datos

La historia de Hidden Page está enteramente en el sitio. El perfil HID usa el
receptor compartido y el conjunto mínimo definido por la especificación:
hostname, IP, usuario, versión de sistema operativo y `mission_id=hidden-page`.
No debe recolectar contenido adicional del equipo del defensor.
