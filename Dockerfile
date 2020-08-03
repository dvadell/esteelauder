FROM tianon/mojo

RUN cpanm UUID::Tiny

WORKDIR /code
CMD morbo index.pl
