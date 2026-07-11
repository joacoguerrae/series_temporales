# Plan de estudio — Parcial de Análisis Predictivo de Series Temporales

**Parcial: lunes 13/7/2026 · en computadora, con material · presupuesto: ~1.5 h/día ≈ 11 h totales**

---

## 1. Qué muestran los parciales 2022–2025

La estructura es casi idéntica todos los años: **3 ejercicios que repiten los mismos tipos**.

| Tipo | Patrón que se repite | Apareció en |
|------|----------------------|-------------|
| **A — Regresión: tendencia + estacionalidad** | Ajustar tendencia lineal → agregar término cuadrático y comparar → periodograma de los residuos → agregar componentes estacionales (armónicos sin/cos o dummies mensuales) → discutir residuos finales | 2022, 2023, 2024 (×2), 2025 → **4/4** |
| **B — ARMA/ARIMA completo** | ¿Es estacionaria? → transformar (log, ∇, ∇log) → ACF/PACF → proponer y ajustar 2 modelos ARMA(p,q) → comparar (AIC, residuos) → predecir con intervalos de confianza | 2022, 2023, 2024, 2025 → **4/4** |
| **C — Dos series: CCF + regresión con lag** | CCF entre x e y → lag de máxima correlación → regresión `y_t = β0 + β1·x_{t−l}` → varianza explicada (R²) → graficar predicción vs observado → residuos | 2022, 2023, 2024, 2025 → **4/4** |
| **D — Espacio de estados (`UnobservedComponents`)** | Modelo estructural con nivel y estacionalidad estocásticos, graficar componentes | solo 2024 → **1/4** |

Habilidades transversales que aparecen en **todos** los ejercicios de **todos** los años:

- **Análisis de residuos** (graficar, ACF de residuos, ¿queda información por extraer?)
- **Transformaciones**: `log`, `diff` (∇), `∇log` como incremento porcentual — y saber deshacerlas
- **Discusión escrita**: cada parte pide "discutir / analizar / comentar"

> **La clave del parcial**: es con material y en computadora, así que el código lo vas a poder copiar del toolkit. Lo que te diferencia es la **interpretación** (qué decís del ACF, de los residuos, de la estacionariedad). Cada día de práctica termina escribiendo las discusiones, no solo corriendo celdas.

Dato útil: los parciales 2024 y 2025 traen en el propio enunciado una celda **"Funciones útiles"** con `ccf`, `periodogram` y `spectrum` ya implementadas. Conocerlas de antemano = tiempo ganado.

---

## 2. Prioridades

### Tier 1 — Sí o sí (≈80–90% del parcial histórico)
- Tipo A: regresión con tendencia + periodograma + estacionalidad
- Tipo B: identificación y ajuste ARMA/ARIMA + predicción con IC
- Tipo C: CCF + regresión con lag
- Residuos, transformaciones y discusión escrita (transversal)

### Tier 2 — Probable este año
- `UnobservedComponents` (apareció en 2024, **y el docente actualizó los ejemplos de DLM para 2026** — commits recientes del repo). Saber la receta y qué significa cada componente. Idea conceptual de DLM/filtro de Kalman para poder comentar.

### Tier 3 — Te lo podés saltear (0/4 apariciones)
- **HMM** (Modelos Markovianos Escondidos): solo saber qué son, 2 líneas.
- **Redes neuronales / ML**: solo conceptual; si cayera, va a venir muy guiado.
- **Regresión no lineal** más allá de transformación log.
- Teoría espectral profunda (densidad espectral, aliasing): alcanza el uso práctico del periodograma.
- GARCH / biblioteca `arch`: nunca apareció.

---

## 3. Funciones que tenés que dominar

| Para qué | Función / receta |
|----------|------------------|
| Regresión con fórmulas | `ols("y ~ t + I(t**2)", data).fit()` → `.summary()`, `.params`, `.resid`, `.fittedvalues`, `.predict()` |
| Variables de tiempo | `t = np.arange(len(x))`; armónicos `np.sin(2*np.pi*f*t)`, `np.cos(...)`; dummies con `C(mes)` en la fórmula |
| Transformar / deshacer | `np.log(x)`, `x.diff()`; deshacer: `np.exp`, `.cumsum()` + valor inicial |
| Autocorrelación | `plot_acf(x, bartlett_confint=False)`, `plot_pacf(x)` (de `statsmodels.graphics.tsaplots`) |
| Espectro | `periodogram(x, fs)`, `spectrum(x, fs, nfreq)` — funciones del curso (vienen en el enunciado) |
| Correlación cruzada | `ccf(x, y, max_lag)` — función del curso; lag para regresión: `x.shift(l)` |
| ARIMA | `ARIMA(x, order=(p,d,q)).fit()` (de `statsmodels.tsa.arima.model`) → `.summary()`, `.aic`, `.resid`, `.plot_diagnostics()` |
| Predicción | `fit.get_forecast(steps)` → `.predicted_mean`, `.conf_int()`; predicción recursiva con `fit.append(datos_test)` |
| Test de residuos | `sm.stats.acorr_ljungbox(resid, lags=[...])` |
| Espacio de estados | `sm.tsa.UnobservedComponents(y, level=True, stochastic_level=True, seasonal=7, stochastic_seasonal=True).fit()` → componentes suavizadas y gráficos |
| Bondad de ajuste | `fit.rsquared` (varianza explicada), MSE de predicción a mano |

