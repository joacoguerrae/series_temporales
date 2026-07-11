# Auditoría de `obligatorio2026_solucion.ipynb`

**Fecha:** 4/7/2026 · **Criterio:** estricto — toda técnica ajena al material del curso se marca con reemplazo propuesto.
**Referencias del curso:** notebooks de `curso_series_temporales` (unidades 1–5) y parciales 2022/2023/2024.
**Alcance:** alineación con el curso, cumplimiento de la letra, correctitud estadística (sobre outputs guardados), presentación/entrega.
**Nota:** auditoría estática (no se ejecutó el notebook). Las celdas se numeran de 0 (portada) a 58 (conclusión general), en el orden del notebook.

---

## Resumen ejecutivo

La solución está **estructuralmente bien encaminada**: cubre las 5 partes, usa las clases y la metodología del curso (regresión con Fourier + dummies, ARMA por AIC, SARIMAX, `UnobservedComponents` incremental, desvío térmico), los números de los outputs son coherentes entre sí y la comparación final es correcta.

Los problemas principales son **de interpretación y justificación, no de código**:

1. El test de **Ljung-Box rechaza blancura** en los residuos de Partes II y III (p ≈ 10⁻¹⁷) y las conclusiones lo esquivan en lugar de interpretarlo (hallazgo A1 — el más importante).
2. El **Modelo C de Parte IV no convergió** (ConvergenceWarning visible en el output) y se ignora (A2).
3. Falta el **análisis de correlaciones de la serie cruda** que la letra pide explícitamente en Parte I (A3).
4. Varias elecciones no vistas en el curso (`np.polyfit`, `enforce_stationarity=False`, ausencia de `bartlett_confint=False`, ausencia de periodograma y de predicción recursiva con `append`) que un docente de este curso notaría de inmediato.

Nada de lo anterior invalida los resultados numéricos ya obtenidos; casi todo se corrige con texto interpretativo y sustituciones puntuales.

---

## Cumplimiento de la letra, parte por parte

| Consigna | Estado | Detalle |
|---|---|---|
| I — tendencia | ✅ | Media móvil 365d (celda 10) |
| I — correlaciones de corto/largo plazo | ❌ | No hay ACF/PACF de la serie `pjme` en la exploración (ver A3) |
| I — estacionalidad (2 picos/año) | ⚠️ | Promedio por día del año (celda 11) la muestra, pero sin periodograma que justifique las frecuencias (M2) |
| I — efecto día de semana (boxplot) | ✅ | Celda 12 |
| I — modelo lineal + análisis del ajuste | ⚠️ | Modelo correcto (celda 14); falta lectura escrita del `summary` (M5) |
| I — residuos + RMSE train/test | ⚠️ | Hecho (celdas 15–17); falta QQ-plot estilo curso (B1) |
| II — estructura de correlación de residuos | ✅ | ACF/PACF (celda 21) |
| II — ARMA(p,q) justificado | ⚠️ | Tabla AIC/BIC correcta (celda 22); falta la lectura ACF/PACF que el curso usa como justificación primaria (M3) |
| II — ajuste + diagnóstico | ❌ | Diagnóstico ejecutado pero mal interpretado: Ljung-Box rechaza y la conclusión no lo dice (A1) |
| III — SARIMAX con exógenas exactas de I | ✅ | Celda 27, `exog=X_train` idéntica a Parte I |
| III — ¿mejora respecto a I? | ✅ | Bien explicado el efecto un-paso vs largo plazo (celdas 28, 31) |
| III — diagnóstico de residuos finales | ❌ | Mismo problema que II: LB rechaza, sin comentario (A1) |
| III — predicción en test | ⚠️ | Hecha a horizonte largo (correcta para comparar); falta la recursiva con `append` que es el método canónico del curso (M4) |
| IV — serie centrada | ✅ | Celda 34, media de train |
| IV — Modelo A (local level + seasonal 7) | ✅ | Celda 36 + observación del nivel trackeando el ciclo anual |
| IV — Modelo B (nivel determinístico + freq anual) | ✅ | Celda 38; comparable a Parte I (2984 vs 2969) y residuo no blanco, como pide la letra |
| IV — Modelo C (+ AR) | ❌ | Especificación correcta pero **no convergió** y no se trata (A2) |
| IV — comparación C vs III en test | ✅ | Celdas 40–42 |
| V.1 — graficar ambas series juntas | ⚠️ | Solo zoom 2010 estandarizado (celda 48); falta el período completo (B4) |
| V.2 — correlación lag 0 | ✅ | 0.173, interpretada como baja (celda 49) |
| V.3 — scatter + no linealidad | ✅ | Relación en U bien interpretada (celdas 50–51) |
| V.4 — desvío térmico | ⚠️ | Construido con `np.polyfit`, técnica no vista en el curso (M1) |
| V.5 — modelo lineal δ + finde | ⚠️ | Correcto (celda 53); falta responder en texto "¿cómo se compara con los anteriores?" (M6) |
| V.6 — mejoras propuestas | ✅ | HDD/CDD + SARIMAX con temperatura; falta anclarlo al lenguaje del curso (M7) |
| Cierre — tabla comparativa + conclusiones | ✅ | Celdas 57–58 |
| Portada con integrantes | ❌ | Sigue "(completar)" (A4) |

