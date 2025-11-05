@echo off
setlocal enabledelayedexpansion
set namespace=ecommerce

echo Listando pods en el namespace %namespace%...
for /f "skip=1 tokens=1" %%P in ('kubectl get pods -n %namespace%') do (
    if not "%%P"=="" (
        echo -----------------------------
        echo Logs de %%P:
        kubectl logs -n %namespace% %%P | findstr "200"
    )
)
endlocal