---

## 4. Plan día por día (bloques de ~1.5 h)

| Día | Foco | Qué hacer |
|-----|------|-----------|
| **Dom 5 (hoy)** | Setup + panorama | Activar el entorno `apst` y verificar `import astsadata`. Leer la letra de los 4 parciales (sin resolverlos) para reconocer el patrón A-B-C. Hojeada rápida a `2- Analisis exploratorio/Modelos lineales.ipynb`. |
| **Lun 6** | Tipo A | Resolver de cero el **Ej. 1 del 2022** (`cardox`), cronometrando ~50 min. Comparar contra la solución. Repasar periodograma y armónicos con `Analisis espectral.ipynb`. Anotar en la guía lo que te trabó. |
| **Mar 7** | Tipo B (1/2): identificar | `Modelos autorregresivos y autocorrelacion parcial.ipynb` + `Modelos de media movil y ARMA.ipynb`: internalizar la tabla ACF/PACF → (p,q). Resolver **Ej. 2 del 2022** (`Nile`). |
| **Mié 8** | Tipo B (2/2): ARIMA + predicción | Resolver **Ej. 2 del 2023** (`sales`): diferenciación, orden de integración, comparar 2 modelos, predicción 1970 con IC. Practicar Ljung-Box y `plot_diagnostics`. |
| **Jue 9** | Tipo C | Resolver **Ej. 3 del 2022** (`co` → `rmort`). Si sobra tiempo, **Ej. 3 del 2023**. Receta fija: ccf → lag máximo → shift → ols → R² → gráfico predicción vs real → residuos. |
| **Vie 10** | Tipo D | Pasada rápida a `4- .../Modelo lineal dinamico.ipynb` (conceptos, no derivaciones) + resolver **Ej. 3 del 2024** (`UnobservedComponents` con la serie COVID). Dejar la receta UC escrita en la guía. |
| **Sáb 11** | **SIMULACRO** | **Parcial 2025 completo, cronometrado** con la duración real, usando solo el material que vas a tener el 13 (guía + toolkit + notebooks del curso). Después: corregir contra la solución y anotar cada cosa que te frenó. Es el día que más rinde — si podés estirarlo a 2.5–3 h, mejor. |
| **Dom 12** | Cierre | Repasar solo lo que falló en el simulacro. Opcional si hay energía: **Ej. 1 del 2024** (`flu`) — el más integrador (regresión + dummies + ARMA sobre residuos + `fit.append` + deshacer el log). 15 min conceptuales de HMM y redes (Tier 3). Terminar temprano y descansar. |

**Regla de la semana**: siempre práctica primero, teoría solo para destrabar. Cada ejercicio resuelto termina con vos escribiendo las frases de discusión de cada parte.

---

## 5. El día del parcial (lun 13)

1. Primera acción: correr la celda de imports + "Funciones útiles" del enunciado; abrir la guía rápida y el toolkit al lado.
2. Time-box: ~⅓ del tiempo por ejercicio. Si una parte te traba más de 10 min, escribí lo que interpretás en texto y seguí — las partes siguientes no suelen depender del resultado exacto.
3. En **cada** parte escribí 2–3 oraciones de discusión (hay plantillas en la guía). Parte sin comentario = puntos regalados.
4. Cuando diga "puede incorporar dos modelos para comparar": ajustá 2, compará AIC y ACF de residuos, elegí uno y seguí. No busques el modelo perfecto.
5. Graficá todo lo que pidan graficar, con título y leyenda — es barato y suma.

---

## 6. Material de apoyo (ya está todo listo ✓)

1. **`guia_rapida.md`** ✓ — receta paso a paso por tipo de ejercicio (A, B, C, D) + plantillas de discusión + gotchas.
2. **`toolkit_parcial.ipynb`** ✓ — celdas listas para copiar/pegar, ejecutado y verificado con series demo reales.
3. **`parciales_resueltos/`** ✓ — los 4 parciales resueltos, ejecutados y verificados (código + discusiones modelo + gráficos). Incluye `data_covid_uy.csv` cacheado para que el Ej. 3 del 2024 funcione sin internet.

⚠️ El parcial 2025 resuelto NO lo mires antes del simulacro del sábado 11: es tu examen de práctica.
