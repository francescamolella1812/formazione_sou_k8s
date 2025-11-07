FROM ubuntu:22.04

# installo dipendenze
RUN apt-get update && apt-get install -y python3 python3-pip

# Installo Flask (versione 3.0.x).

RUN pip install flask==3.0.*


# Copia il file hello.py dalla cartella locale (dove si fa la build) nella root del container /.
COPY hello.py /


# Definisce una variabile d’ambiente che dice a Flask quale app eseguire.
ENV FLASK_APP=hello 
# Serve per “documentare” la porta esposta dal container
EXPOSE 8000
# Definisce il comando di default che Docker eseguirà quando il container parte.
CMD [ "flask", "run", "--host", "0.0.0.0", "--port", "8000" ]
