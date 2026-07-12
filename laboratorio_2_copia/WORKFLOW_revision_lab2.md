# WORKFLOW — Revisión y completado del Laboratorio 2 (Ejercicios 2 a 5)

**Archivo a modificar:** `Segunda entrega de ejercicios - Solucion.ipynb` (esta misma carpeta)
**Entrega:** 13/7/2026 vía GitHub Classroom · Equipo: Ramiro Sanes y Joaquín Guerra
**Objetivo:** dejar el notebook completo, ejecutado de punta a punta, con TODAS las conclusiones respaldadas por los números y gráficos que el propio notebook produce. Nivel: maestría — sólido y dentro de lo dictado en el curso, sin sofisticación extra.

**El Ejercicio 1 NO SE TOCA** (ya fue corregido el 12/7). Solo verificar en la pasada final que sus números no cambien al re-ejecutar.

---

## 0. Estado actual (diagnóstico ya hecho — confiar en esto)

| Ej. | Estado | Problemas detectados |
|-----|--------|----------------------|
| 2 (cmort) | Ejecutado (18/6) | **Bug de especificación**: `trend="t"` sin intercepto → pendiente n.s. (p=0.788) y AR casi integrado (ar.L1+ar.L2=0.998). Interpretación de la predicción no verificada contra el gráfico. Ljung-Box corto (lag 10) no chequea estacionalidad anual (lag 52). |
| 3 (varve) | Parcialmente ejecutado | **Conclusión 3.3 INVERTIDA respecto a sus propios números** (elige MA(1) cuando todo favorece ARMA(1,1)). Falta análisis de residuos del modelo elegido. 3.4 incompleto (falta ARIMA(1,1,1)). **3.5 tiene un bug que lanza excepción** (`trend="c"` con d=1) y nunca fue ejecutado. |
| 4 (AirPassengers) | **Nunca ejecutado** | Índice de strings romperá la predicción/plot. Falta Ljung-Box numérico. **Falta la mitad del enunciado**: la comparación con senos y cosenos. Conclusión escrita de antemano con "captura perfectamente" — prohibido. |
| 5 (log jj) | **Nunca ejecutado** | Conclusión hipotética ("suele ser suficiente", "si el AIC mejora…") escrita sin correr nada. Hay que ejecutar y responder las preguntas del enunciado con números. |

---

## 1. Reglas de oro (aplican a TODO el trabajo)

### 1.1 Grounding: toda afirmación cita un número
- Cada conclusión debe citar los valores concretos que la respaldan: AIC/BIC con sus deltas, p-valores de Ljung-Box, p-valores de coeficientes, RMSE.
- Si un texto ya escrito contradice el output de la celda, **se corrige el texto, jamás se fuerza la interpretación**.
- **Vocabulario prohibido en conclusiones**: "perfectamente", "claramente" (sin número al lado), "suele", "aproximadamente ruido blanco" (sin p-valor citado), "mejora marginal/sustancial" (sin el Δ), y cualquier condicional hipotético del estilo "si el AIC mejora, entonces…" — el AIC ya está impreso: mirarlo y afirmar.

### 1.2 Interpretación de ΔAIC/ΔBIC entre modelos (misma variable dependiente)
| Δ | Lectura |
|---|---------|
| < 2 | Equivalentes → elegir el más simple (parsimonia) |
| 2–10 | Soporte débil para el peor |
| > 10 | Concluyente a favor del menor |

Nunca comparar AIC de modelos ajustados a variables distintas (x vs log(x) vs diff(x)).

### 1.3 Lectura de Ljung-Box
- `acorr_ljungbox(resid, lags=10)` (entero) devuelve la tabla acumulada 1..10: **si CUALQUIER fila temprana rechaza (p<0.05), los residuos NO son ruido blanco** — aunque las últimas filas no rechacen (la señal se diluye al acumular lags).
- Agregar SIEMPRE un horizonte largo acorde a la frecuencia: semanal → `lags=[52]`, mensual → `lags=[24]`, trimestral → `lags=[8]`. Un LB corto no ve estacionalidad remanente.

