# syntax=docker/dockerfile:1.7
FROM continuumio/miniconda3:24.7.1-0

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    CONDA_HTTP_TIMEOUT=120 \
    CONDA_SOLVER=libmamba

RUN --mount=type=cache,target=/opt/conda/pkgs \
    conda install -y -c conda-forge mamba curl && \
    conda clean -afy

RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba install -y -c conda-forge -c bioconda \
      crispresso2 \
      bowtie2 \
      samtools \
      fastqc \
      pigz && \
    conda clean -afy

RUN useradd -m -u 1000 appuser

WORKDIR /crispr-shiny

COPY requirements.txt /crispr-shiny/requirements.txt
RUN python -m pip install --no-cache-dir -r /crispr-shiny/requirements.txt

COPY . /crispr-shiny

RUN mkdir -p /outputs && \
    chown -R appuser:appuser /crispr-shiny /outputs

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD curl -fsS http://localhost:8000/ || exit 1

CMD ["sh", "-c", "shiny run --host 0.0.0.0 --port 8000 /crispr-shiny/app.py"]
