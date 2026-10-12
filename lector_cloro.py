# lector_cloro.py - aplicación simulada (laboratorio)
# No se conecta a ningún controlador real. Solo valida que PLC_PASSWORD existe
# y devuelve una lectura preparada. Nunca imprime el secreto.
import os


def leer_cloro_simulado():
    if not os.getenv("PLC_PASSWORD"):
        raise RuntimeError("Falta la variable PLC_PASSWORD")
    return {"planta": "Maipo Sur - laboratorio", "cloro_mg_l": 0.7}


if __name__ == "__main__":
    lectura = leer_cloro_simulado()
    print(f"Lectura simulada: {lectura['cloro_mg_l']} mg/L")
