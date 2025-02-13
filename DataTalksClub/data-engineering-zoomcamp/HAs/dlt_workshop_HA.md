# DTC data-engineering-zoomcamp - dlt Workshop HA

## 0. Preparations
I had to launch Jupyter on GCP VM because there I have Anaconda Python `3.12` distribution. My local Python `3.8` distribution installed `dlt` version `1.5.0` but had too many issues when creating a pipeline, starting with `packaging` package that prevented me from continuation on a local machine.

```
cannot import name '_TrimmedRelease' from 'packaging.version'
```

On the GCP VM with Python `3.12` I created and launched a Jupyter Notebook which can be found in `./code/dlt_workshop/dlt_workshop_HA.ipynb`.