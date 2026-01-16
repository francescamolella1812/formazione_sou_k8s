# Formazione SOU – CI/CD, Jenkins e Kubernetes

Questo repository contiene il materiale sviluppato durante il modulo formativo **SOU – CI/CD e Kubernetes**.  
L’obiettivo del progetto è esercitarsi nell’utilizzo combinato di Jenkins, Docker, Helm e Kubernetes per il build e il deploy di una semplice 
applicazione Flask.

Il laboratorio copre:
- build di immagini Docker tramite Jenkins
- gestione del versioning delle immagini
- deploy applicativo su Kubernetes tramite Helm
- interazione con le risorse Kubernetes
- verifica delle best practices di deployment
- esposizione dell’applicazione tramite Ingress

---

## Tecnologie utilizzate

- Docker / Podman
- Jenkins
- Git
- Groovy (Jenkins Pipeline)
- Flask (Python)
- Kubernetes (Kind / Minikube / K3s)
- Helm
- CI/CD
- Configuration Management

---

## Struttura del repository

```text
formazione_sou_k8s/
├── Dockerfile
├── Jenkinsfile
├── README.md
├── hello.py
├── kubeconfig-kind-dev
│
├── charts/
│   └── flask-example/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── kind-ingress.yaml
│       ├── sa-cluster-reader.yaml
│       ├── serviceaccount.sh
│       ├── token.txt
│       ├── charts/
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── httproute.yaml
│           ├── hpa.yaml
│           ├── serviceaccount.yaml
│           ├── NOTES.txt
│           ├── _helpers.tpl
│           └── tests/
│               └── test-connection.yaml


## Applicazione Flask

L'applicazione e' un esempio minimale Flask che risponde su `/` con la stringa "Hello World".

- `hello.py`: codice applicazione
- `Dockerfile`: immagine basata su `ubuntu:22.04`, installa Python e Flask e avvia `flask run` sulla porta `8000`

---

## Jenkins Pipeline

Il file `Jenkinsfile` definisce una pipeline che esegue:

- Checkout del codice (branch `main`) da GitHub tramite credenziale SSH Jenkins
- Calcolo del tag immagine come short SHA del commit:
  - `IMAGE_TAG = git rev-parse --short HEAD`
- Build immagine Docker e tagging:
  - `${DOCKER_IMAGE}:${IMAGE_TAG}`
  - `${DOCKER_IMAGE}:latest`
- Login e push su Docker Hub tramite credenziali Jenkins:
  - push del tag `${IMAGE_TAG}`
  - push del tag `latest`
- Deploy locale su Jenkins agent (container Docker):
  - pull `latest`
  - stop e remove del container `flask-app` se esiste
  - run del container mappando `5000:8000`
- Deploy su Kubernetes tramite Helm:
  - usa un kubeconfig fornito come credenziale Jenkins (Secret file)
  - crea (o applica) il namespace `formazione-sou`
  - esegue `helm upgrade --install` del chart `charts/flask-example`
  - imposta `image.repository` e `image.tag` in base alla pipeline
- Check deployment:
  - esegue `charts/flask-example/serviceaccount.sh`

### Variabili pipeline principali

- `DOCKER_IMAGE`: repository immagine su Docker Hub (es. `francesca1812/myimage`)
- `IMAGE_TAG`: short SHA del commit (es. `a1b2c3d`)
- namespace Kubernetes: `formazione-sou`

---

## Helm Chart

Il chart Helm `charts/flask-example` include template per:
- Deployment
- Service
- Ingress
- HPA (autoscaling)
- ServiceAccount (e risorse collegate)

---

## Step del modulo (mappati a questo progetto)

- Step 2: pipeline Jenkins per build e push immagine Docker (Docker Hub)
- Step 3: creazione Helm Chart (`charts/flask-example`)
- Step 4: helm install/upgrade su cluster locale Kind nel namespace `formazione-sou`
- Step 5: utilizzo ServiceAccount cluster-reader e script di check (`serviceaccount.sh`)
- Step 6: esposizione tramite Ingress (`ingress.yaml`, `kind-ingress.yaml`)

