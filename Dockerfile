# Build stage
FROM nginx:1.27-alpine AS builder

# Custom welcome page
RUN echo '<!DOCTYPE html>\n\
<html lang="en">\n\
<head>\n\
  <meta charset="UTF-8">\n\
  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n\
  <title>Auto-Healing Web Tier</title>\n\
  <style>\n\
    body {\n\
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;\n\
      display: flex;\n\
      align-items: center;\n\
      justify-content: center;\n\
      height: 100vh;\n\
      margin: 0;\n\
      background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);\n\
      color: white;\n\
    }\n\
    .container {\n\
      text-align: center;\n\
      padding: 2rem;\n\
    }\n\
    h1 { font-size: 2.5rem; margin-bottom: 0.5rem; }\n\
    p { font-size: 1.2rem; opacity: 0.9; }\n\
    .badge {\n\
      display: inline-block;\n\
      margin-top: 1rem;\n\
      padding: 0.5rem 1rem;\n\
      background: rgba(255,255,255,0.2);\n\
      border-radius: 999px;\n\
      font-size: 0.9rem;\n\
    }\n\
  </style>\n\
</head>\n\
<body>\n\
  <div class="container">\n\
    <h1>🚀 Auto-Healing Web Tier</h1>\n\
    <p>This page is served from a containerised NGINX instance behind an ALB.</p>\n\
    <p>Terminate any instance and watch it self-heal!</p>\n\
    <div class="badge">Powered by Terraform + Docker + AWS</div>\n\
  </div>\n\
</body>\n\
</html>' > /usr/share/nginx/html/index.html

# Add health endpoint
RUN mkdir -p /usr/share/nginx/html/health && \
    echo '{"status":"healthy"}' > /usr/share/nginx/html/health/index.html

# Final stage
FROM nginx:1.27-alpine
COPY --from=builder /usr/share/nginx/html /usr/share/nginx/html

# Health check for Docker
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/health/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
