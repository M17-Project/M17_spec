FROM alpine

RUN apk add git
RUN git clone https://git.m17project.org/m17/M17_spec.git

FROM sphinxdoc/sphinx

COPY --from=0 M17_spec /docs
RUN pip install -r docs/requirements.txt
RUN cd docs && make html

FROM nginx:alpine
COPY --from=1 /docs/docs/_build/html /usr/share/nginx/html
