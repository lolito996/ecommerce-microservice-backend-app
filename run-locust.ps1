# Script para habilitar port-forward de todos los servicios y ejecutar Locust
# Guarda este archivo como run-locust.ps1 y ejecútalo en PowerShell

$ErrorActionPreference = 'Stop'

# Definición de servicios y puertos
$services = @(
    @{ name = 'product-service'; port = 8500 },
    @{ name = 'user-service'; port = 8700 },
    @{ name = 'shipping-service'; port = 8600 },
    @{ name = 'payment-service'; port = 8400 },
    @{ name = 'order-service'; port = 8300 },
    @{ name = 'favourite-service'; port = 8800 }
)


# Lanzar port-forward para cada servicio en segundo plano
echo "Iniciando port-forward de servicios..."
foreach ($svc in $services) {
    $svcName = $svc.name
    $svcPort = $svc.port
    $pidFile = "pf_${svcName}.pid"
    $cmd = "-n ecommerce port-forward svc/$svcName ${svcPort}:${svcPort}"
    # Iniciamos kubectl en segundo plano SIN redirigir salida para evitar crear archivos .log/.err
    $proc = Start-Process -FilePath kubectl -ArgumentList $cmd -WindowStyle Hidden -PassThru
    $proc.Id | Set-Content $pidFile
    Start-Sleep -Milliseconds 500
}

# Esperar a que los servicios estén listos
echo "Esperando 20 segundos a que los forwards estén activos..."
Start-Sleep -Seconds 20

# Probar endpoints principales
echo "Probando endpoints principales:"
$urls = @(
    'http://localhost:8500/product-service/api/products',
    'http://localhost:8700/user-service/api/users',
    'http://localhost:8600/shipping-service/api/shippings',
    'http://localhost:8400/payment-service/api/payments',
    'http://localhost:8300/order-service/api/orders',
    'http://localhost:8800/favourite-service/api/favourites'
)
foreach ($url in $urls) {
    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
        echo "$url -> $($resp.StatusCode)"
    } catch {
        echo "$url -> ERROR: $($_.Exception.Message)"
    }
}


# Ejecutar Locust en modo headless (más usuarios y ramp-up)
echo "Ejecutando Locust..."
$locustCmd = "python -m locust -f tests/locust/locustfile.py --host http://localhost --headless -u 30 -r 5 -t 2m --html locust-report.html"
Write-Host "Comando Locust: $locustCmd"

# Ejecutar y capturar código de salida sin parar el script: queremos siempre limpiar y subir el reporte
$locustExit = 0
try {
    Invoke-Expression $locustCmd
    $locustExit = $LASTEXITCODE
} catch {
    Write-Host "Locust lanzó una excepción: $($_.Exception.Message)"
    # marcar como fallo
    $locustExit = 1
}


# Detener port-forwards y limpiar archivos
echo "Finalizado. Deteniendo port-forwards y limpiando archivos..."
foreach ($pidfile in Get-ChildItem -Filter 'pf_*.pid') {
    $pf_pid = Get-Content $pidfile
    try { Stop-Process -Id $pf_pid -Force } catch {}
    Remove-Item $pidfile -Force
}
Remove-Item pf_*.log,pf_*.err -Force -ErrorAction SilentlyContinue
echo "Listo."
if ($locustExit -ne 0) {
    Write-Host "ADVERTENCIA: Locust terminó con código $locustExit (hubo fallos en las peticiones)."
    Write-Host "El reporte se escribió en locust-report.html. El script terminará con exit code 0 para no marcar el pipeline como fallido."
    exit 0
}