---

## Hallazgos — severidad ALTA

### A1. Ljung-Box rechaza blancura en Partes II y III y las conclusiones lo esquivan
- **Celdas:** 23–24 (Parte II) y 29, 31 (Parte III).
- **Qué pasa:** `acorr_ljungbox` da p-valores ≈ 4·10⁻¹⁷ a lags 10/20/30 en ambos casos. La conclusión de Parte II dice que el test "indica si queda estructura remanente" sin decir **qué indicó**; la de Parte III ni lo menciona. Un lector del curso ve el output y la omisión de inmediato.
- **Qué dice el curso:** *Modelos ARMA generalizados* enseña la regla explícita: "si el p-valor es pequeño (ej: p<0.05) se rechaza la hipótesis" de blancura. El diagnóstico honesto es parte de la receta Box-Jenkins del resumen del curso.
- **Fix propuesto (sin tocar código):** reescribir ambas conclusiones: el ARMA reduce fuertemente la autocorrelación (la ACF de residuos lo muestra) pero **no la elimina: Ljung-Box rechaza blancura**, y la estructura remanente está en los múltiplos de lag 7 (la dummy de fin de semana no distingue lunes de miércoles, y queda estacionalidad semanal en el residuo).
- **Fix opcional (código, alineado al curso):** (a) usar **dummies por día de la semana** en la matriz de diseño de Parte I en lugar de una sola dummy de finde — el curso enseña regresión con factores (dummies trimestrales de la serie JJ en *Modelos lineales*), y la letra misma sugiere agrupar por día; o (b) agregar componente estacional `seasonal_order=(1,0,0,7)` como enseña la sección SARIMA del curso. Cualquiera de las dos probablemente limpie gran parte del rechazo.

### A2. El Modelo C (Parte IV) no convergió y el warning quedó impreso en el output
- **Celda:** 40 — `ConvergenceWarning: Maximum Likelihood optimization failed to converge`.
- **Qué pasa:** el RMSE de test de Parte IV (3402.4) sale de un modelo cuya optimización falló; la comparación IV vs III queda debilitada y el warning quedó visible en el PDF a entregar.
- **Qué dice el curso:** en *Modelo lineal dinámico* los `fit` de modelos de espacio de estados se llaman con `start_params=[...]` y/o `maxiter=100` justamente para ayudar a converger.
- **Fix propuesto:** reintentar `ucC.fit(maxiter=...)` (p. ej. 200–500) y/o `start_params` razonables (partiendo de los de B); verificar que desaparece el warning y actualizar el RMSE. Si aun así queda lento/difícil, decirlo en el texto (es un modelo con muchos estados) — lo que no puede pasar es ignorarlo.

### A3. Falta el análisis de correlaciones de la serie en la exploración de Parte I
- **Celdas:** 9–12 (bloque de exploración).
- **Qué pasa:** la letra pide explorar "si la serie presenta correlaciones de corto o largo plazo" y la solución nunca muestra la ACF/PACF de `pjme` cruda (solo la de los residuos, después del modelo).
- **Qué dice el curso:** es el primer paso estándar; el parcial 2024 (Ej. 1.1) pide textualmente "analizar también la autocorrelación de la serie".
- **Fix propuesto:** agregar en la exploración `plot_acf(y_train, lags=..., bartlett_confint=False)` (+ PACF opcional) y 2–3 líneas: correlación de corto plazo alta (persistencia térmica día a día), decaimiento lento + ondas a lag 7 y ~365 (estacionalidades) → motiva regresores determinísticos + estructura ARMA posterior.

