# Ficha de blindaje · Planta de Agua Potable Maipo Sur

> **Expediente de Desarrollo Seguro y Gestión de Riesgo Operacional**
> Caso: Planta de Tratamiento y Distribución de Agua Potable «Maipo Sur» (80.000 habitantes).
> Alineado con Ley Marco de Ciberseguridad N° 21.663 (OIV), NIST SP 800-82 Rev. 3 e IEC 62443-4-1.
---

## 1. Sistema y equipo

- **Sector asignado:** Infraestructura Crítica Sanitaria · Agua Potable y Tratamiento.
- **Nombre del equipo:** Equipo 1 - Guardianes de Maipo Sur.
- **Asignación de roles:**
  * **Operador de planta (sin teclado / veto físico):** Encargado de la calidad sanitaria del agua y seguridad del proceso físico de cloración.
  * **Desarrollador (con teclado):** Modificación segura de archivos, aislamiento de credenciales y remediación de código.
  * **Guardián del pipeline (con teclado):** Configuración de compuertas automáticas en GitHub Actions (`seguridad.yml`) y análisis de logs.
  * **Auditor de IA (sin teclado):** Auditoría forense de dependencias, detección de alucinaciones y revisión de propuestas de asistentes de IA.
  * **Relator (sin teclado):** Redacción de la ficha técnica y exposición del criterio de riesgo ante la sala.

---

## 2. Diagrama del Sistema (Modelo de Zonas y Conductos Purdue)

El flujo físico y lógico de la planta se estructura en 4 componentes principales:

```
[ Nivel 4 / 3.5: Nube / Red Externa ]
       │
       ▼ (HTTPS - Monitoreo de Lecturas)
[ Servicio Web Telemetría ]
       │
       ▼ (Canal Supervisión N2: Interfaz Operador)
[ Panel de Operación HMI / SCADA ]
       │
       ▼ (Conducto Industrial Seguro N1: Modbus TCP / Puerto 502)
[ PLC Dosificador de Cloro ]
       │
       ▼ (Proceso Físico N0: Inyección Química)
[ Bomba / Válvula Dosificadora ] ──► [ Red de Agua Potable (80.000 personas) ]
```

[![Diagrama de Zonas y Conductos Purdue](https://github.com/Cristo2121/planta-maipo-sur/raw/main/evidencias/diagrama_flujo_maipo_sur.svg)](/Cristo2121/planta-maipo-sur/blob/main/evidencias/diagrama_flujo_maipo_sur.svg)

- **Archivo de evidencia gráfica subido:** `evidencias/diagrama_flujo_maipo_sur.svg`

---

## 3. Tres Amenazas Priorizadas (Impacto Físico en el Agua)

| N°    | Amenaza                                                          | Categoría STRIDE                                                                                   | Impacto en el Proceso Físico (Mundo Real)                                                                                                                                                                | Control que la Detecta / Mitiga                                                                                                                                                                          |
| ----- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1** | **Adulteración de la dosificación de cloro en el PLC**           | **Manipulación (Tampering)**                                                                       | Si un atacante modifica las consignas de cloración, puede:<br>a) Reducir el cloro a 0 mg/L: distribución de agua sin desinfectar con bacterias (E. coli, cólera) a 80.000 personas.<br>b) Aumentar el cloro a niveles tóxicos (>5.0 mg/L): intoxicación química masiva, quemaduras en mucosas y corte del suministro comunal. | • Control **futuro** (aún no existe en el código): validación de rangos de dosificación y alarma física.<br>• Hoy el pipeline solo cubre el código que la planta escribe (Semgrep), no el equipo físico. |
| **2** | **Toma de control del PLC por credencial de fábrica o expuesta** | **Suplantación (Spoofing) / Filtración (Information Disclosure)**                                  | Acceso no autorizado al panel del controlador industrial (similar al incidente real de Aliquippa, Pensilvania, 2023 con PLC Unitronics). El atacante cambia la clave de acceso, bloquea al operador de turno y toma el control unilateral de las bombas de agua. | • Control 1: **Gitleaks** bloqueando credenciales en cada commit.<br>• GitHub Secrets (`PLC_PASSWORD`) para inyección segura en tiempo de ejecución.<br>• Procedimiento de rotación inmediata en el equipo físico. |
| **3** | **Secuestro de instrucciones y comandos vía Asistente de IA**    | **Elevación de privilegios (Elevation of Privilege) / Inyección de instrucciones (LLM01 / LLM03)** | El asistente de turno con permisos sobre el SCADA recibe un prompt malicioso (inyección indirecta) que le ordena ejecutar llamadas directas al sistema operativo (`shell=True`). El atacante logra ejecución remota de código en la red de control sin pasar por la HMI. | • Semgrep (`python-shell-true`) detecta el efecto final (ejecución de comandos del sistema), no la inyección de instrucciones en sí.<br>• Control **futuro**: mínimo privilegio para la IA (solo lectura, nunca consignas). |

