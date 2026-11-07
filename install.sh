#!/data/data/com.termux/files/usr/bin/bash
# Terminux + Local AI Fully Automated Installer

set -uo pipefail

REPO_URL="${TERMINUX_REPO:-https://github.com/aishervin/Terminux.git}"
BRANCH="${TERMINUX_BRANCH:-main}"
INSTALL_DIR="${TERMINUX_DIR:-$HOME/Terminux}"
WORKSPACE_DIR="${TERMINUX_WORKSPACE:-$HOME/Terminux-workspace}"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
TERMUX_BASH="${PREFIX:-/data/data/com.termux/files/usr}/bin/bash"

# Colors
O=$'\033[38;5;208m'; W=$'\033[97m'; D=$'\033[90m'; OK=$'\033[38;5;114m'; E=$'\033[38;5;203m'; C=$'\033[36m'; B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'

banner() {
  clear 2>/dev/null || true
  printf "${O}${B}--- نصب خودکار Terminux + هوش مصنوعی آفلاین ---${R}\n\n"
}

fail() { printf "\n\n${E}${B}✕ خطای نصب:%s${R}\n\n" "$*" >&2; exit 1; }

banner
# 1. نصب بسته‌های ضروری (شامل ابزارهای کامپایلر)
echo "۱/۶ در حال نصب ابزارهای پایه و موتور AI..."
pkg update -y && pkg install -y nodejs-lts git clang cmake make python wget || fail "نصب بسته‌ها ناموفق بود."

# 2. دریافت و کامپایل موتور هوش مصنوعی (llama.cpp)
echo "۲/۶ در حال کامپایل موتور هوش مصنوعی (این مرحله ممکن است زمان‌بر باشد)..."
[ ! -d "$HOME/llama.cpp" ] && git clone https://github.com/ggerganov/llama.cpp "$HOME/llama.cpp"
cd "$HOME/llama.cpp" && make -j4 || fail "کامپایل موتور AI ناموفق بود."

# 3. دریافت مدل کدنویسی Qwen2.5-Coder (خودکار)
echo "۳/۶ در حال دریافت مدل هوش مصنوعی..."
mkdir -p "$HOME/Terminux/models"
[ ! -f "$HOME/Terminux/models/coder.gguf" ] && wget -O "$HOME/Terminux/models/coder.gguf" "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"

# 4. آماده‌سازی سورس و npm
echo "۴/۶ در حال آماده‌سازی پروژه Terminux..."
[ ! -d "$INSTALL_DIR" ] && git clone "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR" && npm install || fail "نصب وابستگی‌های پروژه ناموفق بود."

# 5. ساخت دستور اجرایی یکپارچه
echo "۵/۶ ساخت میانبر اجرایی..."
cat > "$PREFIX_BIN/terminux" <<EOF
#!${TERMUX_BASH}
# اجرای هوش مصنوعی آفلاین در پس‌زمینه
$HOME/llama.cpp/server -m $HOME/Terminux/models/coder.gguf --port 8080 --threads 4 > /dev/null 2>&1 &
echo "AI Server started on port 8080..."
# اجرای رابط کاربری
cd "${INSTALL_DIR}"
export OPENCODE_PORT=8080
exec ./node_modules/.bin/tsx src/server.ts
EOF
chmod +x "$PREFIX_BIN/terminux"

echo "۶/۶ تکمیل و راه‌اندازی..."
echo "--- نصب با موفقیت پایان یافت! ---"
echo "دستور اجرا: terminux"
