# FHIR-RU knowledge base

[Landing](http://fhir-ru.zendoc.me/manifest)

## Run locally

* install java
* [install clojure](https://clojure.org/guides/getting_started#_clojure_installer_and_cli_tools)
* [install babashka](https://github.com/babashka/babashka#installation)

```bash
git clone git@github.com:fhir-ru/zendoc.git fhir-ru

cd fhir-ru
git submodule init
git submodule update --recursive

bb dev
open http://localhost:3333
# edit  /docs

```

## Run with docker-compose

```bash
git clone git@github.com:fhir-ru/zendoc.git fhir-ru
cd fhir-ru

# Build and start (submodules are handled automatically in Docker)
docker-compose up --build

# Or run in background
docker-compose up -d

# See logs
docker-compose logs -f

# Stop
docker-compose down
```

## Run with pre-built image

```bash
docker run -p 3333:3333 ghcr.io/fhir-ru/zendoc:latest
```

Then open http://localhost:3333

## zendoc basics

Each document is a resource, which consists of keys and values.
zendoc has a specific syntax, which is superset of EDN

### EDN basics

Read about [EDN](https://learnxinyminutes.com/docs/edn/)

### Links


### Diagrams

Zendoc supports mermaid syntax - [read more](https://mermaid-js.github.io/mermaid/#/)

```
^title "Моя диаграмма"
:diagram mm/

  classDiagram
    class BankAccount
    BankAccount : +String owner
    BankAccount : +Bigdecimal balance
    BankAccount : +deposit(amount)
    BankAccount : +withdrawl(amount)

```

## Deploy

Make your changes and push into repository!
Result will be available on http://fhir-ru.zendoc.me/manifest in a few minutes.
