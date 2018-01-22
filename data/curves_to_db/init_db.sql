-- Se loguer avec droits admin sur un serveur PostgreSQL
-- (en local ou non). Puis :

-- superuser status required to use command 'copy' ...
create role irsdi with superuser login password 'irsdi2017';
create database edf25m with owner irsdi;
\c edf25m irsdi -- connect to DB as irsdi
create table series ( id serial primary key, curve real[] );
