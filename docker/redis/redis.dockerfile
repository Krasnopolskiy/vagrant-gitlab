FROM redis:7.2

RUN apt update && apt install -y curl jq
