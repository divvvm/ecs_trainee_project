FROM ghcr.io/open-webui/open-webui:main

RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

COPY init_db.sh /init_db.sh
RUN chmod +x /init_db.sh

EXPOSE 8080

ENTRYPOINT ["/init_db.sh"]
CMD ["npm", "run", "start"]