# Plan de ejecución — Obligatorio Series Temporales 2026

**Serie:** consumo eléctrico diario PJME (2002–2017, 5844 obs.)
**Entrega:** PDF por Gestión el 6/7/2026 (se puede seguir afinando hasta 13/7).
**Archivo de solución:** `obligatorio2026_solucion.ipynb` (copia nueva; la letra `obligatorio2026.ipynb` queda intacta como referencia).
**Modo de trabajo:** se genera el notebook completo de una y luego se revisa.
**Alcance:** mínimo bien justificado; exploración extra solo donde aporte mucho valor.

> ⚠️ Completar nombres de **integrantes** en la celda de portada antes de exportar el PDF.

---

## Convenciones comunes

- **Split temporal:** `train` = hasta 2015-12-31 · `test` = 2016-01-01 a 2017-12-31. Sin barajar (es serie temporal).
- **Métrica:** `RMSE = sqrt(mean((y - ŷ)²))`. Se reporta **RMSE train (ajuste)** y **RMSE test (predicción)** en cada parte para comparar de forma homogénea.
- **Tabla comparativa final:** una tabla que junte el RMSE test de las Partes I, III, IV y V para la discusión de cierre.
- **Reproducibilidad:** semilla fija donde aplique; figuras con título y ejes claros (van al PDF).

---

## Parte I — Análisis exploratorio + modelo lineal

**Qué pide:** detectar tendencia, correlaciones, estacionalidad (2 picos/año: invierno y verano), y efecto de día de semana; proponer un modelo lineal; analizar residuos; RMSE train y test.

**Pasos:**
1. EDA visual: serie completa, zoom a 1 año, media móvil para tendencia.
2. Estacionalidad anual: los **2 picos/año** se capturan con términos de Fourier de período 365.25 → armónicos `k=1,2` (el armónico 2 genera los dos picos invierno/verano).
3. Estacionalidad semanal: agrupar por día de la semana + `boxplot` → justifica **dummy de fin de semana** (o dummies por día).
4. Modelo lineal (OLS sobre train):
   `consumo ~ tendencia_lineal + Σ(sen/cos anuales) + dummy_finde`
5. Diagnóstico de residuos sobre train: gráfico temporal, histograma/QQ, y **ACF** (se anticipa que NO quedan blancos → motiva Parte II).
6. Reportar RMSE train y RMSE test.

**Entregable:** modelo lineal justificado + figuras + RMSE train/test + comentario de que los residuos tienen autocorrelación remanente.

---

## Parte II — ARMA sobre los residuos

**Qué pide:** analizar la estructura de correlación de los residuos de la Parte I, proponer un `ARMA(p,q)` justificado y diagnosticar.

**Pasos:**
1. Tomar los residuos de train de la Parte I.
2. **ACF y PACF** → leer p y q candidatos (se espera decaimiento tipo AR; probable AR(p) con p bajo, p.ej. p=1–2).
3. Ajustar `ARIMA(p,d=0,q)` con `statsmodels` y `trend='n'` (residuos centrados).
4. Diagnóstico: ACF de los residuos del ARMA, **Ljung-Box**, QQ-plot.
5. Si hay duda entre dos órdenes, comparar por **AIC/BIC** (única exploración prevista aquí).

**Entregable:** orden ARMA elegido con justificación (ACF/PACF + AIC) y diagnóstico de blancura.

---

## Parte III — ARMA con variables exógenas (SARIMAX)

**Qué pide:** combinar I y II en un único `SARIMAX` con las **mismas exógenas** de la Parte I; ver si mejora; diagnóstico; predicción en test.

**Pasos:**
1. `SARIMAX(endog=consumo, exog=regresores_ParteI, order=(p,0,q))` sobre train.
2. Comparar RMSE de ajuste vs. Parte I (debería mejorar al modelar la autocorrelación).
3. Diagnóstico de residuos finales (ACF, Ljung-Box).
4. **Predicción en test** con las exógenas del período test (los regresores son determinísticos → calculables para cualquier fecha). Reportar RMSE test.

