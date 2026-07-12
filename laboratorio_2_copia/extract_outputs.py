"""Extrae stdout/errores de un .ipynb ejecutado, para verificar resultados sin leer todo el JSON.

Uso:
    python extract_outputs.py "Segunda entrega de ejercicios - Solucion.ipynb"
"""
import json, sys

path = sys.argv[1]
nb = json.load(open(path, encoding="utf-8"))
for i, c in enumerate(nb["cells"]):
    if c["cell_type"] != "code":
        continue
    src = "".join(c["source"]) if isinstance(c["source"], list) else c["source"]
    first = src.strip().splitlines()[0] if src.strip() else "(vacia)"
    lines = []
    for o in c.get("outputs", []):
        if o.get("output_type") == "stream":
            t = o.get("text", "")
            lines.append("".join(t) if isinstance(t, list) else t)
        elif o.get("output_type") == "error":
            lines.append("ERROR: " + o.get("ename", "") + ": " + o.get("evalue", ""))
        elif o.get("output_type") == "execute_result":
            data = o.get("data", {}).get("text/plain", "")
            txt = "".join(data) if isinstance(data, list) else data
            lines.append(txt[:600])
    if lines:
        print(f"--- celda {i} | {first[:70]}")
        out = "\n".join(lines)
        print(out[:2500])
print("=== fin ===")
