# ============================================================
# 简历罗盘 · 静态原型站点
# 多阶段构建：构建期整理产物 → 运行期仅用 nginx 提供静态服务
# 默认端口 7999
# ============================================================

# ---------- Stage 1：整理静态产物 ----------
FROM alpine:3.20 AS builder

WORKDIR /build

# 拷贝全部静态资源（保持目录结构）
COPY src/ ./src/

# 整理产物：仅保留落地页，lp/ 的内容平铺为站点根（总览页即 index.html，
# 内页与总览页同级，页面内相对链接 href="01-*.html" 才能命中）
RUN mkdir -p /build/out && \
    cp /build/src/lp/*.html /build/out/ && \
    cp /build/src/lp/00-index.html /build/out/index.html && \
    rm -f /build/out/00-index.html && \
    { \
      echo '<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">'; \
      echo '<title>404 · 页面不存在</title>'; \
      echo '<style>body{margin:0;min-height:100vh;display:grid;place-content:center;text-align:center;'; \
      echo 'background:#08080B;color:#EDEDF2;font-family:system-ui,sans-serif}'; \
      echo 'a{color:#818CF8}</style></head><body><div>'; \
      echo '<h1 style="font-size:56px;margin:0">404</h1>'; \
      echo '<p style="color:#9CA3AF">这个页面不存在</p>'; \
      echo '<a href="/">返回首页</a></div></body></html>'; \
    } > /build/out/404.html && \
    find /build/out -type f -name '*.html' | wc -l > /build/out/.htmlcount && \
    echo "构建完成，HTML 文件数：$(cat /build/out/.htmlcount)"

# ---------- Stage 2：nginx 运行时 ----------
FROM nginx:1.27-alpine AS runtime

# 站点配置
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# 静态产物
COPY --from=builder /build/out /usr/share/nginx/html

EXPOSE 7999

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:7999/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