**Entregable:** un modelo unificado, comparación contra Parte I, y RMSE test.

---

## Parte IV — Modelo en espacio de estados (`UnobservedComponents`)

**Qué pide:** enfoque estructural sobre la serie **centrada** (restar media), en tres modelos incrementales y comparar contra Parte III.

**Pasos:**
1. **Modelo A — local level + estacional semanal:**
   `UnobservedComponents(level='local level', seasonal=7, stochastic_seasonal=True)`.
   Observar que el nivel intenta seguir la variación anual (insuficiente).
2. **Modelo B — nivel determinístico + estacional semanal + frecuencia anual determinística:**
   `level=True, stochastic_level=False`, `seasonal=7`,
   `freq_seasonal=[{'period':365.25,'harmonics':k}]`, `stochastic_freq_seasonal=[False]`.
   Verificar que la performance queda **comparable a la regresión de Parte I** y que el residuo **aún no es blanco**.
3. **Modelo C — agregar componente autorregresiva:** `irregular=False, autoregressive=k`
   con `k` similar al orden de la Parte II.
4. **Comparar Modelo C vs. Parte III en test** y discutir (esperado: resultados parecidos; ambos modelan tendencia/estacionalidad + AR).

**Entregable:** tres ajustes incrementales + comparación final contra Parte III en test.

**Nota técnica:** trabajar con la serie centrada; el ajuste de UC con datos diarios y armónicos anuales puede ser algo lento → mantener `harmonics` chico (k=2–4).

---

## Parte V — Correlación con temperatura

**Qué pide:** estudiar la relación consumo–temperatura e incorporarla.

**Pasos:**
1. Graficar `pjme` y `temp` juntas (ejes/normalización para verlas en conjunto).
2. **Correlación a lag 0** entre `P_t` y `T_t` → se espera **baja** (relación no lineal).
3. **Scatter** `pjme` vs `temp` → forma de **U** (frío y calor suben el consumo): dependencia no lineal.
4. Construir **desvío térmico** `δ_t = |T_t − T̄|` (T̄ = temperatura de referencia/confort).
5. Modelo lineal: `x_t = β0 + β1·δ_t + β2·d_t + w_t` (d_t = dummy finde). Comparar RMSE con los anteriores.
6. **Mejora valiosa (exploración acotada):** separar frío/calor de forma asimétrica (HDD/CDD, es decir `max(0, T̄−T)` y `max(0, T−T̄)`) y/o incorporar `δ_t` como exógena al SARIMAX de la Parte III para medir la mejora real en test.

**Entregable:** evidencia de no linealidad, modelo con desvío térmico, y al menos una mejora justificada.

---

## Cierre

- **Tabla comparativa** de RMSE test (Partes I, III, IV, V) + breve discusión de cuál predice mejor y por qué.
- Conclusiones cortas (3–5 líneas).
- Revisar que cada figura tenga título y que el notebook corra de punta a punta con el kernel `C:\venv_ob`.
- Exportar a **PDF** para la entrega.

---

## Checklist de consignas (control final)

- [ ] I: tendencia, autocorrelación, estacionalidad anual (2 picos), efecto día de semana (boxplot)
- [ ] I: modelo lineal + análisis de residuos + RMSE train y test
- [ ] II: ACF/PACF de residuos + ARMA(p,q) justificado + diagnóstico
- [ ] III: SARIMAX con exógenas de I + comparación + diagnóstico + predicción test
- [ ] IV: UC local level+seasonal / +freq determinística / +AR + comparación con III
- [ ] V: corr lag 0, scatter no lineal, desvío térmico, modelo lineal, mejora
- [ ] Portada con integrantes completada
- [ ] Notebook corre completo + exportado a PDF
