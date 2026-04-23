<#
.SYNOPSIS
    Script de Provisionamento de Laboratório (v11.0 - Dev Focus & Dropbox)
    Foco: Instalação de Ferramentas, injeção de ZIPs e Variáveis de Ambiente.
#>

$ErrorActionPreference = "Continue"

# ==============================================================
# 1. VALIDAÇÃO DE PRIVILÉGIOS (ADMINISTRADOR)
# ==============================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "ERRO CRÍTICO: Este script PRECISA ser executado como Administrador."
    Start-Sleep -Seconds 5
    Exit
}

# ==============================================================
# 2. VARIÁVEIS GERAIS E LINKS DROPBOX (Com dl=1 obrigatório)
# ==============================================================
$senhaPadraoMySQL  = "senai105"
$pastaInstaladores = "C:\Instaladores" 
$pastaJavaDestino  = "C:\Program Files\Java"

# Links de Download
$urlCisco = "https://www.dropbox.com/scl/fi/g7w7a6pfysjaqepwdm1ao/CiscoPacketTracer_900_win_64bit.exe?rlkey=gzy4tqx8axm7kmv6kam6wrbgb&st=zqsyl385&dl=1"
$urlJre   = "https://www.dropbox.com/scl/fi/3ntor70af07fykn3d9msp/jre-8u491-windows-x64-1.exe?rlkey=t1lnmueuox6lfc7vk1qdyc4la&st=nq9qcufu&dl=1"
$urlJdk   = "https://www.dropbox.com/scl/fi/xxdu4tkjc1t707uzdzcmr/jdk-26_windows-x64_bin.zip?rlkey=lzea5cjqxtrpn4o9gdmmmxh2u&st=bxbajg0a&dl=1"
$urlVS    = "https://aka.ms/vs/17/release/vs_community.exe"

# Caminhos Locais
$caminhoCisco = Join-Path $pastaInstaladores "CiscoPacketTracer.exe"
$caminhoJre   = Join-Path $pastaInstaladores "jre-8u491.exe"
$caminhoJdk   = Join-Path $pastaInstaladores "jdk-26.zip"
$caminhoVS    = Join-Path $pastaInstaladores "vs_setup.exe"

# ==============================================================
# 3. FUNÇÕES AUXILIARES
# ==============================================================
function Write-Secao($texto) {
    Write-Host "`n  ----------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  $texto" -ForegroundColor Cyan
    Write-Host "  ----------------------------------------------" -ForegroundColor DarkGray
}

function Instalar-Winget($nome, $id) {
    Write-Host "  >> Instalando (Winget): $nome..." -ForegroundColor Yellow
    winget install --exact --id $id --accept-package-agreements --accept-source-agreements --silent --force
    if ($LASTEXITCODE -eq 0) {
        Write-Host "     OK: Instalado com sucesso." -ForegroundColor Green
    } elseif ($LASTEXITCODE -eq -1978335189 -or $LASTEXITCODE -eq -1978335215) {
        Write-Host "     INFO: Já está instalado ou atualizado." -ForegroundColor DarkYellow
    } else {
        Write-Host "     AVISO: Erro no Winget ($LASTEXITCODE)." -ForegroundColor Red
    }
}

function Baixar-Arquivo($url, $caminhoDestino, $nomeAmigavel) {
    if (!(Test-Path $caminhoDestino)) {
        Write-Host "  >> Baixando: $nomeAmigavel..." -ForegroundColor Yellow
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $url -OutFile $caminhoDestino -UseBasicParsing
            Write-Host "     OK: Download concluído." -ForegroundColor Green
        } catch {
            Write-Host "     ERRO: Falha ao baixar $nomeAmigavel." -ForegroundColor Red
        }
    } else {
        Write-Host "     INFO: $nomeAmigavel já existe na pasta." -ForegroundColor DarkYellow
    }
}

# ==============================================================
# 4. EXECUÇÃO PRINCIPAL
# ==============================================================
Clear-Host
Write-Host "`n  ==============================================" -ForegroundColor Green
Write-Host "   PROVISIONAMENTO DEV - LABORATÓRIO v11.0"  -ForegroundColor Green
Write-Host "  ==============================================`n" -ForegroundColor Green

