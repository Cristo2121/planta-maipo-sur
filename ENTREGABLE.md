# Ficha de blindaje · Planta de Agua Potable Maipo Sur

> **Expediente de Desarrollo Seguro y Gestión de Riesgo Operacional**
> Caso: Planta de Tratamiento y Distribución de Agua Potable «Maipo Sur» (80.000 habitantes).
> Alineado con Ley Marco de Ciberseguridad N° 21.663 (OIV), NIST SP 800-82 Rev. 3 e IEC 62443-4-1.

---

## 1. Sistema y equipo
- **Sector asignado:** Infraestructura Crítica Sanitaria · Agua Potable y Tratamiento.
- **Nombre del equipo:** Equipo 1 - Guardianes de Maipo Sur.
- **Asignación de roles:**
  - **Operador de planta (sin teclado / veto físico):** Encargado de la calidad sanitaria del agua y seguridad del proceso físico de cloración.
  - **Desarrollador (con teclado):** Modificación segura de archivos, aislamiento de credenciales y remediación de código.
  - **Guardián del pipeline (con teclado):** Configuración de compuertas automáticas en GitHub Actions (`seguridad.yml`) y análisis de logs.
  - **Auditor de IA (sin teclado):** Auditoría forense de dependencias, detección de alucinaciones y revisión de propuestas de asistentes de IA.
  - **Relator (sin teclado):** Redacción de la ficha técnica y exposición del criterio de riesgo ante la sala.

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

- **Archivo de evidencia gráfica subido:** `evidencias/diagrama_flujo_maipo_sur.png`

---

## 3. Tres Amenazas Priorizadas (Impacto Físico en el Agua)

| N° | Amenaza | Categoría STRIDE | Impacto en el Proceso Físico (Mundo Real) | Control que la Detecta / Mitiga |
|:--:|---|:---|---|---|
| **1** | **Adulteración de la dosificación de cloro en el PLC** | **Manipulación (Tampering)** | Si un atacante modifica las consignas de cloración, puede: <br>a) Reducir el cloro a 0 mg/L: distribución de agua sin desinfectar con bacterias (E. coli, cólera) a 80.000 personas.<br>b) Aumentar el cloro a niveles tóxicos (>5.0 mg/L): intoxicación química masiva, quemaduras en mucosas y corte del suministro comunal. | • Control 1: Validación estricta de rangos en código y Semgrep.<br>• Compuerta estricta: No permitir comandos no parametrizados hacia el bus Modbus. |
| **2** | **Toma de control del PLC por credencial de fábrica o expuesta** | **Suplantación (Spoofing) / Filtración (Information Disclosure)** | Acceso no autorizado al panel del controlador industrial (similar al incidente real de Aliquippa, Pensilvania, 2023 con PLC Unitronics). El atacante cambia la clave de acceso, bloquea al operador de turno y toma el control unilateral de las bombas de agua. | • Control 1: **Gitleaks** bloqueando credenciales en cada commit.<br>• GitHub Secrets (`PLC_PASSWORD`) para inyección segura en tiempo de ejecución.<br>• Procedimiento de rotación inmediata en el equipo físico. |
| **3** | **Secuestro de instrucciones y comandos vía Asistente de IA** | **Elevación de privilegios (Elevation of Privilege) / Inyección de instrucciones (LLM01 / LLM03)** | El asistente de turno con permisos sobre el SCADA recibe un prompt malicioso (inyección indirecta) que le ordena ejecutar llamadas directas al sistema operativo (`shell=True`). El atacante logra ejecución remota de código en la red de control sin pasar por la HMI. | • Control 1 (Semgrep): Regla `python-shell-true` que bloquea ejecución de shells arbitrarias.<br>• Política de Mínimo Privilegio: La IA solo consulta lecturas, jamás despacha consignas a actuadores. |

---

## 4. Controles Automáticos Ejecutados en el Pipeline
- **Enlace a la ejecución en GitHub Actions:** `https://github.com/Cristo2121/planta-maipo-sur/actions`
- **Controles ejecutados:**
  1. **Código propio (SAST + Detección de Secretos):** 
     - `Gitleaks v8.30.1` (con regla estricta `.gitleaks.toml`).
     - `Semgrep OSS v1.180.0` (reglas `.semgrep.yml` para bloquear llamadas inseguras de shell y bypass de TLS).
  2. **Código prestado (SCA + SBOM):**
     - `Trivy fs` (escaneo de vulnerabilidades HIGH/CRITICAL en dependencias).
     - Generación de **SBOM CycloneDX** (`sbom.cdx.json`) almacenado como artefacto del build.
     - `OSV-Scanner v2.6.0` (verificación de fuentes de dependencias abiertas).
  3. **Configuración (IaC Scanning):**
     - `Trivy config` sobre archivos de infraestructura (`infra/plc.tf`) verificando que no existan puertos industriales expuestos a `0.0.0.0/0`.
- **Estado final del pipeline:** **Visto verde (Passed)** tras corregir el secreto y verificar la prueba funcional.