### A4. Portada sin integrantes
- **Celda:** 0 — sigue "(completar)". Bloqueante para la entrega del 6/7. Completar antes de exportar el PDF.

---

## Hallazgos — severidad MEDIA (alineación con el curso)

### M1. `np.polyfit` para la temperatura de referencia (Parte V) — técnica no vista
- **Celda:** 52. El vértice de una parábola ajustada con `np.polyfit` (T_ref = −b/2a = 10.8 °C) no aparece en ningún notebook del curso.
- **Qué dice el curso/letra:** la letra sugiere δ_t = |T_t − T̄_t| donde T̄ se lee naturalmente como temperatura media; el ejemplo mortalidad–temperatura de *Regresión entre series* maneja la no linealidad con temperatura centrada `(T−T̄)` + término cuadrático `(T−T̄)²` vía `ols`.
- **Fix propuesto (elegir uno):**
  - (a) **Mínimo:** δ = |T − T̄| con T̄ = media de la temperatura en train (~12–13 °C), tal cual la letra; opcionalmente comentar que el scatter sugiere un mínimo de consumo cerca de 11 °C y probar esa "temperatura de confort" como variante justificada **visualmente** (leyendo el scatter, sin polyfit).
  - (b) **Estilo curso:** regresión `consumo ~ (T−T̄) + (T−T̄)² + finde` como el Modelo 3 de mortalidad del curso, y comparar con la versión |δ|.
  - En cualquier caso el RMSE cambiará poco (10.8 vs ~12.5 °C); lo que importa es poder defender el método.

### M2. Falta el periodograma para justificar las frecuencias
- **Celdas:** 11 y 13–14. Los armónicos k=1,2 se justifican solo con el promedio por día del año.
- **Qué dice el curso:** el periodograma es LA herramienta sistemática de *Análisis espectral* para detectar componentes periódicas; los parciales 2022 (Ej. 1.3) y 2024 (funciones útiles provistas) lo dan por sabido.
- **Fix propuesto:** agregar `periodogram(...)` / `spectrum(...)` (las funciones del curso, copiadas tal cual) sobre la serie de train centrada (o sobre los residuos de tendencia): deberían aparecer picos en f ≈ 1/365.25 y 2/365.25 (los dos picos anuales) y en 1/7 (semanal) → justifica K=2 y el regresor de día de semana con evidencia espectral.

### M3. Parte II: la justificación del orden ARMA es solo por AIC
- **Celdas:** 20–22. El markdown dice "la ACF/PACF sugiere un proceso autorregresivo" sin leer los gráficos.
- **Qué dice el curso:** la regla de identificación es el contenido central de la unidad 3: **AR(p) → PACF corta en p, ACF decae; MA(q) → ACF corta en q; ARMA mixto → ambas decaen y ahí sí se corta por AIC/BIC**.
- **Fix propuesto:** 3–4 líneas leyendo los gráficos de la celda 21: PACF con lags 1–3 significativos y corte posterior → AR(3) candidato natural; ACF decae lentamente (consistente con AR); los mixtos (1,1)/(2,1) se prueban porque ACF y PACF no cortan limpio, y el AIC confirma AR(3). La tabla ya está; falta el relato que el curso espera.

### M4. Falta la predicción recursiva con `append` como complemento en test
- **Celdas:** 28 (Parte III), 40 (Parte IV).
- **Qué pasa:** el test se evalúa solo con pronóstico a 731 pasos (`get_forecast`). Es una elección válida y comparable entre partes (y conviene mantenerla como métrica principal), pero el curso enseña insistentemente la **predicción recursiva a un paso** con `fit.append(test)` + `get_prediction` como "el uso más adecuado" de estos modelos, y el parcial 2024 la pide textualmente.
- **Fix propuesto:** agregar en Parte III un bloque corto: `sarimax_III.append(y_test, exog=X_test)` → RMSE recursivo, y 2–3 líneas comparando: a un paso el ARMA aporta mucho (RMSE ≈ nivel de train), a horizonte largo domina la parte determinística (por eso 3279 ≈ 3291 de Parte I). Esto además **explica** un resultado que hoy queda sin explicar del todo. `get_forecast` puede quedarse, o cambiarse por `get_prediction(start, end, exog=...)` que es el idioma del curso (son equivalentes).

