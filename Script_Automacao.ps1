<#
.SYNOPSIS
    Script de Provisionamento de Laboratório (v13.0 - Stable & Resilient)
    Foco: Execução offline parcial (Mega), Tratamento de Variáveis de Ambiente Automático e Winget Resiliente.
#>

$ErrorActionPreference = "Continue"
# Garante suporte a caracteres especiais no console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ==============================================================
# 1. VALIDAÇÃO DE PRIVILÉGIOS (ADMINISTRADOR)
# ==============================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "ERRO CRÍTICO: Execute o PowerShell como Administrador para rodar o script."
    Start-Sleep -Seconds 5
    Exit
}

# ==============================================================
# 2. VARIÁVEIS GERAIS E CAMINHOS
# ==============================================================
$senhaPadraoMySQL  = "senai105"
$pastaInstaladores = "C:\Instaladores" 
$pastaJavaDestino  = "C:\Program Files\Java"

# Caminhos Locais Esperados (Arquivos baixados do Mega)
$caminhoCisco = Join-Path $pastaInstaladores "CiscoPacketTracer_900_win_64bit.exe"
$caminhoJdk   = Join-Path $pastaInstaladores "jdk-26_windows-x64_bin.exe"
$caminhoJre   = Join-Path $pastaInstaladores "jre-8u491-windows-x64.exe"
$caminhoVS    = Join-Path $pastaInstaladores "vs_setup.exe" # Mantido o nome genérico para o instalador do VS

# ==============================================================
# 3. FUNÇÕES AUXILIARES
# ==============================================================
function Write-Secao($texto) {
    Write-Host "`n  ----------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [+] $texto" -ForegroundColor Cyan
    Write-Host "  ----------------------------------------------" -ForegroundColor DarkGray
}

function Instalar-Winget($nome, $id) {
    Write-Host "  >> Instalando (Winget): $nome..." -ForegroundColor Yellow
    # Adicionado --disable-interactivity para blindar contra pop-ups ocultos
    $processo = Start-Process -FilePath "winget" -ArgumentList "install --exact --id $id --accept-package-agreements --accept-source-agreements --silent --force --disable-interactivity" -Wait -NoNewWindow -PassThru
    
    if ($processo.ExitCode -eq 0) {
        Write-Host "     OK: Instalado com sucesso." -ForegroundColor Green
    } elseif ($processo.ExitCode -in @(-1978335189, -1978335215)) {
        Write-Host "     INFO: Já instalado/atualizado." -ForegroundColor DarkYellow
    } else {
        Write-Host "     AVISO: Falha/Erro no Winget (Código: $($processo.ExitCode))." -ForegroundColor Red
    }
}

# ==============================================================
# 4. PRÉ-FLIGHT CHECK (Checagem de dependências físicas)
# ==============================================================
Clear-Host
Write-Host "`n  ==============================================" -ForegroundColor Green
Write-Host "   PROVISIONAMENTO - INFRAESTRUTURA v13.0"  -ForegroundColor Green
Write-Host "  ==============================================`n" -ForegroundColor Green

Write-Secao "Fase 0: Checagem de Arquivos Locais (Mega.nz)"
$arquivosCriticos = @($caminhoCisco, $caminhoJdk, $caminhoJre, $caminhoVS)
$arquivosFaltando = $false

if (!(Test-Path $pastaInstaladores)) { New-Item -ItemType Directory -Path $pastaInstaladores | Out-Null }

foreach ($arquivo in $arquivosCriticos) {
    if (-not (Test-Path $arquivo)) {
        Write-Host "  [ERRO] Faltando: $arquivo" -ForegroundColor Red
        $arquivosFaltando = $true
    } else {
        Write-Host "  [OK] Encontrado: $arquivo" -ForegroundColor Green
    }
}

if ($arquivosFaltando) {
    Write-Host "`n  FATAL: Baixe os arquivos do Mega.nz e coloque em $pastaInstaladores antes de continuar." -ForegroundColor Red
    Write-Host "  Abortando execução para evitar ambiente fragmentado." -ForegroundColor Red
    Exit
}

