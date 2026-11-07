# Hidden Page — briefing para participantes

### Situación

El Support Center de AURELION Technologies usa un dashboard interno para seguir
incidentes activos de clientes. El equipo asumió que la página estaría protegida
porque no aparecía enlazada desde el sitio; incluso pidió a los buscadores que
no la indexaran. Eso no impide que alguien la visite.

## Misión

- **Atacante:** investiga el sitio web de la instancia que te asignaron, localiza
  el dashboard y revisa sus registros de incidentes. Si encuentras la bandera,
  dila verbalmente al organizador para que la valide.
- **Defensor:** detecta la actividad en los registros, protege `/internal/` con
  autenticación real y demuestra que el acceso sin credenciales queda bloqueado
  mientras el personal de soporte aún puede usar el dashboard.

## Alcance

Trabaja solo contra la IP y el puerto de tu pareja, dentro de la red aislada del
taller. El perfil HID de esta misión solo comunica al receptor del atacante el
hostname, la IP local, el usuario, el nombre del sistema operativo y
`mission_id=hidden-page`. Si el dispositivo falla, pide al organizador que te
confirme manualmente el host asignado. No recopiles otros datos del equipo del
defensor, no uses credenciales reales y no pruebes otras parejas.

La entrada que encuentres no es un portal de envío: comunica la bandera al
organizador en persona. Quitar una ruta de `robots.txt` sin proteger el recurso
no cuenta como mitigación.
