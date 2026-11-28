#!/usr/bin/env python3
"""Compara los parametros del HPS entre el .qsys de Terasic y el del repo.

Uso: python3 verify_hps.py ORIGEN.qsys DESTINO.qsys
"""
import sys
import xml.etree.ElementTree as ET


def hps_params(path):
    root = ET.parse(path).getroot()
    m = next(m for m in root.iter("module") if m.get("kind") == "altera_hps")
    out = {}
    for p in m.findall("parameter"):
        v = p.get("value")
        out[p.get("name")] = (p.text or "") if v is None else v
    return out


a = hps_params(sys.argv[1])
b = hps_params(sys.argv[2])
dif = sorted(n for n in a if n in b and a[n] != b[n] and not n.startswith("AUTO_"))
falta = sorted(n for n in a if n not in b and not n.startswith("AUTO_"))
print("Parametros distintos:", len(dif))
for n in dif:
    print("  ", n, "| origen:", a[n][:40], "| repo:", b[n][:40])
print("Parametros que no estan en el repo:", len(falta))
for n in falta[:40]:
    print("  ", n)