### 1.4 Alcance (solo lo dictado en el curso)
- **Permitido**: `ols` (statsmodels formula), `ARIMA` (incl. `seasonal_order` — SARIMA está en `3- Modelos ARMA y ARIMA/Modelos ARMA generalizados y resumen.ipynb` del repo del curso), `UnobservedComponents`, `plot_acf`/`plot_pacf` (con `bartlett_confint=False` en ACF), `qqplot`, `acorr_ljungbox`, `plot_diagnostics`, `get_forecast`/`get_prediction`, `fit.append`, armónicos sin/cos, dummies.
- **Prohibido**: `pmdarima`/`auto_arima`, tests ADF/KPSS, prophet, sklearn, GARCH, grid searches masivos, features exógenas inventadas. Si algo no aparece en los notebooks del curso (`C:\Users\joaco\Documents\ort\semestre_3\curso_series_temporales\`), no va.

### 1.5 Estilo de las conclusiones
2 a 4 oraciones, en español, primera persona del plural ("ajustamos", "elegimos"). Estructura: (1) qué muestran los números, (2) decisión que se toma, (3) limitación honesta si la hay.

---

## 2. Setup técnico (leer antes de ejecutar nada)

### 2.1 Cómo ejecutar el notebook (crítico en esta máquina)
**NUNCA** invocar `C:\Users\joaco\anaconda3\envs\apst\python.exe` directo para nbconvert: el kernel muere con excepción 0xc06d007f (DLLs de MKL sin el PATH de activación). Usar SIEMPRE:

```powershell
$env:JUPYTER_RUNTIME_DIR = "$env:TEMP\jrt"
New-Item -ItemType Directory -Force "$env:TEMP\jrt" | Out-Null
& "C:\Users\joaco\anaconda3\Scripts\conda.exe" run -n apst python -m nbconvert --to notebook --execute --inplace "C:\Users\joaco\Documents\ort\semestre_3\series_temporales\laboratorio_2_copia\Segunda entrega de ejercicios - Solucion.ipynb"
```

nbconvert ejecuta con cwd = carpeta del notebook, así que la ruta relativa `data/international-airline-passengers.csv` del Ej. 4 funciona (el CSV existe en `laboratorio_2_copia\data\`).

### 2.2 Cómo verificar outputs sin leer todo el JSON
En esta carpeta está `extract_outputs.py`. Después de cada ejecución:

```powershell
& "C:\Users\joaco\anaconda3\envs\apst\python.exe" "C:\Users\joaco\Documents\ort\semestre_3\series_temporales\laboratorio_2_copia\extract_outputs.py" "C:\Users\joaco\Documents\ort\semestre_3\series_temporales\laboratorio_2_copia\Segunda entrega de ejercicios - Solucion.ipynb"
```
(este script sí puede correr con python.exe directo — no levanta kernel). Imprime stdout/errores por celda. Buscar `ERROR` primero; después extraer los números para las conclusiones.

### 2.3 Cómo editar celdas
Usar `Read` sobre el notebook (da los `cell id`) y `NotebookEdit` con ese id. Los ids relevantes están citados en cada paso de este workflow.

### 2.4 Gotchas conocidos de este stack (ya nos mordieron antes)
1. `ARIMA(..., trend="c")` con `d=1` **lanza ValueError** (término de orden menor que d se elimina al diferenciar). Con d=1 usar `trend="n"` (o `"t"` si se quiere drift).
2. `trend="t"` NO incluye intercepto; para nivel + pendiente es `trend="ct"`.
3. Datasets de `astsa` son DataFrames → `.squeeze()` antes de ARIMA/UC.
4. Índices sin frecuencia (strings, enteros) → statsmodels predice con índice posicional y los plots quedan desalineados. Asignar `pd.period_range(...)` antes de ajustar.
5. En `ols`, los nombres de términos en `fit.pvalues` son los de patsy (`I(t ** 2)` con espacios) — si se filtra por p-valor, iterar sobre `fit.pvalues.index`, no sobre strings propios.
6. `plot_components()` de UnobservedComponents no acepta PeriodIndex → si se usa, convertir antes con `serie.index = serie.index.to_timestamp()`. (En el Ej. 5 actual no se usa `plot_components`, así que solo aplica si se agrega.)

---

## 3. EJERCICIO 2 — cmort (AR con tendencia + predicción a 1 año)

**Enunciado**: ajustar AR de orden adecuado a `cmort`, predecir el año siguiente, estimando primero la tendencia. Componente estacional: opcional.

### Paso 2.1 — Corregir la especificación del modelo (celda `9ef76b9d`)
Problema: `trend="t"` no incluye intercepto → la pendiente dio 0.0649 con p=0.788 (no significativa, ¡y positiva cuando la serie decrece!) y el AR se fue a la frontera (ar.L1+ar.L2 = 0.998). Reemplazar el contenido por:

```python
# Ajuste AR(2) con nivel + tendencia lineal (trend="ct": intercepto + pendiente)
fit_ar2 = ARIMA(cmort, order=(2, 0, 0), trend="ct").fit()
print(fit_ar2.summary())
```

### Paso 2.2 — Ejecutar y verificar
Tras ejecutar, en el summary verificar:
- [ ] `x1` (pendiente) **negativa** y con p < 0.05 (la serie baja de ~97 a ~85 en 508 semanas → esperar pendiente ≈ −0.02 semanal).
- [ ] ar.L1 + ar.L2 razonablemente < 1 (esperar ≈ 0.85–0.9; ya no en la frontera).
- [ ] Ljung-Box de la celda `f5f87558`: todas las filas con p > 0.05.

Si la pendiente diera no significativa incluso con "ct", NO ocultarlo: reportarlo y mantener el modelo de dos pasos (ols + AR(2) sobre residuos, que ya está hecho arriba en el notebook) como especificación final.

### Paso 2.3 — Chequeo de estacionalidad remanente (nuevo, insertar tras celda `f5f87558`)
```python
# La mortalidad tiene ciclo anual (52 semanas): chequear horizonte largo
print(acorr_ljungbox(fit_ar2.resid, lags=[10, 26, 52]))
fig, ax = plt.subplots(figsize=(15, 3))
plot_acf(fit_ar2.resid, lags=60, bartlett_confint=False, ax=ax, title="ACF residuos hasta lag 60");
```
- Si lag 52 rechaza (p<0.05) o se ve onda anual en la ACF: agregar la componente estacional opcional (armónicos): regresión `ols('cmort ~ t + sin1 + cos1', ...)` con `sin1=np.sin(2*np.pi*t/52)`, `cos1=np.cos(2*np.pi*t/52)` + AR(2) sobre sus residuos (mismo patrón del Ej. 1.2/1.3). Es lo que el enunciado deja como opcional — hacerlo solo si el LB largo lo justifica.
- Si no rechaza: mencionar en la conclusión que se chequeó hasta el lag 52 sin evidencia de estacionalidad remanente (con el p-valor).

### Paso 2.4 — Verificar la interpretación de la predicción (celda `3aa0178a`)
El texto actual afirma "la predicción sigue la tendencia decreciente" sin haberlo verificado. Tras re-ejecutar la celda `2b27acc1` (la predicción), mirar el gráfico y los valores de `xhat`: ¿la media predicha baja a lo largo de las 52 semanas? (con trend="ct" debería: pendiente ≈ β·52 ≈ −1 a −2 unidades en el año).

**Plantilla de conclusión (reemplazar celda `3aa0178a`):**
> **Interpretación:** El modelo final es un AR(2) con tendencia lineal (pendiente = [X.XXX], p = [X.XXX]): la mortalidad media desciende ≈ [X.X] unidades por año. La predicción a 52 semanas parte del último valor observado, converge hacia la tendencia estimada y su intervalo de confianza se ensancha hasta estabilizarse en ≈ ±[X] unidades, reflejando que el AR(2) estacionario agota su memoria en pocas semanas. El test de Ljung-Box sobre los residuos no rechaza ruido blanco ni en horizonte corto ni anual (p = [X.XX] en lag 10, [X.XX] en lag 52).

(Llenar los [X] con el output real. Si se agregó estacionalidad, mencionar los armónicos y su significancia.)

---

## 4. EJERCICIO 3 — varve (MA/ARMA + ARIMA d=1 + proyección)

### Paso 3.1 — CORREGIR la conclusión invertida (celda `7b1c0a1d`) ⚠️ EL ERROR MÁS GRAVE DEL NOTEBOOK
El texto actual dice "El MA(1) es suficiente; los residuos quedan ruido blanco… el ARMA(1,1) tiene criterios ligeramente peores… el coeficiente AR no es significativo". **Los outputs impresos dicen EXACTAMENTE lo contrario**:
- Ljung-Box del MA(1) (celda `c1145597`): rechaza en TODAS las filas 1–10 (p entre 0.002 y 0.045) → los residuos del MA(1) NO son ruido blanco.
- AIC: ARMA(1,1) 870.66 vs MA(1) 887.36 → Δ = 16.7 a favor del ARMA. BIC: 888.47 vs 900.71 → Δ = 12.2. Ambos concluyentes (>10).
- ar.L1 = 0.2341 con z = 5.34, p < 0.001 → **sí** es significativo.

**Reemplazar la celda `7b1c0a1d` por:**
> **Conclusión:** El MA(1) resulta **insuficiente**: el test de Ljung-Box sobre sus residuos rechaza la hipótesis de ruido blanco en todos los horizontes de 1 a 10 lags (p entre 0.002 y 0.045), evidenciando autocorrelación remanente. El ARMA(1,1) lo supera de forma concluyente: AIC 870.66 vs 887.36 (Δ = 16.7) y BIC 888.47 vs 900.71 (Δ = 12.2), con el coeficiente AR claramente significativo (ar.L1 = 0.234, p < 0.001). Se selecciona el **ARMA(1,1)**, sujeto al análisis de sus residuos (celda siguiente).

### Paso 3.2 — Agregar análisis de residuos del modelo elegido (insertar DESPUÉS de `c1145597`, ANTES de `7b1c0a1d`)
El enunciado pide "ajuste el modelo resultante y analice los residuos" — hoy solo se analizan los del MA(1) descartado. Insertar celda de código:

```python
# Residuos del modelo elegido: ARMA(1,1)
res_arma = fit_arma11.resid
fig, axs = plt.subplots(1, 3, figsize=(18, 4))
res_arma.plot(ax=axs[0], title=f"Residuos ARMA(1,1)  RMSE={np.std(res_arma):.4f}")
plot_acf(res_arma, bartlett_confint=False, ax=axs[1], title="ACF residuos ARMA(1,1)")
qqplot(res_arma, line='s', ax=axs[2]);
```
y otra:
```python
print("Ljung-Box — ARMA(1,1):")
print(acorr_ljungbox(res_arma, lags=10))
```
**Verificar**: los p-valores del ARMA(1,1) deberían quedar > 0.05 (si alguna fila temprana rechazara, decirlo honestamente en la conclusión y comentar que aun así es el mejor candidato de los probados). Agregar 1–2 oraciones después de la celda citando los p reales y el QQ-plot (colas).

### Paso 3.3 — Completar 3.4 con el ARIMA(1,1,1) (celda `9e71844d`)
"Aplicar el análisis anterior directamente" con d=1 → el análisis anterior ahora concluye ARMA(1,1), así que corresponde ARIMA(1,1,1). Reemplazar la celda por:

```python
# El modelo elegido en 3.3 fue ARMA(1,1) sobre diff(log) -> equivale a ARIMA(1,1,1) sobre log(varve)
fit_arima = ARIMA(log_varve.squeeze(), order=(1, 1, 1), trend="n").fit()
print(fit_arima.summary())

# Verificación de equivalencia con 3.3 (mismos coeficientes salvo detalles numéricos):
print(f"\nARMA(1,1) sobre diff : ar={fit_arma11.params['ar.L1']:.4f}  ma={fit_arma11.params['ma.L1']:.4f}")
print(f"ARIMA(1,1,1) directo : ar={fit_arima.params['ar.L1']:.4f}  ma={fit_arima.params['ma.L1']:.4f}")
```
Agregar celda markdown debajo: la equivalencia diferenciar-a-mano vs d=1 (coeficientes casi idénticos, [citar valores]; la ventaja de d=1 es que `get_forecast` devuelve predicciones en la escala de log(varve) directamente, sin acumular). La constante se omite (`trend="n"`) porque en 3.3 la const fue no significativa (p = 0.646 en el ARMA(1,1)) — la media de diff(log(varve)) ≈ −0.0013 no difiere de 0.

### Paso 3.4 — Arreglar el bug de 3.5 (celda `64e69611`)
`ARIMA(log_varve_train, order=(0,1,1), trend="c")` **lanza ValueError** (regla 2.4.1). Además el orden debe ser el elegido. Reemplazar por:

```python
fit_train = ARIMA(log_varve_train.squeeze(), order=(1, 1, 1), trend="n").fit()
print(fit_train.summary().tables[1])
```

### Paso 3.5 — Completar 3.5: proyección multi-paso + recursiva (celda `e81e73a0` y `3d35a959`)
"Proyectar los restantes 34" = predicción multi-paso desde n=600 (lo que el código actual NO hace: `append` + `get_prediction` sobre el test es predicción recursiva a un paso, que usa los datos reales del test). Mostrar AMBAS, etiquetadas correctamente. Reemplazar `e81e73a0` por:

```python
# (a) PROYECCIÓN multi-paso: 34 pasos desde el final del train (sin ver el test)
fc = fit_train.get_forecast(34)
proy = fc.predicted_mean
ci_p = fc.conf_int(alpha=0.05)

# (b) Predicción RECURSIVA a un paso: incorpora cada dato real del test a medida que llega
fit_with_test = fit_train.append(log_varve_test.squeeze())
rec = fit_with_test.get_prediction(start=log_varve_test.index[0], end=log_varve_test.index[-1]).predicted_mean

log_varve.squeeze().iloc[-120:].plot(label="log(varve) observado", alpha=0.6)
proy.plot(label="Proyección multi-paso (34)")
plt.fill_between(ci_p.index, ci_p.iloc[:, 0], ci_p.iloc[:, 1], alpha=0.2)
rec.plot(label="Predicción recursiva (1 paso)", linestyle="--")
plt.axvline(x=log_varve_test.index[0], color='r', linestyle=':', label='Inicio test')
plt.legend()
plt.title("ARIMA(1,1,1) — proyección de los últimos 34 datos");
```
y `3d35a959` por:
```python
test = log_varve_test.squeeze()
print(f"RMSE proyección multi-paso : {np.sqrt(np.mean((proy - test)**2)):.4f}")
print(f"RMSE predicción recursiva  : {np.sqrt(np.mean((rec - test)**2)):.4f}")
print(f"Desvío del test (referencia sin modelo): {test.std(ddof=0):.4f}")
```

**Plantilla de conclusión (reemplazar `a2c96361`):**
> **Conclusión:** La proyección multi-paso del ARIMA(1,1,1) se aplana rápidamente al nivel del último dato de entrenamiento (con d=1 no hay media a la cual revertir) con IC que se ensanchan progresivamente, y logra RMSE = [X.XXX] sobre los 34 datos de test; la predicción recursiva a un paso, que incorpora cada observación real, sigue mejor las fluctuaciones y baja el RMSE a [X.XXX]. Ambos errores se comparan contra el desvío del test ([X.XXX]) como referencia. [Ajustar el texto si los números relativos cuentan otra historia — p. ej. si la multi-paso empata a la recursiva, decirlo.]

---

## 5. EJERCICIO 4 — AirPassengers (SARIMA + comparación con senos y cosenos)

Nada de este ejercicio fue ejecutado. Además de ejecutarlo, hay que **agregar la comparación con senos/cosenos** (mitad del enunciado, hoy ausente) y reescribir la conclusión pre-escrita.

### Paso 4.1 — Arreglar el índice (celda `60404ead`)
El índice queda como strings ("1949-01") → la predicción fuera de muestra y el plot se rompen (statsmodels necesita índice con frecuencia). Reemplazar el inicio de la celda por:

```python
df  = pd.read_csv('data/international-airline-passengers.csv', names=['year','passengers'], header=0)
air = pd.Series(df["passengers"].values,
                index=pd.period_range('1949-01', periods=len(df), freq='M'))
```
(el resto de la celda — los plots — queda igual).

### Paso 4.2 — Ejecutar las celdas del SARIMA y verificar
- [ ] `fit_bj` (SARIMA(0,1,1)(0,1,1)12) y `fit_alt` (SARIMA(1,1,0)(1,1,0)12) ajustan sin error.
- [ ] Anotar AIC/BIC de ambos (celda `0e44c1d3`) → la conclusión debe citar cuál gana y por cuánto.
- [ ] En el summary de `fit_bj`: ma.L1 y ma.S.L12 significativos.
- [ ] La predicción (celda `c9344afe`) se grafica alineada a continuación de la serie (si no, el índice del paso 4.1 quedó mal).

### Paso 4.3 — Agregar Ljung-Box numérico (insertar tras la celda `62f8a37e` de plot_diagnostics)
```python
print("Ljung-Box — SARIMA(0,1,1)(0,1,1)12:")
print(acorr_ljungbox(fit_bj.resid[13:], lags=[12, 24]))
# Nota: se descartan los primeros 13 residuos (arranque de la doble diferenciación d=1, D=1)
```

### Paso 4.4 — Agregar la comparación con senos y cosenos (NUEVAS celdas antes de la conclusión `6590b388`)
Referencia de código del curso: `3- Modelos ARMA y ARIMA/Modelos ARMA generalizados y resumen.ipynb` (sección SARIMA, que usa esta misma serie) y `2- Analisis exploratorio/Analisis espectral.ipynb`. Insertar:

```python
# Ajuste clásico del curso: tendencia + armónicos estacionales sobre log(air)
t = np.arange(len(log_air))
dfh = pd.DataFrame({'y': log_air.values, 't': t}, index=log_air.index)
for k in [1, 2, 3]:
    dfh[f'sin{k}'] = np.sin(2*np.pi*k*t/12)
    dfh[f'cos{k}'] = np.cos(2*np.pi*k*t/12)

fit_harm = ols('y ~ t + sin1 + cos1 + sin2 + cos2 + sin3 + cos3', data=dfh).fit()
print(f"Regresión armónicos — R2: {fit_harm.rsquared:.4f}  AIC: {fit_harm.aic:.2f}")

fig, axs = plt.subplots(1, 2, figsize=(15, 4))
pd.Series(fit_harm.resid.values, index=log_air.index).plot(ax=axs[0], title="Residuos regresión sin/cos")
plot_acf(fit_harm.resid, lags=36, bartlett_confint=False, ax=axs[1], title="ACF residuos sin/cos");
```
```python
print("Ljung-Box — residuos de la regresión sin/cos:")
print(acorr_ljungbox(fit_harm.resid, lags=[12, 24]))
```
**Qué esperar** (verificar contra el output real): la regresión con armónicos ajusta bien el nivel (R² alto) pero sus residuos quedan **fuertemente autocorrelacionados** (LB rechaza, ACF con onda), porque la estacionalidad determinística fija no se adapta a la amplitud creciente ni modela la correlación serial; el SARIMA sí deja residuos limpios. Esa es la comparación que pide el enunciado. (El AIC de `fit_harm` y de `fit_bj` son comparables solo con cautela — mismo endog log(air), pero uno condiciona a la diferenciación; apoyar la comparación en los residuos y en los gráficos, no solo en AIC.)

### Paso 4.5 — Reescribir la conclusión (celda `6590b388`) — plantilla:
> **Conclusión:** Entre los dos SARIMA probados, el (0,1,1)(0,1,1)₁₂ de Box-Jenkins obtiene AIC = [X] / BIC = [X] frente a AIC = [X] / BIC = [X] del (1,1,0)(1,1,0)₁₂, por lo que se selecciona el primero; sus coeficientes son significativos y el test de Ljung-Box sobre sus residuos no rechaza ruido blanco (p = [X] en lag 12, [X] en lag 24). En la comparación con el ajuste clásico de tendencia + senos y cosenos sobre log(air): la regresión armónica alcanza R² = [X] pero deja residuos con autocorrelación fuerte (Ljung-Box p = [X], ACF con estructura), mientras que el SARIMA modela esa correlación y produce residuos limpios; además su estacionalidad es adaptativa (se actualiza con los datos) en lugar de fija. La predicción a 24 meses reproduce nivel, tendencia y patrón estacional en la escala original.

(Todos los [X] salen de los outputs de los pasos 4.2–4.4. Si algo no coincide con lo esperado — p. ej. LB del SARIMA rechaza — reportarlo tal cual y matizar la conclusión.)

---

## 6. EJERCICIO 5 — log(jj) con UnobservedComponents

El código de los 3 modelos ya está escrito y es correcto en su especificación (M1: tendencia determinística; M2: tendencia estocástica; M3: M1 + AR(1)). Falta EJECUTAR y escribir conclusiones reales.

### Paso 5.1 — Ejecutar las celdas del ejercicio
- Si aparece `ConvergenceWarning` en algún `fit`: reintentar con `fit(disp=False, maxiter=500)`. Si persiste, dejarlo anotado en la conclusión (honestidad > cosmética).
- [ ] Verificar que la tabla comparativa (celda `54820f63`) imprime AIC/BIC/RMSE de los 3 modelos.
- [ ] En `plot_diagnostics` de cada modelo: mirar si el correlograma queda en bandas y el QQ razonable.
- Opcional prolijo: cambiar `ljj = np.log(astsa.jj)` por `ljj = np.log(astsa.jj.squeeze())`.

### Paso 5.2 — Agregar Ljung-Box numérico de los 3 (insertar antes de la conclusión `058cb274`)
```python
for nombre, f in [("Modelo 1", fit1), ("Modelo 2", fit2), ("Modelo 3", fit3)]:
    lb = acorr_ljungbox(f.resid, lags=[8])
    print(f"{nombre}: Ljung-Box p(8) = {lb.lb_pvalue.iloc[0]:.3f}")
```
(trimestral → horizonte 8 = 2 años.)

### Paso 5.3 — Reescribir la conclusión (celda `058cb274`) respondiendo LO QUE PREGUNTA el enunciado
El enunciado pregunta explícitamente: parte 2, "¿la tendencia estocástica mejora el modelo?"; parte 3, "¿el AR(1) mejora el modelo 1?". La conclusión actual responde con hipótesis — reemplazar por respuestas con números. Plantilla:

> **Conclusión Ejercicio 5:**
> - Modelo 1 (tendencia determinística): AIC = [X], BIC = [X], RMSE = [X], Ljung-Box p(8) = [X].
> - Modelo 2 (tendencia estocástica): AIC = [X], BIC = [X], RMSE = [X], Ljung-Box p(8) = [X]. → **¿Mejora? [SÍ/NO]**: el AIC [baja/sube] [X] puntos [interpretar con la tabla de la regla 1.2: Δ<2 equivalentes → parsimonia favorece la tendencia determinística; Δ>10 a favor de uno, concluyente].
> - Modelo 3 (M1 + AR(1)): AIC = [X], BIC = [X], RMSE = [X], Ljung-Box p(8) = [X]. → **¿Mejora sobre M1? [SÍ/NO]**, [misma lógica; además citar si el coeficiente AR y su sigma2 son significativos en el summary].
> - Elegimos el **Modelo [N]** por [menor AIC/BIC con residuos limpios / empate resuelto por parsimonia]. Los diagnósticos del elegido muestran [residuos dentro de bandas / detalle del QQ], [+ toda salvedad real].

**Regla especial**: si M1 y M2 empatan (Δ<2), la respuesta correcta a "¿mejora?" es "**no** — agrega un parámetro sin ganancia; se prefiere la tendencia determinística por parsimonia". No inventar mejoras.

---

## 7. PASADA FINAL (obligatoria)

1. **Ejecución completa limpia** del notebook con el comando de 2.1 (esto re-ejecuta TODO, incluido el Ej. 1 — sus outputs deben reproducir los números ya citados en sus conclusiones: AR(1) AIC 179.3/BIC 188.6, AR(2) 166.4/178.8, LB p=0.007, lineal+AR(2) AIC 150.6, RMSE 0.4297→0.3757).
2. Correr `extract_outputs.py` y confirmar: **cero `ERROR`** en todas las celdas.
3. **Checklist cruzada texto ↔ números** — para CADA celda de conclusión/interpretación del notebook, verificar que cada número citado aparece textualmente en algún output y que el sentido (mejora/empeora, rechaza/no rechaza, significativo/no) coincide. Si difiere: corregir el TEXTO.
4. Verificar que no quedó vocabulario prohibido (regla 1.1): buscar en el notebook las palabras "perfectamente", "suele", "si el AIC", "claramente". Deben ser 0 apariciones en celdas de conclusión.
5. Verificar que las fechas de ejecución de los summaries son todas del mismo día (ejecución limpia, no mezcla de corridas viejas).
6. Guardar y commitear en el repo de GitHub Classroom antes del **13/7/2026**.

---

## 8. Referencias rápidas
- Notebooks del curso: `C:\Users\joaco\Documents\ort\semestre_3\curso_series_temporales\`
- SARIMA del curso: `3- Modelos ARMA y ARIMA\Modelos ARMA generalizados y resumen.ipynb`
- UC / DLM del curso: `4- Modelos de Espacio de Estados\Modelo lineal dinamico.ipynb`
- Recetas y plantillas de redacción: `curso_series_temporales\preparacion_parcial\guia_rapida.md` y `toolkit_parcial.ipynb`
- Patrones ya resueltos análogos: `preparacion_parcial\parciales_resueltos\` (2023-Ej2 para índices/PeriodIndex; 2024-Ej1 para regresión+ARMA; 2022-Ej2 para elección AR y forecast)