---

## 4. Controles Automáticos Ejecutados en el Pipeline

- **Enlace a la ejecución en GitHub Actions:** `https://github.com/Cristo2121/planta-maipo-sur/actions/runs/38597927249`
- **Controles ejecutados:**
  1. **Código propio (SAST + Detección de Secretos):**
    * `Gitleaks v8.30.1` (con regla estricta `.gitleaks.toml`).
    * `Semgrep OSS v1.180.0` (reglas `.semgrep.yml` para bloquear llamadas inseguras de shell y bypass de TLS).
  2. **Código prestado (SCA + SBOM):**
    * `Trivy fs` (escaneo de vulnerabilidades HIGH/CRITICAL en dependencias).
    * Generación de **SBOM CycloneDX** (`sbom.cdx.json`) almacenado como artefacto del build.
     - `OSV-Scanner v2.6.0` (verificación de fuentes de dependencias abiertas). En la primera ejecución detectó `idna 3.9.0` con una vulnerabilidad conocida; se corrigió a `idna==3.15`.
  3. **Configuración (IaC Scanning):**
     - `Trivy config` sobre archivos de infraestructura (`infra/plc.tf`). Revisa la configuración declarada; hoy ese archivo solo define una variable y no tiene recursos que evaluar, por lo que no hay hallazgos de red.
- **Estado final del pipeline:** verde en la ejecución #18 (commit `64c3bb5`), después de corregir `idna`.

---

## 5. Matriz de Hallazgos y Toma de Decisiones

| Hallazgo Detectado                                                                               | Herramienta                                                     | Gravedad    | Decisión de Seguridad                    | Justificación Técnica y Operativa                                                                                                                                                                        | Responsable y Fecha             |
| ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------- | ----------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| Contraseña de fábrica del PLC (valor omitido por política de seguridad) escrita en `config.yaml` | Gitleaks                                                        | **CRÍTICA** | **Corregir Ahora**                       | Un secreto en código público permite a cualquiera intervenir la dosificación de la planta. Se retiró del archivo, se configuró `password_env: PLC_PASSWORD` y se inyecta desde GitHub Secrets.           | Desarrollador / 12-Oct-2026     |
| Credencial expuesta potencialmente guardada en historial antiguo de git                          | Revisión del equipo (el pipeline escanea solo el estado actual) | **ALTA**    | **Aceptar Temporalmente con Mitigación** | En el laboratorio de emergencia se retiró del archivo actual. Para producción se asume el secreto comprometido: se ejecuta rotación física de la contraseña en el PLC y se audita el registro de accesos. | Operador Planta / 12-Oct-2026   |
| Sin archivo de bloqueo (lockfile) con hashes para dependencias transitivas                       | Revisión del equipo                                             | **MEDIA**   | **Postergar con Fecha**                  | `requirements.txt` fija las dependencias directas con `==`, pero no hay lockfile con hashes que cubra las transitivas. Se calendariza para el siguiente sprint de mantención sin afectar la disponibilidad. | Guardián Pipeline / 19-Oct-2026 |
| Dependencia `idna` 3.9.0 con vulnerabilidad conocida (PYSEC-2026-215 / GHSA-65pc-fj4g-8rjx) declarada en `requirements.txt` | OSV-Scanner | **MEDIA** (CVSS 6.9) | **Corregir Ahora** | Un componente con una falla conocida en la cadena de suministro puede ser explotado. Se actualizó a `idna==3.15`, la versión corregida que indica OSV, fijada con `==`, y la ejecución #18 quedó en verde. | Desarrollador / 14-Oct-2026 |

