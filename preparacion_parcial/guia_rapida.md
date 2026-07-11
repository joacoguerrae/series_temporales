# Guía rápida — qué hacer en cada tipo de ejercicio

Compañera del `toolkit_parcial.ipynb` (las referencias §A1, §B2, etc. son las secciones del toolkit).
Regla de oro: **cada parte del parcial termina con 2–3 oraciones de interpretación**. El código se copia; el comentario es lo que puntúa.

---

## 0. Los primeros 5 minutos del parcial

1. Ejecutar la celda de imports del enunciado y la de **"Funciones útiles"** (`ccf`, `periodogram`, `spectrum`) si viene incluida (2024 y 2025 la traían). Si no viene, copiarla del toolkit §0.
2. Abrir al lado: esta guía + el toolkit + el parcial resuelto más parecido.
3. Leer los 3 ejercicios ANTES de empezar y clasificarlos: ¿cuál es Tipo A, B, C, D? Repartir el tiempo (~⅓ cada uno) y arrancar por el que más sabés.
4. Si un dataset viene de `astsa`: es un **DataFrame** aunque tenga una sola columna → convertir con `.squeeze()` o `["columna"]`.

---

## Tipo A — Regresión: tendencia + estacionalidad

**Cómo reconocerlo:** "ajuste de tendencia lineal… agregar término cuadrático… periodograma… componentes estacionales…". Ejemplos: Ej1-2022 (cardox), Ej1-2023 (cpg), Ej1/Ej2-2024 (flu, cloud), Ej1-2025 (tmort).

| Paso | Qué hacer | Toolkit |
|------|-----------|---------|
| 1 | Graficar la serie. Comentar: tendencia (¿lineal? ¿acelerada?), estacionalidad visible, varianza (¿crece? → log). | §A1 |
| 2 | Si los valores crecen/decaen exponencialmente o la varianza crece con el nivel → transformar: `x = np.log(serie)` y justificarlo. | §B1 |
| 3 | Ajustar tendencia lineal: `ols('y ~ t', data=df).fit()`. Mirar `summary()`: signo y p-valor de la pendiente, R². Graficar ajuste y residuos. | §A2 |
| 4 | Agregar término cuadrático `I(t**2)`. Comparar con el anterior: ¿t² significativo? ¿baja el AIC? ¿los residuos pierden la curvatura? | §A2 |
| 5 | `periodogram(residuos, sampling_frequency=fs)` → identificar frecuencias dominantes. `spectrum(residuos, fs)` da la tabla ordenada. | §A3 |
| 6 | Agregar estacionalidad: armónicos `sin/cos` en las frecuencias del periodograma, **o** dummies mensuales `C(mes)`. Ajustar todo junto. | §A4 / §A5 |
| 7 | **Eliminar términos no significativos** (p > 0.05) y reajustar — decirlo explícitamente. | §A4 |
| 8 | Residuos finales: graficar + `plot_acf`. Casi siempre queda autocorrelación → decir que un ARMA podría modelarla. | §E1 |

**`sampling_frequency` del periodograma** = observaciones por unidad de tiempo "natural": mensual → 12 (frecuencias en ciclos/año; pico en 1 = ciclo anual), semanal → 52, diaria con ciclo semanal → 7, trimestral → 4. El pico en frecuencia f = período de 1/f unidades.

**Armónicos:** para datos mensuales con ciclo anual: `sin(2π·t/12)`, `cos(2π·t/12)`; armónico doble: `sin(4π·t/12)`, `cos(4π·t/12)`. **Siempre incluir sin y cos juntos** (fase libre); después podés eliminar el que no sea significativo.

---

## Tipo B — ARMA / ARIMA completo

**Cómo reconocerlo:** "¿es estacionaria?… ACF/PACF… ajustar ARMA(p,q)… residuos… predicción". Ejemplos: Ej2 de 2022/2023/2025, parte del Ej1-2024.

| Paso | Qué hacer | Toolkit |
|------|-----------|---------|
| 1 | Graficar. ¿Estacionaria? Checklist: media constante, varianza constante, sin tendencia ni estacionalidad. | §B1 |
| 2 | Si no lo es → transformar: tendencia → `diff()`; varianza creciente → `log`; crecimiento porcentual → `∇log = np.log(x).diff().dropna()`. Verificar que la transformada sí luzca estacionaria y decir si está centrada en 0 (media = drift). | §B1 |
| 3 | `plot_acf(x, bartlett_confint=False)` + `plot_pacf(x)` → elegir **dos candidatos** (p,q) con la tabla de abajo. | §B2 |
| 4 | Ajustar ambos: `ARIMA(x, order=(p,d,q)).fit()`. Si diferenciaste a mano, equivalente: ajustar la original con `d=1`. Comparar por **AIC** + significancia de coeficientes. | §B3 |
| 5 | Diagnóstico del elegido: `plot_diagnostics()` + `acorr_ljungbox`. | §B4 |
| 6 | Predicción: `get_forecast(pasos)` → `predicted_mean` + `conf_int()`. Graficar con banda. Si hubo `log` → deshacer con `np.exp` (§B6). | §B5 |