try {
    if (!(Test-Path $pastaInstaladores)) { New-Item -ItemType Directory -Path $pastaInstaladores | Out-Null }
    if (!(Test-Path $pastaJavaDestino)) { New-Item -ItemType Directory -Path $pastaJavaDestino | Out-Null }

    # ----------------------------------------------------------
    Write-Secao "Fase 1: Ferramentas Winget"
    # ----------------------------------------------------------
    Instalar-Winget "Git" "Git.Git"
    Instalar-Winget "GitKraken" "Axosoft.GitKraken"
    Instalar-Winget "Visual Studio Code" "Microsoft.VisualStudioCode"
    Instalar-Winget "Google Antigravity" "Google.Antigravity"
    Instalar-Winget ".NET SDK 9" "Microsoft.DotNet.SDK.9"
    Instalar-Winget "Python 3.13" "Python.Python.3.13"
    Instalar-Winget "Node.js LTS" "OpenJS.NodeJS.LTS"
    Instalar-Winget "VirtualBox" "Oracle.VirtualBox"
    Instalar-Winget "Arduino IDE" "ArduinoSA.IDE.stable"
    Instalar-Winget "MySQL Server" "Oracle.MySQL"
    Instalar-Winget "Power BI Desktop" "Microsoft.PowerBI"

    # ----------------------------------------------------------
    Write-Secao "Fase 2: Serviços (MySQL)"
    # ----------------------------------------------------------
    Write-Host "  >> Configurando MySQL..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 15 
    $mysqladmin = Get-ChildItem -Path "C:\Program Files\MySQL" -Filter "mysqladmin.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
    if ($mysqladmin) {
        & $mysqladmin -u root password "$senhaPadraoMySQL" 2>&1 | Out-Null
        Write-Host "     OK: Senha root definida." -ForegroundColor Green
    }

    # ----------------------------------------------------------
    Write-Secao "Fase 3: Downloads via Dropbox e Instalações"
    # ----------------------------------------------------------
    Baixar-Arquivo $urlCisco $caminhoCisco "Cisco Packet Tracer"
    Baixar-Arquivo $urlJre $caminhoJre "Java JRE 8"
    Baixar-Arquivo $urlJdk $caminhoJdk "Java JDK 26 (ZIP)"
    Baixar-Arquivo $urlVS $caminhoVS "Visual Studio Bootstrapper"

    # --- CISCO PACKET TRACER ---
    if (Test-Path $caminhoCisco) {
        Write-Host "  >> Instalando: Cisco Packet Tracer..." -ForegroundColor Yellow
        Start-Process -FilePath $caminhoCisco -ArgumentList "/verysilent /suppressmsgboxes /norestart" -Wait
    }

    # --- JAVA JRE (Executável) ---
    if (Test-Path $caminhoJre) {
        Write-Host "  >> Instalando: Java JRE..." -ForegroundColor Yellow
        Start-Process -FilePath $caminhoJre -ArgumentList "/s" -Wait
    }

    # --- JAVA JDK (Descompactação e Variáveis de Ambiente) ---
    if (Test-Path $caminhoJdk) {
        $destinoJdkExtraido = Join-Path $pastaJavaDestino "jdk-26"
        if (!(Test-Path $destinoJdkExtraido)) {
            Write-Host "  >> Descompactando: Java JDK 26..." -ForegroundColor Yellow
            Expand-Archive -Path $caminhoJdk -DestinationPath $pastaJavaDestino -Force
            Write-Host "     OK: Extraído em $pastaJavaDestino" -ForegroundColor Green
            
            # Como ZIPs de Java costumam criar uma subpasta (ex: jdk-26.0.x), vamos pegar a pasta criada
            $pastaRealJdk = Get-ChildItem -Path $pastaJavaDestino -Directory | Where-Object { $_.Name -like "*jdk*" } | Select-Object -ExpandProperty FullName -First 1
            
            Write-Host "  >> Configurando JAVA_HOME e PATH..." -ForegroundColor Yellow
            [Environment]::SetEnvironmentVariable("JAVA_HOME", $pastaRealJdk, [EnvironmentVariableTarget]::Machine)
            
            $pathAtual = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
            $caminhoBin = "$pastaRealJdk\bin"
            if ($pathAtual -notlike "*$caminhoBin*") {
                $novoPath = $pathAtual + ";$caminhoBin"
                [Environment]::SetEnvironmentVariable("Path", $novoPath, [EnvironmentVariableTarget]::Machine)
            }
        } else {
            Write-Host "     INFO: JDK 26 já descompactado." -ForegroundColor DarkYellow
        }
    }

    # --- VISUAL STUDIO COMMUNITY ---
    if (Test-Path $caminhoVS) {
        Write-Host "  >> Instalando: Visual Studio Community..." -ForegroundColor Yellow
        Start-Process -FilePath $caminhoVS -ArgumentList "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.ManagedDesktop" -Wait
    }

    # ----------------------------------------------------------
    Write-Secao "Fase 4: Extensões do VS Code"
    # ----------------------------------------------------------
    $codePath = "C:\Program Files\Microsoft VS Code\bin\code.cmd"
    $codePathAlt = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
    $comandoCode = if (Test-Path $codePath) { $codePath } elseif (Test-Path $codePathAlt) { $codePathAlt } else { $null }

    if ($comandoCode) {
        Write-Host "  >> Instalando extensões..." -ForegroundColor Yellow
        $extensoes = @("ms-dotnettools.csharp", "ms-dotnettools.csdevkit", "ms-python.python", "vscjava.vscode-java-pack", "ritwickdey.LiveServer", "eamodio.gitlens")
        foreach ($ext in $extensoes) {
            & $comandoCode --install-extension $ext --force 2>&1 | Out-Null
        }
        Write-Host "     OK: Extensões instaladas." -ForegroundColor Green
    }

    Write-Host "`n  ==============================================" -ForegroundColor Green
    Write-Host "   INSTALAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "  ==============================================`n" -ForegroundColor Green

} catch {
    Write-Host "`n  [ERRO] $($_.Exception.Message)" -ForegroundColor Red
}