---

## 5. Matriz de Hallazgos y Toma de Decisiones

| Hallazgo Detectado | Herramienta | Gravedad | Decisión de Seguridad | Justificación Técnica y Operativa | Responsable y Fecha |
|---|---|:---:|:---:|---|---|
| Contraseña fija del PLC (`LAB-CLORO-2026-DEMO`) escrita en `config.yaml` | Gitleaks | **CRÍTICA** | **Corregir Ahora** | Un secreto en código público permite a cualquiera intervenir la dosificación de la planta. Se retiró del archivo, se configuró `password_env: PLC_PASSWORD` y se inyecta desde GitHub Secrets. | Desarrollador / 12-Oct-2026 |
| Credencial expuesta potencialmente guardada en historial antiguo de git | Análisis Histórico (NIST PS) | **ALTA** | **Aceptar Temporalmente con Mitigación** | En el laboratorio de emergencia se retiró del archivo actual. Para producción se asume el secreto comprometido: se ejecuta rotación física de la contraseña en el PLC y se audita el registro de accesos. | Operador Planta / 12-Oct-2026 |
| Dependencias con versiones no fijadas en componentes auxiliares | Trivy SCA | **MEDIA** | **Postergar con Fecha** | Se identificó necesidad de fijar hashes exactos en todo el árbol de dependencias. Se calendariza para el siguiente sprint de mantención programada sin afectar la disponibilidad del servicio. | Guardián Pipeline / 19-Oct-2026 |

---

## 6. Auditoría Forense al Parche de IA (Propuesta #7)

Llegó la pull request **Propuesta #7** generada por `asistente-ia`, prometiendo "arreglar la lectura del controlador". Se audita bajo las 4 preguntas obligatorias:

1. **¿Existe el paquete `plc_helper_utils`?**
   - **EVIDENCIA:** **NO EXISTE.** Se verificó en el índice oficial de Python ([PyPI.org](https://pypi.org/)). Es una **alucinación de paquete** (típica en el 20% de códigos generados por LLMs). Representa riesgo de *Package Squatting* (un atacante podría registrar ese nombre en PyPI y ejecutar código malicioso en nuestros servidores).
2. **¿Qué hace con la entrada?**
   - **EVIDENCIA:** Concatena directamente cadenas en el sistema operativo mediante:
     ```python
     cmd = "modpoll -r " + registro + " " + host
     salida = subprocess.run(cmd, shell=True, capture_output=True)
     ```
     El uso de `shell=True` con parámetros no sanitizados permite una **Inyección de Comandos Arbitrarios (Command Injection)** en el host que monitorea el agua.
3. **¿Apaga alguna protección de seguridad?**
   - **EVIDENCIA:** **SÍ.** Desactiva la verificación de certificados criptográficos en la conexión HTTP mediante:
     ```python
     requests.post(TELEMETRIA, verify=False, ...)
     ```
     Esto anula TLS y permite ataques de intermediario (*Man-in-the-Middle*), donde un tercero puede interceptar o falsificar las lecturas de cloro.
4. **¿A dónde manda los datos de la planta?**
   - **EVIDENCIA:** Envía lecturas brutas a un endpoint externo no documentado (`https://telemetria.example.invalid/ingesta`), sin autenticación, sin cifrado verificado y sin aprobación del operador.

- **VEREDICTO FINAL:** **RECHAZADO ROTUNDAMENTE.** El cambio es funcionalmente fraudulento, vulnerable y expone datos operacionales críticos.
- **Explicación redactada para el Operador de Planta (máx. 2 frases):**
  > *"Este parche utiliza piezas de software inexistentes y abre una puerta trasera que permite a un atacante ejecutar órdenes en el equipo y alterar los niveles de cloro sin que el sistema genere alarmas. Su instalación pondría en riesgo directo la potabilidad del agua para la población."*
  *(Revisada y aprobada por el Auditor de IA).*

---

## 7. Pendientes para el Paso a una Planta Real
Antes de desplegar esta solución en una sanitaria real (bajo fiscalización de la ANCI):
1. **Rotación Criptográfica y Fírmica:** Cambiar la clave maestra en el PLC físico de la planta y revocar todas las sesiones previas.
2. **Segmentación Purdue e IEC 62443:** Implementar cortafuegos industriales y DMZ (Nivel 3.5) entre el servidor web de lecturas y el controlador N1, impidiendo cualquier tráfico que no sea Modbus sobre TLS o VPN con MFA.
3. **Firma Digital de Artefactos (Cosign / Sigstore):** Garantizar que solo los contenedores y scripts firmados criptográficamente por el equipo puedan ser descargados por los servidores de campo.
4. **Cumplimiento Legal Ley 21.663:** Notificar los protocolos de gestión de incidentes al CSIRT Nacional dentro del plazo legal exigido para Operadores de Importancia Vital.

---

## 8. Reproducción Técnica del Análisis
Para reproducir localmente o en un runner de CI/CD idéntico:
```bash
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
