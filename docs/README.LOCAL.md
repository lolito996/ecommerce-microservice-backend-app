// ...existing code...
Documentación local y pipelines
=================================

Resumen rápido
--------------
Este documento centraliza cómo ejecutar y verificar el proyecto en local, los workflows (GitHub Actions), las pruebas E2E y de rendimiento (Locust), y las acciones necesarias para usar un runner self-hosted.

Requisitos mínimos
------------------
- Windows con PowerShell 7 (pwsh) o Linux/macOS
- Docker Desktop o Docker Engine
- Minikube (si despliegas en kubernetes local)
- kubectl configurado para el cluster local
- Java 11, Maven (o usar ./mvnw)
- Python 3.8+ y Locust (para pruebas de performance)
- Git y acceso al repo

Verificar:
```powershell
docker --version
minikube version
kubectl version --client
pwsh --version
mvn -v
python -V
```

Estructura relevante
--------------------
- kubernetes/ — manifests por servicio
- tests/locust/locustfile.py — scripts Locust (performance)
- .github/workflows/ — workflows GitHub Actions
- run-locust.ps1 — script PowerShell para port-forward + Locust
- load-images-minikube.bat — carga imágenes a Minikube (ahora solo 6 servicios por defecto)

Ejecutar en local (Kubernetes + Minikube)
----------------------------------------
1. Iniciar minikube:
```powershell
minikube start
minikube status
```

2. Cargar imágenes (solo 6 servicios por defecto):
```powershell
.\load-images-minikube.bat
minikube image ls
```

3. Namespace:
```powershell
kubectl create namespace ecommerce --dry-run=client -o yaml | kubectl apply -f -
```

4. Aplicar manifests:
```powershell
kubectl apply -f kubernetes
kubectl get pods -n ecommerce -o wide
```

E2E local (Maven)
-----------------
```powershell
mvn -f e2e-tests test
```
Usa variable TEST_BASE_URL para cambiar host (por ejemplo: TEST_BASE_URL=http://localhost:8080 mvn -f e2e-tests test).

Locust (performance) — ejecutar localmente
-----------------------------------------
Desde la raíz del repo:

1) Instalar dependencias:
```powershell
python -m pip install -r tests/locust/requirements.txt
```

2) Ejecutar script que habilita port-forward y lanza Locust:
```powershell
.\run-locust.ps1 [-Users 30] [-SpawnRate 5] [-Duration "2m"] [-KeepLogs]
```
- Opciones:
  - -Users: usuarios concurrentes (defecto 30)
  - -SpawnRate: usuarios/s de ramp-up (defecto 5)
  - -Duration: duración (ej. "2m", defecto "2m")
  - -KeepLogs: guarda logs de port-forward en ./logs (opcional)

3) Resultado: locust-report.html y archivos CSV en la raíz.

Qué hace run-locust.ps1
-----------------------
- Inicia port-forward para los servicios en namespace ecommerce en background.
- Valida endpoints y espera readiness.
- Ejecuta Locust en modo headless con parámetros configurables.
- Limpia procesos kubectl y archivos pf_*.pid al terminar.
- No deja .err/.log innecesarios por defecto; si usas -KeepLogs guarda en ./logs.

Limpieza manual de artefactos residuales
----------------------------------------
Si quedan archivos pf_*.log, pf_*.err o pf_*.pid y no se pueden borrar:
```powershell
# detener kubectl si está colgado
Stop-Process -Name kubectl -Force -ErrorAction SilentlyContinue

# borrar archivos residuales
Remove-Item .\pf_*.log -Force -ErrorAction SilentlyContinue
Remove-Item .\pf_*.err -Force -ErrorAction SilentlyContinue
Remove-Item .\pf_*.pid -Force -ErrorAction SilentlyContinue
```

Ignorar archivos en git
-----------------------
Si añadiste .log/.err/pf_*.pid y ya estaban trackeados:

```powershell
git add .gitignore
git commit -m "gitignore: ignore runtime .log/.err and pf_*.pid"

# quitar del index (sin borrar localmente)
git rm --cached -r -- '*.log' '*.err' 'pf_*.pid' || true
git commit -m "Untrack runtime log/err and pf_*.pid files" || echo 'No changes to commit'
```

Pipeline: ejecución simplificada de Locust
-----------------------------------------
- El workflow e2e-locust.yml ahora puede estar configurado para ejecutar solo `run-locust.ps1` en el runner self-hosted.
- Asegúrate de que el runner tenga Docker, kubectl, Minikube y Python/Locust instalados y accesibles.

Diagnóstico y troubleshooting rápido
------------------------------------
- Si Locust muestra ReadTimeout bajo carga pero curl local responde rápido => posible saturación del servicio.
  - Ejecutar: kubectl top pods -n ecommerce
  - Ver logs en tiempo real:
    ```powershell
    kubectl logs <pod> -n ecommerce --tail=200 -f
    ```
- Verificar puertos ocupados localmente:
```powershell
netstat -ano | findstr :8500
```

Sugerencias de mejora
---------------------
- Añadir tests unitarios y de integración por servicio (ver sección "Qué falta implementar" original).
- Añadir opción en run-locust.ps1 para guardar logs en carpeta específica solo si se pasa flag.
- Usar `minikube image load` (implementado en load-images-minikube.bat) para mayor fiabilidad al cargar imágenes.

Estado actual del repo
----------------------
- load-images-minikube.bat: ahora carga 6 servicios por defecto (API Gateway, Service Discovery, Cloud Config, User Service, Proxy Client, Zipkin).
- run-locust.ps1: maneja limpieza y evita generar .err/.log por defecto; acepta opciones para usuarios/rate/duración.

