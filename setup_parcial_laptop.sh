#!/usr/bin/env bash
# Setup del entorno para el parcial de Series Temporales (lun 13/7/2026).
# Idempotente: se puede correr N veces. Pensado para la laptop.
# Uso manual:  bash ~/Documents/ORT/series_temporales/setup_parcial_laptop.sh
# (Claude lo dispara solo por SSH cuando la laptop aparece en la tailnet.)
set -uo pipefail
cd "$(dirname "$0")"
exec > >(tee -a setup_parcial_laptop.log) 2>&1
echo "════ setup parcial — $(hostname) — $(date '+%F %T') ════"

export PATH="$HOME/.local/bin:$PATH"
FAIL=0

# ── 1. uv ────────────────────────────────────────────────────────────────
if ! command -v uv >/dev/null 2>&1; then
    echo "→ uv no está: instalando…"
    curl -LsSf https://astral.sh/uv/install.sh | sh || { echo "✗ instalación de uv FALLÓ"; exit 1; }
    export PATH="$HOME/.local/bin:$PATH"
fi
echo "✓ uv $(uv --version | cut -d' ' -f2)"

# ── 2. venv python 3.11 (pandas<2 no tiene wheels para 3.12) ────────────
if ! .venv/bin/python -c 'import sys' >/dev/null 2>&1; then
    rm -rf .venv
    uv venv --python 3.11 || { echo "✗ uv venv FALLÓ"; exit 1; }
fi
uv pip install --python .venv/bin/python \
    "pandas<2.0" "numpy<2" matplotlib statsmodels scipy astsadata jupyter ipykernel \
    2>&1 | tail -2 || { echo "✗ instalación de paquetes FALLÓ"; exit 1; }

# ── 3. material sincronizado (Syncthing puede estar aún bajando) ─────────
MATERIAL=(
  "preparacion_parcial/guia_rapida.md"
  "preparacion_parcial/toolkit_parcial.ipynb"
  "preparacion_parcial/parciales_resueltos/parcial_2025_resuelto.ipynb"
  "preparacion_parcial/parciales_resueltos/data_covid_uy.csv"
  "parciales/Parcial 2025 - enunciado para simulacro.ipynb"
)
echo "→ esperando material de Syncthing (máx 15 min)…"
for i in $(seq 1 90); do
    missing=0
    for f in "${MATERIAL[@]}"; do [ -f "$f" ] || missing=1; done
    [ "$missing" = 0 ] && break
    sleep 10
done
for f in "${MATERIAL[@]}"; do
    if [ -f "$f" ]; then echo "✓ $f"; else echo "✗ FALTA: $f (¿Syncthing corriendo?)"; FAIL=1; fi
done

# ── 4. smoke test (lo mismo que se validó en la PC) ─────────────────────
.venv/bin/python - <<'PY'
import warnings; warnings.filterwarnings('ignore')
import numpy as np, pandas as pd, matplotlib
import astsadata as astsa, statsmodels.api as sm
from statsmodels.formula.api import ols
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from statsmodels.tsa.arima.model import ARIMA
x = astsa.cardox.squeeze()
fit = ARIMA(x.diff().dropna().reset_index(drop=True), order=(1, 0, 1)).fit()
sm.tsa.UnobservedComponents(x[:120].reset_index(drop=True), level=True,
                            stochastic_level=True, seasonal=12).fit(disp=0)
try:
    pd.read_csv('preparacion_parcial/parciales_resueltos/data_covid_uy.csv')
    covid = 'covid.csv ✓'
except FileNotFoundError:
    covid = 'covid.csv PENDIENTE de sync'
print(f"✓ smoke test: numpy {np.__version__} | pandas {pd.__version__} | "
      f"statsmodels {sm.__version__} — ARIMA ✓ UnobservedComponents ✓ {covid}")
PY
[ $? -ne 0 ] && { echo "✗ smoke test FALLÓ"; FAIL=1; }

# ── 5. kernel para jupyter / VS Code ─────────────────────────────────────
.venv/bin/python -m ipykernel install --user --name parcial-apst \
    --display-name "Python (parcial apst)" >/dev/null \
    && echo "✓ kernel 'Python (parcial apst)' registrado" \
    || { echo "✗ registro de kernel FALLÓ"; FAIL=1; }

# ── 6. asistente / editor (informativo, no bloquea) ──────────────────────
if command -v claude >/dev/null 2>&1; then
    echo "✓ claude $(claude --version 2>/dev/null | head -1)"
else
    echo "⚠ claude NO instalado (terminal): curl -fsSL https://claude.ai/install.sh | bash"
fi
if command -v code >/dev/null 2>&1; then
    exts=$(code --list-extensions 2>/dev/null)
    for e in ms-python.python ms-toolsai.jupyter anthropic.claude-code; do
        if echo "$exts" | grep -qi "^$e$"; then
            echo "✓ VS Code ext: $e"
        else
            echo "→ instalando VS Code ext: $e"
            code --install-extension "$e" >/dev/null 2>&1 \
                && echo "✓ VS Code ext: $e (instalada)" \
                || echo "⚠ no se pudo instalar $e (instalar a mano si se quiere)"
        fi
    done
else
    echo "⚠ VS Code (code) no está en PATH — queda jupyter lab + claude en terminal"
fi

echo "════ RESULTADO: $([ $FAIL = 0 ] && echo 'TODO LISTO ✓' || echo 'CON PENDIENTES ⚠ (ver arriba)') ════"
echo "Para estudiar/parcial:  cd ~/Documents/ORT/series_temporales && .venv/bin/jupyter lab"
exit $FAIL
