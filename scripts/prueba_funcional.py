# scripts/prueba_funcional.py
# Comprueba que el servicio sigue funcionando y que la configuración
# referencia el secreto en lugar de contenerlo. Nunca imprime el secreto.
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, RAIZ)

from lector_cloro import leer_cloro_simulado  # noqa: E402

# 1) El archivo de configuración debe existir y apuntar al secreto por nombre.
ruta_config = os.path.join(RAIZ, "config.yaml")
if not os.path.exists(ruta_config):
    sys.exit("ERROR: falta config.yaml. Restaura el archivo y corrígelo; borrarlo no es una solución.")
with open(ruta_config, encoding="utf-8") as f:
    contenido = f.read()
if not re.search(r"^\s*password_env:\s*[\"']?PLC_PASSWORD[\"']?\s*$", contenido, re.M):
    sys.exit("ERROR: config.yaml debe indicar 'password_env: PLC_PASSWORD' (el nombre del secreto, no su valor).")

# 2) El secreto debe llegar a la aplicación como variable de entorno.
if not os.environ.get("PLC_PASSWORD"):
    if os.environ.get("GITHUB_ACTIONS") == "true":
        sys.exit(
            "ERROR: el secreto PLC_PASSWORD no llegó a la aplicación. "
            "Créalo en Settings > Secrets and variables > Actions (nombre exacto: PLC_PASSWORD)."
        )
    os.environ["PLC_PASSWORD"] = "VALOR-FICTICIO-DE-PRUEBA"  # solo para pruebas locales

resultado = leer_cloro_simulado()
assert resultado["cloro_mg_l"] == 0.7
print("Prueba funcional correcta; el secreto no fue mostrado")