# ==============================================================
# 5. EXECUÇÃO PRINCIPAL
# ==============================================================
try {
    # ----------------------------------------------------------
    Write-Secao "Fase 1: Softwares Essenciais (Winget)"
    # ----------------------------------------------------------
    $apps = @(
        @("Git", "Git.Git"),
        @("GitKraken", "Axosoft.GitKraken"),
        @("VS Code", "Microsoft.VisualStudioCode"),
        @("Google Antigravity", "Google.Antigravity"),
        @(".NET SDK 9", "Microsoft.DotNet.SDK.9"),
        @("Python 3.13", "Python.Python.3.13"),
        @("Node.js LTS", "OpenJS.NodeJS.LTS"),
        @("VirtualBox", "Oracle.VirtualBox"),
        @("Arduino IDE", "ArduinoSA.IDE.stable"),
        @("MySQL Server", "Oracle.MySQL"),
        @("Power BI Desktop", "Microsoft.PowerBI")
    )

    foreach ($app in $apps) { Instalar-Winget $app[0] $app[1] }

    # ----------------------------------------------------------
    Write-Secao "Fase 2: Serviços (MySQL)"
    # ----------------------------------------------------------
    Write-Host "  >> Configurando senha root do MySQL..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 10 # Aguarda inicialização do serviço recém-instalado
    $mysqladmin = Get-ChildItem -Path "C:\Program Files\MySQL" -Filter "mysqladmin.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
    if ($mysqladmin) {
        & $mysqladmin -u root password "$senhaPadraoMySQL" 2>&1 | Out-Null
        Write-Host "     OK: Senha definida." -ForegroundColor Green
    }

    # ----------------------------------------------------------
    Write-Secao "Fase 3: Instalação de Arquivos Locais"
    # ----------------------------------------------------------
    
    # --- CISCO PACKET TRACER ---
    Write-Host "  >> Instalando: Cisco Packet Tracer..." -ForegroundColor Yellow
    Start-Process -FilePath $caminhoCisco -ArgumentList "/verysilent /suppressmsgboxes /norestart" -Wait
    Write-Host "     OK." -ForegroundColor Green

    # --- JAVA JRE ---
    Write-Host "  >> Instalando: Java JRE 8..." -ForegroundColor Yellow
    Start-Process -FilePath $caminhoJre -ArgumentList "/s" -Wait
    Write-Host "     OK." -ForegroundColor Green

    # --- JAVA JDK 26 (Exe nativo) ---
    Write-Host "  >> Instalando: Java JDK 26..." -ForegroundColor Yellow
    Start-Process -FilePath $caminhoJdk -ArgumentList "/s" -Wait
    Write-Host "     OK. Configurando Variáveis de Ambiente..." -ForegroundColor DarkGray
    
    # Nova Lógica Dinâmica para achar a pasta pós-instalação do .EXE
    Start-Sleep -Seconds 3
    if (Test-Path $pastaJavaDestino) {
        $pastaRealJdk = Get-ChildItem -Path $pastaJavaDestino -Directory | Where-Object { $_.Name -match "jdk" } | Sort-Object CreationTime -Descending | Select-Object -ExpandProperty FullName -First 1
        
        if ($pastaRealJdk) {
            [Environment]::SetEnvironmentVariable("JAVA_HOME", $pastaRealJdk, [EnvironmentVariableTarget]::Machine)
            $pathAtual = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
            $caminhoBin = "$pastaRealJdk\bin"
            
            if ($pathAtual -notlike "*$caminhoBin*") {
                $novoPath = $pathAtual + ";$caminhoBin"
                [Environment]::SetEnvironmentVariable("Path", $novoPath, [EnvironmentVariableTarget]::Machine)
            }
            Write-Host "     OK: JAVA_HOME setado para $pastaRealJdk" -ForegroundColor Green
        }
    }

    # --- VISUAL STUDIO COMMUNITY ---
    Write-Host "  >> Instalando: Visual Studio..." -ForegroundColor Yellow
    Start-Process -FilePath $caminhoVS -ArgumentList "--passive --wait --norestart --add Microsoft.VisualStudio.Workload.ManagedDesktop" -Wait
    Write-Host "     OK." -ForegroundColor Green

    # ----------------------------------------------------------
    Write-Secao "Fase 4: Extensões do VS Code"
    # ----------------------------------------------------------
    $codePath = "C:\Program Files\Microsoft VS Code\bin\code.cmd"
    $codePathAlt = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
    $comandoCode = if (Test-Path $codePath) { $codePath } elseif (Test-Path $codePathAlt) { $codePathAlt } else { $null }

    if ($comandoCode) {
        Write-Host "  >> Instalando extensões essenciais..." -ForegroundColor Yellow
        $extensoes = @("ms-dotnettools.csharp", "ms-dotnettools.csdevkit", "ms-python.python", "vscjava.vscode-java-pack", "ritwickdey.LiveServer", "eamodio.gitlens")
        foreach ($ext in $extensoes) {
            & $comandoCode --install-extension $ext --force 2>&1 | Out-Null
        }
        Write-Host "     OK: Todas as extensões injetadas." -ForegroundColor Green
    } else {
        Write-Host "     AVISO: Executável do VS Code não encontrado. Extensões puladas." -ForegroundColor DarkYellow
    }

    Write-Host "`n  ==============================================" -ForegroundColor Green
    Write-Host "   LABORATÓRIO PROVISIONADO COM SUCESSO!" -ForegroundColor Green
    Write-Host "  ==============================================`n" -ForegroundColor Green

} catch {
    Write-Host "`n  [ERRO CRÍTICO] $($_.Exception.Message)" -ForegroundColor Red
}