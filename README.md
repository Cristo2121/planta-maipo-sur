# Taller DevSecOps - Planta Maipo Sur

Laboratorio ficticio. No usar datos, credenciales, IP ni equipos reales.

## Accesos

- Actions: pestaña **Actions** de este repositorio
- Secreto requerido: `PLC_PASSWORD`
- Workflow: `seguridad-planta`
- Entregable: `ENTREGABLE.md`
- Rúbrica: `RUBRICA.md`
- Laboratorio IA: https://gandalf.lakera.ai/

## Ejercicio 1 (individual, 15 min)

1. Ejecuta `seguridad-planta` (Actions > seguridad-planta > Run workflow).
2. Abre el job `buscar-secretos`, luego el paso `Gitleaks`, y lee el hallazgo.
3. Crea el secreto `PLC_PASSWORD` (Settings > Secrets and variables > Actions).
4. Cambia `config.yaml` a `password_env: PLC_PASSWORD`.
5. Ejecuta nuevamente y comprueba la prueba funcional.

Regla de oro: **no copies ni muestres la contraseña**.

## Ejercicio 2 (por equipos, 30 min)

1. Completa el modelado de amenazas (papel, sin teclado).
2. Cambia a la rama de tu equipo (ver abajo).
3. Activa los controles marcados en `.github/workflows/seguridad.yml`.
4. Corrige el defecto de tu sector.
5. Revisa la propuesta de IA **sin fusionarla** (nunca pulses Merge).
6. Completa `ENTREGABLE.md`.

## Cómo cambiar de rama

Arriba a la izquierda de la lista de archivos hay un botón que dice `main`.
Púlsalo y elige la rama de tu equipo: `equipo-agua`, `equipo-energia`,
`equipo-salud` o `equipo-transporte`. Todo lo que edites en el Ejercicio 2
debes guardarlo en **esa** rama. Al ejecutar el workflow, elige también esa rama
en el desplegable de *Run workflow*.

## Reglas

1. Trabajamos solo con sistemas simulados y datos ficticios.
2. Una cruz roja significa que el control encontró un problema; no que fallaste.
3. No copies contraseñas en chats, fichas o capturas.
4. No desactives una regla para obtener un resultado verde.
5. Si algo no coincide con la pantalla, levanta la mano.
