<#
  run-local-e2e.ps1
  Automatiza el flujo local para ejecutar las pruebas E2E:
   - Inicia minikube si no está
   - Carga imágenes con load-images-minikube.bat
   - Crea namespace `ecommerce` y aplica manifests
   - Espera rollouts
   - Determina TEST_BASE_URL (minikube service o port-forward)
   - Ejecuta `mvnw -f e2e-tests test` y guarda los reportes
#>

param(
    [switch]$NoImageLoad
)

function Exit-WithMessage($code, $msg) {
    Write-Host $msg
    exit $code
}

Write-Host "== Ejecutando run-local-e2e.ps1 =="

Write-Host "Comprobando Minikube..."
$minikubeStatus = & minikube status --format '{{.Host}}' 2>$null
if ($LASTEXITCODE -ne 0 -or $minikubeStatus -ne 'Running') {
    Write-Host "Minikube no está corriendo. Intentando iniciar..."
    minikube start
    if ($LASTEXITCODE -ne 0) { Exit-WithMessage 2 "No se pudo iniciar Minikube" }
} else {
    Write-Host "Minikube running"
}

if (-not $NoImageLoad) {
    if (Test-Path .\load-images-minikube.bat) {
        Write-Host "Cargando imágenes en minikube con load-images-minikube.bat"
        & .\load-images-minikube.bat
        if ($LASTEXITCODE -ne 0) { Write-Host "Advertencia: el script de carga devolvió código $LASTEXITCODE" }
    } else {
        Write-Host "load-images-minikube.bat no encontrado, omitiendo carga de imágenes. Asegúrate de que las imágenes estén en Minikube." 
    }
}

Write-Host "Asegurando namespace 'ecommerce' y aplicando manifiestos..."
kubectl create namespace ecommerce --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f kubernetes

Write-Host "Esperando rollouts (esto puede tardar algunos minutos)..."
$deps = kubectl get deployments -n ecommerce -o jsonpath="{.items[*].metadata.name}"
foreach ($d in $deps.Split(' ')) {
    if ($d) {
    Write-Host "Esperando rollout: $d"
    # Aumentamos el timeout de rollout a 8 minutos para dar tiempo a los servicios Spring Boot a arrancar
    kubectl rollout status deployment/$d -n ecommerce --timeout=8m
        if ($LASTEXITCODE -ne 0) { Write-Host "Warning: rollout status para $d devolvió código $LASTEXITCODE" }
    }
}

Write-Host "Determinando URL del API Gateway..."

# 1) Intentar obtener la URL con 'minikube service' pero con timeout para evitar bloqueos en Windows
$svcUrl = $null
$job = Start-Job -ScriptBlock { minikube service api-gateway --url -n ecommerce 2>$null }
if (Wait-Job -Job $job -Timeout 6) {
    $svcRaw = Receive-Job -Job $job | Out-String
    if ($svcRaw) {
        $urls = $svcRaw -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        if ($urls.Count -gt 0) {
            $svcUrl = $urls[0]
            Write-Host "Found service URL via minikube service: $svcUrl"
        }
    }
} else {
    Write-Host "minikube service timed out or blocked; abortando intento rápido.";
    Stop-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
}

# 2) Si no se obtuvo URL, intentar construirla usando minikube ip + nodePort (NodePort must be set in the Service)
if (-not $svcUrl) {
    try {
        $nodePort = kubectl get svc api-gateway -n ecommerce -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
    } catch {
        $nodePort = $null
    }

    if ($nodePort) {
        try {
            $minikubeIp = (& minikube ip) -replace "`r|`n", ''
        } catch {
            $minikubeIp = $null
        }

        if ($minikubeIp) {
            $candidate = "http://$minikubeIp`:$nodePort"
            Write-Host "Intentando conectar a NodePort: $candidate"
            try {
                $resp = Invoke-WebRequest -Uri "$candidate/actuator/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
                if ($resp.StatusCode -eq 200) {
                    $svcUrl = $candidate
                    Write-Host "Found service URL via NodePort: $svcUrl"
                }
            } catch {
                Write-Host ("NodePort no accesible desde host: {0}:{1}" -f $minikubeIp, $nodePort)
            }
        }
    }
}

# 3) Si aún no tenemos URL, arrancar port-forward en background y guardar PID para poder cerrarlo luego
if (-not $svcUrl) {
    Write-Host "No se pudo obtener URL pública. Verificando si el puerto 8080 está libre..."
    $netstat = netstat -ano | Select-String ":8080"
    if ($netstat) {
        $pid = ($netstat -split '\s+')[-1]
        if ($pid -match '^[0-9]+$') {
            Write-Host "El puerto 8080 está ocupado por el proceso PID $pid. Intentando detenerlo..."
            try {
                Stop-Process -Id $pid -Force
                Write-Host "Proceso $pid detenido."
            } catch {
                Write-Host "No se pudo detener el proceso $pid automáticamente. Hazlo manualmente si el port-forward falla."
            }
        }
    }
    Write-Host "Iniciando port-forward en background hacia localhost:8080"
    $proc = Start-Process -FilePath kubectl -ArgumentList "port-forward -n ecommerce service/api-gateway 8080:8080" -WindowStyle Hidden -PassThru

    # Esperar hasta 180s por el reenvío y la respuesta /actuator/health (servicios Spring Boot pueden tardar)
    $maxWait = 180
    $waited = 0
    $healthy = $false
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 2
        $waited += 2
        if (-not $proc -or $proc.HasExited) { break }
        try {
            $resp = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
            if ($resp.StatusCode -eq 200) {
                $healthy = $true
                break
            }
        } catch {
            # no hacer nada, seguimos esperando
        }
        Write-Host "Esperando port-forward y health... $waited/$maxWait s"
    }

    if ($proc -and -not $proc.HasExited -and $healthy) {
        $svcUrl = 'http://localhost:8080'
        Write-Host "Usando fallback port-forward: $svcUrl (kubectl PID: $($proc.Id)). Guardando PID en .\portforward.pid"
        Set-Content -Path .\portforward.pid -Value $proc.Id
    } elseif ($proc -and -not $proc.HasExited -and -not $healthy) {
        Write-Host "Port-forward iniciado (PID: $($proc.Id)) pero el endpoint /actuator/health no respondió en $maxWait s. Comprueba manualmente."
        $svcUrl = 'http://localhost:8080'
        Set-Content -Path .\portforward.pid -Value $proc.Id
    } else {
        Write-Host "No fue posible iniciar port-forward (proc exit). Revisa manualmente. Si el puerto sigue ocupado, mata el proceso manualmente con: Stop-Process -Id <PID>"
    }
}

Write-Host "Exportando TEST_BASE_URL para esta sesión y ejecutando pruebas E2E..."
$env:TEST_BASE_URL = $svcUrl

Write-Host "TEST_BASE_URL = $env:TEST_BASE_URL"

Write-Host "Ejecutando Maven tests en e2e-tests... (esto mostrará salida en consola)"
& .\mvnw -f e2e-tests test
$mvnCode = $LASTEXITCODE

if ($mvnCode -eq 0) {
    Write-Host "Pruebas E2E completadas correctamente. Los reportes están en e2e-tests\target\surefire-reports"
} else {
    Write-Host "Las pruebas fallaron con código $mvnCode. Revisa e2e-tests\target\surefire-reports para detalles."
}

Write-Host "run-local-e2e.ps1 finalizado."
exit $mvnCode
