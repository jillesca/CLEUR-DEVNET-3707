# First stage: build
FROM ciscotestautomation/pyats:latest as builder

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=true \
    PIP_ROOT_USER_ACTION=ignore \
    PIP_NO_WARN_SCRIPT_LOCATION=0 \
    PIP_DISABLE_ROOT_WARNING=ignore

COPY llm_agent/requirements.txt /home/llm_agent/requirements.txt

RUN pip install --upgrade pip \
    && pip install -r /home/llm_agent/requirements.txt

# Second stage: runtime
FROM ciscotestautomation/pyats:latest

COPY --from=builder /usr/local /usr/local
# COPY llm_agent /home/llm_agent

RUN echo 'alias ll="ls -al"' >> ~/.bashrc

WORKDIR /home/llm_agent

# docker build -f llm_agent.Dockerfile -t llm .
# docker run -itd -v $(pwd)/llm_agent:/home/llm_agent --name llm llm
# docker exec -it llm /bin/bash
# docker rm -f llm