---

## 6. Auditoría Forense al Parche de IA (Propuesta #7)

Llegó la pull request **Propuesta #7** generada por `asistente-ia`, prometiendo "arreglar la lectura del controlador". Se audita bajo las 4 preguntas obligatorias:

1. **¿Existe el paquete `plc_helper_utils`?**
  - **EVIDENCIA:** **NO EXISTE.** Se verificó en el índice oficial de Python ([PyPI.org](https://pypi.org/)). Es una **alucinación de paquete** (un error conocido de los asistentes de IA). Representa riesgo de *Package Squatting* (un atacante podría registrar ese nombre en PyPI y ejecutar código malicioso en nuestros servidores).
2. **¿Qué hace con la entrada?**
  - **EVIDENCIA:** Concatena directamente cadenas en el sistema operativo mediante:

```
cmd = "modpoll -r " + registro + " " + host
salida = subprocess.run(cmd, shell=True, capture_output=True)
```

El uso de `shell=True` con parámetros no sanitizados permite una **Inyección de Comandos Arbitrarios (Command Injection)** en el host que monitorea el agua.

3. **¿Apaga alguna protección de seguridad?**
  - **EVIDENCIA:** **SÍ.** Desactiva la verificación de certificados criptográficos en la conexión HTTP mediante:

```
requests.post(TELEMETRIA, verify=False, ...)
```

Esto anula TLS y permite ataques de intermediario (*Man-in-the-Middle*), donde un tercero puede interceptar o falsificar las lecturas de cloro.

4. **¿A dónde manda los datos de la planta?**
  - **EVIDENCIA:** Envía lecturas brutas a un endpoint externo no documentado (`https://telemetria.example.invalid/ingesta`), sin autenticación, sin cifrado verificado y sin aprobación del operador.

- **VEREDICTO FINAL:** **RECHAZADO.** El parche es inseguro: usa un paquete que no existe, ejecuta comandos armados con texto sin validar, desactiva la verificación TLS y envía las lecturas a un destino no autorizado.
- **Explicación redactada para el Operador de Planta (máx. 2 frases):**

  > *"Este parche usa un paquete que no existe, ejecuta comandos con texto sin validar y envía las lecturas del controlador a un destino no autorizado sin verificar la conexión segura. Si se instalara, alguien podría ejecutar órdenes en el equipo que lee el cloro o falsear esas lecturas, y eso pondría en riesgo la dosificación del agua."*

*(Revisada y aprobada por el Auditor de IA).*

---

## 7. Pendientes para el Paso a una Planta Real

Antes de desplegar esta solución en una sanitaria real (bajo fiscalización de la ANCI):

1. **Rotación de credenciales:** Cambiar la clave maestra en el PLC físico de la planta y revocar todas las sesiones previas.
2. **Segmentación Purdue e IEC 62443:** Implementar cortafuegos industriales y DMZ (Nivel 3.5) entre el servidor web de lecturas y el controlador N1, impidiendo cualquier tráfico que no sea Modbus sobre TLS o VPN con MFA.
3. **Firma Digital de Artefactos (Cosign / Sigstore):** Garantizar que solo los contenedores y scripts firmados criptográficamente por el equipo puedan ser descargados por los servidores de campo.
4. **Cumplimiento Legal Ley 21.663:** Notificar los protocolos de gestión de incidentes al CSIRT Nacional dentro del plazo legal exigido para Operadores de Importancia Vital.

---

## 8. Reproducción Técnica del Análisis

Para reproducir localmente o en un runner de CI/CD idéntico:

```
# 0. Instalar las herramientas con versión y huella SHA-256 fijas
for t in gitleaks semgrep trivy; do bash scripts/instalar.sh $t; done
export PATH=/tmp/herramientas:$PATH

# 1. Búsqueda determinista de secretos
gitleaks dir . --config .gitleaks.toml --redact --verbose

# 2. Análisis estático de código seguro
semgrep scan --config .semgrep.yml --error .

# 3. Verificación de infraestructura declarada
trivy config --severity HIGH,CRITICAL .

# 4. Generación de Lista de Materiales (SBOM)
trivy fs --format cyclonedx --output sbom.cdx.json .

# 5. Prueba funcional no destructiva
python3 scripts/prueba_funcional.py
```