**Tabla de identificación (memorizala):**

| Modelo | ACF | PACF |
|--------|-----|------|
| AR(p) | decae (exponencial/sinusoidal) | **se corta tras lag p** |
| MA(q) | **se corta tras lag q** | decae |
| ARMA(p,q) | decae | decae |
| No estacionaria | decae MUY lento, casi lineal | — (diferenciar primero) |

- ¿Cuántos pasos predecir? "el año siguiente" = frecuencia de la serie: mensual → 12, trimestral → 4, anual → el número que pidan.
- La media del proceso la da `const` en el summary; la predicción de un ARMA estacionario **converge a esa media** y los IC se estabilizan.
- `d` = cuántas veces diferenciaste. "Ajustar a la serie original incluyendo el orden de integración" (2023) = `ARIMA(original, order=(p,1,q))` con `trend='t'` si la diferenciada tenía media ≠ 0 (drift). Más simple y aceptado: modelar la diferenciada con constante.

---

## Tipo C — Dos series: CCF + regresión con lag

**Cómo reconocerlo:** "correlación cruzada… lag de mayor correlación… modelo y_t = β₀ + β₁·x_{t−l}". Ejemplos: Ej3 de 2022/2023/2025, parte del Ej2-2024.

| Paso | Qué hacer | Toolkit |
|------|-----------|---------|
| 1 | Graficar ambas series (misma figura si escalas comparables). Si piden incrementos: `∇x = x.diff()`. | §C1 |
| 2 | `ccf(x, y, max_lag=...)` (función del curso). Comentar: ¿significativa? ¿de qué lado del 0 está el pico? | §C1 |
| 3 | Confirmar el lag numéricamente: `cors = pd.Series({l: y.corr(x.shift(l)) for l in range(0, L)})` → `l_opt = cors.idxmax()` (usar `.abs().idxmax()` si la correlación fuerte es negativa). | §C2 |
| 4 | Regresión laggeada: `datos = pd.DataFrame({'y': y, 'xlag': x.shift(l_opt)}).dropna()` → `ols('y ~ xlag', datos).fit()`. | §C3 |
| 5 | Varianza explicada = `fit.rsquared`. Señalar que R² = corr² (regresión simple). | §C3 |
| 6 | Graficar observado vs `fittedvalues` (la predicción arranca l pasos tarde — el enunciado lo suele recordar). | §C4 |
| 7 | Residuos + `plot_acf` → casi siempre queda estacionalidad/autocorrelación → proponer: agregar tendencia/estacionalidad, otros regresores, o ARMA en los residuos. | §E1 |

**Convención del lag:** `x.shift(l)` corre x hacia adelante → en la fila t queda x_{t−l}. `y.corr(x.shift(l))` = corr(y_t, x_{t−l}): si el máximo está en l > 0, **x adelanta a y** ("x es indicador líder"), que es lo que el modelo necesita.

---

## Tipo D — Espacio de estados (`UnobservedComponents`)

**Cómo reconocerlo:** "modelo estructural… level… stochastic_level… seasonal". Ejemplo: Ej3-2024 (COVID). Riesgo alto este año: el docente actualizó DLM para 2026.

| Paso | Qué hacer | Toolkit |
|------|-----------|---------|
| 1 | Armar y ajustar: `sm.tsa.UnobservedComponents(y, level=True, stochastic_level=True, seasonal=7, stochastic_seasonal=True).fit()`. Copiar los argumentos EXACTOS que pida el enunciado. | §D1 |
| 2 | Componentes: `res.plot_components(figsize=(12,9))`, o a mano: `res.level['smoothed']`, `res.seasonal['smoothed']`. | §D2 |
| 3 | Comentar: la tendencia (nivel) sigue la evolución suavizada; la componente estacional muestra el patrón (ej. semanal) y si cambia en el tiempo (por ser estocástica). | — |
| 4 | Si piden predicción: `res.get_forecast(k)` funciona igual que en ARIMA. | §B5 |

