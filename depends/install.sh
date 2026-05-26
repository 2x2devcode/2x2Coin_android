#!/bin/bash

# Cores para o terminal
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
log_error() { echo -e "${RED}[ERRO]${NC} $1"; exit 1; }

echo "================================================================="
echo "   Instalador de Dependências para Compilação 2x2Coin Android    "
echo "================================================================="

# 1. Validar Sistema Operacional
log_info "Verificando Sistema Operacional..."
if ! grep -q "22.04" /etc/os-release; then
    log_warn "Este script foi otimizado para o Ubuntu 22.04. Seu sistema pode apresentar incompatibilidades."
else
    log_success "Ubuntu 22.04 detectado."
fi

# 2. Lista de dependências divididas por categoria
# Pacotes APT (A validação é feita via dpkg)
APT_DEPS=(
    "build-essential" "cmake" "git" "curl" "wget" "zip" "unzip" 
    "python3" "python3-pip" "libssl-dev" "libboost-all-dev" 
    "libdb++-dev" "libminiupnpc-dev" "libevent-dev" "openjdk-17-jdk" 
    "openjdk-17-jre" "default-jdk-headless" "apksigner" "zipalign" 
    "libgl1-mesa-dev" "libxcb-xinerama0" "libxcb-cursor0" 
    "libfontconfig1" "libx11-xcb1"
)

# Ferramentas de linha de comando críticas para checagem direta
CMD_DEPS=("make" "g++" "cmake" "git" "javac" "keytool" "apksigner" "zipalign")

MISSING_APTS=""

# 3. Mapeamento de dependências ausentes
log_info "Analisando pacotes do sistema já instalados..."
for pkg in "${APT_DEPS[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo -e "  [S] $pkg"
    else
        echo -e "  [${RED}X${NC}] $pkg"
        MISSING_APTS="$MISSING_APTS $pkg"
    fi
done

# 4. Instalação se necessário
if [ -n "$MISSING_APTS" ]; then
    log_warn "Os seguintes pacotes estão ausentes e serão instalados: $MISSING_APTS"
    log_info "Atualizando índices do apt (sudo apt update)..."
    sudo apt update || log_error "Falha ao atualizar o gerenciador de pacotes apt."
    
    log_info "Instalando pacotes ausentes..."
    sudo apt install -y $MISSING_APTS
    if [ $? -ne 0 ]; then
        log_error "Ocorreu um erro durante a instalação dos pacotes via apt."
    fi
else
    log_success "Todos os pacotes base do APT já estão instalados."
fi

# 5. Verificação Pós-Instalação Detalhada
echo "-----------------------------------------------------------------"
log_info "Iniciando verificação de integridade pós-instalação..."
ERROS_FATAIS=0

# Validar binários no PATH
for cmd in "${CMD_DEPS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Comando '$cmd' operacional: $(which $cmd)"
    else
        echo -e "  ${RED}✗${NC} Comando '$cmd' NÃO ENCONTRADO no sistema!"
        ERROS_FATAIS=$((ERROS_FATAIS + 1))
    fi
done

# Validar versão do Java especificamente (exigência do Gradle)
if command -v java &> /dev/null; then
    JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
    if [ "$JAVA_VER" -eq 17 ] 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Versão correta do Java detectada (Java 17)."
    else
        log_warn "O Java padrão do seu sistema não é a versão 17. O Gradle pode falhar."
    fi
fi

# 6. Relatório Final
echo "-----------------------------------------------------------------"
if [ "$ERROS_FATAIS" -eq 0 ]; then
    log_success "Parabéns! Todas as dependências foram instaladas e verificadas com sucesso."
    echo "[INFO] Seu Ubuntu 22.04 está 100% pronto para rodar o './build_android.sh'."
else
    log_error "A instalação terminou, mas $ERROS_FATAIS ferramenta(s) crítica(s) falharam na validação."
fi
echo "================================================================="
