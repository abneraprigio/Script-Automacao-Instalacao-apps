🚀 Script de Provisionamento de Laboratório (PowerShell)

Automação completa para instalação e configuração de ambiente de desenvolvimento e redes.

📌 Sobre o Projeto

Este script PowerShell foi desenvolvido para provisionamento automatizado de máquinas, com foco em ambientes educacionais e laboratoriais.

Ele realiza desde a instalação de ferramentas essenciais até a configuração de variáveis de ambiente e serviços, reduzindo drasticamente o tempo de setup manual.

⚙️ Funcionalidades

✔ Validação de execução como Administrador
✔ Criação automática de diretórios padrão
✔ Instalação de softwares via Winget
✔ Download automático de arquivos via Dropbox
✔ Instalação silenciosa de aplicações
✔ Extração automática de arquivos .zip
✔ Configuração de variáveis de ambiente (JAVA_HOME e PATH)
✔ Configuração inicial do MySQL (senha root)
✔ Instalação de extensões no VS Code

🧰 Softwares Instalados
📦 Via Winget
Git
GitKraken
Visual Studio Code
.NET SDK 9
Python 3.13
Node.js LTS
VirtualBox
Arduino IDE
MySQL Server
Power BI Desktop
📥 Via Download (Dropbox / Web)
Cisco Packet Tracer
Java JRE 8
Java JDK 26 (ZIP)
Visual Studio Community
⚡ Etapas do Script
🔹 Fase 1: Instalação via Winget

Instala automaticamente ferramentas essenciais para desenvolvimento e laboratório.

🔹 Fase 2: Configuração do MySQL
Aguarda instalação
Define senha padrão do root:
senai105
🔹 Fase 3: Downloads e Instalações
Baixa instaladores automaticamente
Executa instalação silenciosa
Extrai o JDK
Configura variáveis de ambiente:
JAVA_HOME
PATH
🔹 Fase 4: VS Code

Instala automaticamente extensões:

C#
Python
Java
Live Server
GitLens
📂 Estrutura de Diretórios
C:\Instaladores        → Armazena todos os instaladores
C:\Program Files\Java  → Destino do JDK
▶️ Como Executar
1. Clonar o repositório
git clone https://github.com/abneraprigio/Script-Automacao-Instalacao-apps.git
2. Abrir PowerShell como Administrador

⚠️ Obrigatório

3. Liberar execução de scripts
Set-ExecutionPolicy Bypass -Scope Process -Force
4. Executar o script
.\Script_Automacao.ps1
🔐 Requisitos
Windows 10/11
PowerShell 5.1+
Conexão com internet
Permissão de administrador
Winget instalado
⚠️ Observações
O script utiliza links diretos do Dropbox (com dl=1)
Pode levar tempo dependendo da internet
Algumas instalações podem demorar (ex: Visual Studio)
💡 Possíveis Melhorias
 Sistema de logs detalhado
 Interface gráfica (GUI)
 Tratamento avançado de erros
 Parametrização de instalações
 Integração com Chocolatey
👨‍💻 Autor

Abner Aprigio