### M5. Parte I: falta el análisis escrito del `summary` del OLS
- **Celda:** 14 (output) y 18 (conclusión). La letra pide "analice los resultados del ajuste".
- **Fix propuesto:** 4–5 líneas: todos los regresores significativos (p<0.001); `weekend` ≈ −3314 MW (cae el consumo el finde); cos2/sin2 dominan a cos1/sin1 → el segundo armónico genera los dos picos; tendencia levemente negativa (−45 MW/año); R² = 0.59; Durbin-Watson = 0.42 ya anticipa la autocorrelación de residuos que motiva la Parte II.

### M6. Parte V: sin respuesta textual a "¿cómo se compara este modelo con los anteriores?" ni discusión de la ventaja informacional de la temperatura
- **Celdas:** 53–55 y 58.
- **Qué pasa:** los números están (train 2202 / test 2506, y 2158 con SARIMAX+temp) pero: (a) no hay una frase de comparación junto al resultado; (b) nunca se dice que las Partes I–IV predicen con **funciones puramente determinísticas del tiempo**, mientras que la Parte V usa la **temperatura observada del período de test** (que en un pronóstico real no se conoce). Es la pregunta de defensa más previsible del trabajo.
- **Fix propuesto:** una frase tras la celda 53 (mejora ~24% el RMSE de test vs Parte III: la temperatura explica los picos reales, que el calendario solo aproxima "en promedio") y una aclaración en la conclusión general: la comparación es condicional a conocer T_t; en producción se usaría un pronóstico de temperatura.

### M7. HDD/CDD sin anclaje al lenguaje del curso
- **Celdas:** 54–55.
- **Qué pasa:** los términos HDD/CDD (heating/cooling degree days) son jerga del dominio energético, no del curso.
- **Qué dice el curso:** la respuesta asimétrica se modela en el curso con **variables indicatrices** (ejemplo SOI: `rec ~ soi + D + soi·D`, "equivale a ajustar dos rectas").
- **Fix propuesto:** conservar HDD/CDD (es la mejora valiosa) pero presentarlos como "desvío frío / desvío calor" y justificarlos así: equivalen a interactuar δ con la indicatriz de T<T̄, es decir, ajustar dos pendientes distintas a cada lado de la temperatura de referencia, como se vio en clase.

### M8. `enforce_stationarity=False, enforce_invertibility=False` en SARIMAX — no visto y no necesario
- **Celdas:** 27 y 55.
- **Qué pasa:** flags que no aparecen en el curso y que habría que saber explicar (deshabilitan la restricción de causalidad/invertibilidad que el curso sí enseña como requisito de un ARMA bien definido — sección Causalidad/Invertibilidad de la unidad 3). Los AR estimados (1.04, −0.41, 0.14) son estacionarios de todos modos.
- **Fix propuesto:** quitar ambos flags (el ajuste debería dar prácticamente igual); si algo fallara al reajustar, ese sería un dato importante a investigar, no a silenciar.

### M9. Tendencia no significativa en el SARIMAX — oportunidad de discusión que el curso valora
- **Celda:** 27: `trend` pasa de t=−4.37 (p≈0) en OLS a z=−1.72 (p=0.085) en SARIMAX.
- **Qué dice el curso:** la inferencia OLS supone residuos blancos (hipótesis del modelo lineal, *Modelos lineales*); al modelar la autocorrelación, los errores estándar se vuelven honestos. Los parciales piden repetidamente "eliminar las variables no significativas".
- **Fix propuesto:** 2 líneas señalando esto (la significancia de la tendencia era un espejismo de la autocorrelación) — es exactamente el tipo de observación que distingue un trabajo bueno de uno correcto. Opcional: reajustar sin tendencia y verificar que nada cambia materialmente.

---

## Hallazgos — severidad BAJA (estilo y presentación)

