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

# 生成根导航页：把两套原型库索引到一起
RUN mkdir -p /build/out && \
    cp -r /build/src/lp          /build/out/lp && \
    cp -r /build/src/prototypes  /build/out/prototypes && \
    { \
      echo '<!DOCTYPE html>'; \
      echo '<html lang="zh-CN"><head><meta charset="utf-8">'; \
      echo '<meta name="viewport" content="width=device-width,initial-scale=1">'; \
      echo '<title>简历罗盘 · 原型站点</title>'; \
      echo '<style>'; \
      echo '*{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-content:center;'; \
      echo 'background:#08080B;color:#EDEDF2;font-family:"PingFang SC","Microsoft YaHei",system-ui,sans-serif;padding:40px 22px}'; \
      echo '.box{max-width:720px;text-align:center}'; \
      echo 'h1{margin:0 0 14px;font-size:clamp(28px,5vw,44px);font-weight:800;letter-spacing:-.03em}'; \
      echo 'p{margin:0 auto 38px;max-width:520px;color:#9CA3AF;line-height:1.75;font-size:15px}'; \
      echo '.links{display:grid;gap:16px;grid-template-columns:repeat(auto-fit,minmax(260px,1fr))}'; \
      echo 'a{display:block;padding:26px 24px;border:1px solid rgba(255,255,255,.1);border-radius:16px;'; \
      echo 'text-decoration:none;color:inherit;background:rgba(255,255,255,.035);transition:.4s cubic-bezier(.16,1,.3,1)}'; \
      echo 'a:hover{transform:translateY(-5px);border-color:rgba(129,140,248,.55);background:rgba(129,140,248,.09)}'; \
      echo 'b{display:block;font-size:17px;font-weight:720;margin-bottom:7px}'; \
      echo 'span{font-size:13px;color:#8B8B96;line-height:1.6}'; \
      echo '</style></head><body><div class="box">'; \
      echo '<h1>简历罗盘 · 原型站点</h1>'; \
      echo '<p>AI 简历润色网站的设计原型集合。全部为纯静态 HTML，点击任意入口即可浏览。</p>'; \
      echo '<div class="links">'; \
      echo '<a href="/lp/"><b>落地页原型 · 20 套</b><span>视差海报落地页，含首屏海报 + 特性带 + 收尾行动</span></a>'; \
      echo '<a href="/prototypes/"><b>功能页原型 · 11 套</b><span>覆盖诊断、匹配、改写、支付等完整流程</span></a>'; \
      echo '</div></div></body></html>'; \
    } > /build/out/index.html && \
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