**Vocabulario para comentar:** es un **modelo lineal dinámico (DLM)**: estado no observado (nivel, estacionalidad) que evoluciona en el tiempo + observación con ruido; se estima con el **filtro de Kalman** (filtrado = usar el pasado; suavizado = usar toda la muestra). `stochastic_X=True` permite que la componente X **cambie en el tiempo** en lugar de ser fija.

---

## Plantillas de discusión (adaptar números y seguir)

- **Estacionariedad:** "La serie [no] parece estacionaria: la media [es constante / presenta tendencia creciente], la varianza [es estable / crece con el nivel] y [no] se observa estacionalidad. [Aplicamos ∇log para obtener el crecimiento porcentual aproximado, que sí luce estacionario y centrado en ~X]."
- **ACF/PACF:** "La ACF [decae exponencialmente / se corta tras el lag q] y la PACF [se corta tras el lag p / decae], patrón compatible con un [AR(p) / MA(q) / ARMA(p,q)]. Proponemos también [otro] para comparar."
- **Elección de modelo:** "Ambos ajustes tienen coeficientes significativos; el AIC favorece al [modelo] (X vs Y), por lo que lo seleccionamos, sujeto a que sus residuos queden limpios."
- **Residuos limpios:** "Los residuos oscilan alrededor de 0 sin patrón, su ACF queda dentro de las bandas y Ljung-Box no rechaza ruido blanco (p = X > 0.05); el QQ-plot es aproximadamente normal. El modelo capturó la dependencia temporal."
- **Residuos NO limpios:** "Los residuos aún muestran [autocorrelación en los primeros lags / estacionalidad de período X]: queda información por extraer; podría modelarse con [ARMA / componentes estacionales adicionales / otros regresores]."
- **Significancia:** "El término X no es significativo (p = Y > 0.05): lo eliminamos y reajustamos; el AIC [mejora / no empeora] con menos parámetros."
- **Predicción ARMA:** "La predicción converge a la media del proceso (≈X) — típico de un ARMA estacionario — y los IC se ensanchan con el horizonte hasta estabilizarse."
- **R²:** "El modelo explica el X% de la varianza (R² = 0.XX); en regresión simple coincide con el cuadrado de la correlación (r = 0.YY)."
- **Periodograma:** "El periodograma muestra un pico dominante en f = X ciclos/[unidad] (período 1/X), es decir, un ciclo [anual/semanal/...]; [aparece además el armónico 2f porque la onda no es sinusoidal pura]."

---

## Gotchas técnicos (errores que hacen perder tiempo)

1. **`astsa.X` es DataFrame** → `.squeeze()` antes de ARIMA/ols, o accedé a la columna (`astsa.lap['co']`).
2. **Forecast con fechas**: statsmodels necesita índice con frecuencia (PeriodIndex/DatetimeIndex). Si el índice son enteros pelados (Nile, climhyd, econ5), la predicción sale con índice posicional — o le asignás un `pd.period_range(...)` antes de ajustar, o interpretás las posiciones.
3. **`shift(l) + dropna()`**: `shift` genera NaN al inicio; alinear con `pd.DataFrame({...}).dropna()` ANTES de `ols`, si no, error o resultados basura.
4. **`diff()` deja NaN en la primera posición** → `.dropna()` antes de ACF/ARIMA.
5. **`plot_acf(..., bartlett_confint=False)`** — así lo usa el curso; con `True` (default) las bandas crecen con el lag y se leen distinto.
6. **Banda del forecast**: `plt.fill_between(ci.index, ci.iloc[:,0], ci.iloc[:,1], alpha=0.2)` — con `iloc` no dependés del nombre de las columnas (cambia según el nombre de la serie).
7. **Deshacer transformaciones**: solo log → `np.exp(pred)`; ∇log → `np.exp(np.cumsum(pred)) * último_valor_original` (§B6). Si ajustaste `ARIMA(log_x, order=(p,1,q))`, `get_forecast` ya predice log_x (la integración la hace el modelo) → solo falta `np.exp`.
8. **Dummies con fórmula**: crear la columna `mes = x.index.month` y usar `C(mes)` — statsmodels arma las k−1 dummies solo.
9. **Fórmulas `ols`**: potencias van dentro de `I(...)`: `y ~ t + I(t**2)`. Los nombres de columnas no pueden tener espacios.
10. **`plot_components()` de `UnobservedComponents` no soporta PeriodIndex** (los datasets de astsa vienen así): convertí antes de ajustar → `y.index = y.index.to_timestamp()`. Con datos de CSV (DatetimeIndex, como el COVID de 2024) no hace falta.
11. **No busques el modelo perfecto**: 2 candidatos, AIC, residuos, elegir, seguir. El tiempo vale más que la tercera cifra decimal del AIC.