| # | Celda(s) | Detalle | Fix |
|---|---|---|---|
| B1 | 17 | El curso siempre chequea gaussianidad con `sm.qqplot(res, line="s")`; la solución usa histograma | Agregar QQ-plot (o reemplazar el histograma) en el diagnóstico de Parte I |
| B2 | 17, 21, 38 | `plot_acf` sin `bartlett_confint=False`; el curso lo indica dos veces como nota explícita ("para usar el intervalo de confianza correcto") | Agregar el argumento en todas las ACF de residuos |
| B3 | 8 | `warnings.filterwarnings('ignore')` global; el curso solo silencia el import de astsa con `catch_warnings` | Quitarlo (además enmascara problemas reales como el de A2) |
| B4 | 48 | V.1 pide graficar ambas series juntas; solo hay zoom 2010 | Agregar el período completo (las dos series estandarizadas, o dos paneles como el curso) |
| B5 | 23, 38 | `arma_II.resid.iloc[1:]` y `ucB.resid.iloc[10:]` — burn-in sin explicación | Una línea: se descartan los primeros residuos afectados por la inicialización del filtro (el curso hace lo análogo: "saco el primer residuo") |
| B6 | 58 | "**suele** dar el menor RMSE" — hedging innecesario: en este trabajo **dio** el menor (2158 MW) | Afirmación directa con el número |
| B7 | 49 | Correlación consumo–temperatura solo a lag 0 | Opcional: CCF con la función del curso (los 3 parciales piden correlación cruzada entre series) — enriquece sin costo |
| B8 | 9–12 | La EDA usa la serie completa (2002–2017) para decisiones de diseño | Aceptable (el curso también grafica todo antes de partir), pero preferible sobre train o mencionarlo |
| B9 | 27 | Clase `SARIMAX` directa; el curso usa `ARIMA` (que también acepta `exog`) y solo menciona SARIMAX de nombre | Defendible tal cual (está nombrada en el curso); opcional cambiarla por `ARIMA(y_train, exog=X_train, order=...)` para ser 100% literal |

---

## Lo que está bien y no hay que tocar

- **Estructura y split**: train hasta 2015 / test 2016–17, sin barajar; RMSE homogéneo con helper propio. ✔
- **Parte I, diseño del modelo**: tendencia + Fourier k=1,2 (la regresión con senos/cosenos y armónicos es ejercicio literal de *Modelos lineales* y del ejemplo AirPassengers) + dummy — todo curso puro. La matriz de diseño determinística evaluable en cualquier fecha es la forma correcta de predecir en test. ✔
- **Parte II, metodología AIC**: comparar candidatos con tabla AIC/BIC es exactamente lo que hace el curso con Recruitment y GNP. ✔
- **Parte III**: exógenas idénticas a Parte I (lo que la letra exige), y la explicación un-paso vs largo plazo de por qué el RMSE de train mejora tanto y el de test poco es correcta y fina. ✔
- **Parte IV**: los tres modelos incrementales replican la letra parámetro a parámetro y coinciden con el ejercicio JJ del curso (freq_seasonal determinística, luego `autoregressive=k`); serie centrada con media de train. ✔
- **Parte V**: scatter en U bien interpretado; SARIMAX+temperatura como mejora final es la extensión natural. ✔
- **plot_diagnostics**: está enseñado en el curso (*Modelo lineal dinámico* lo usa 7 veces), su uso en II/III es defendible. ✔
- Los outputs guardados son internamente consistentes (no se detectaron números contradictorios entre celdas ni con las conclusiones, salvo lo señalado en A1/A2).

---

## Estado — 4/7/2026

Los hallazgos fueron aplicados en **`obligatorio2026_solucion_v2.ipynb`** (nueva solución, ejecutada de punta a punta con el kernel `venv_ob`; la letra quedó intercalada verbatim y `obligatorio2026_solucion.ipynb` quedó intacta como respaldo). Aplicado: A1 (Ljung-Box interpretado honestamente), A2 (Modelo C converge, verificado con `mle_retvals`), A3 (ACF/PACF de la serie cruda), M1–M9 y todas las bajas. Durante la implementación apareció además un problema nuevo tipo A2 en el ARMA+temperatura de la Parte V (no convergía): se resolvió con inicialización en dos etapas (OLS→ARMA) y quedó verificado.

**Pendiente único: A4 — completar los integrantes en la portada antes de exportar el PDF.**

---

## Orden sugerido de corrección (para la fase de implementación)

1. **A4** (portada) y **A1** (reescribir 2 conclusiones) — texto puro, 15 min, máximo impacto.
2. **A2** — reajustar Modelo C con `maxiter`/`start_params` y actualizar números.
3. **A3 + M2** — bloque de ACF + periodograma en la exploración de Parte I (usar las funciones `periodogram`/`spectrum` del curso).
4. **M3, M5, M6, M9** — párrafos interpretativos (sin tocar resultados).
5. **M1** — rehacer δ sin polyfit; **M8** — quitar flags; **M7** — reencuadrar HDD/CDD.
6. **M4** — bloque de predicción recursiva en Parte III.
7. **Bajas** en el orden de la tabla, según tiempo disponible.
8. Correr el notebook completo con el kernel `C:\venv_ob` de punta a punta (esta auditoría fue estática), verificar que no queden warnings visibles, y exportar el PDF.
