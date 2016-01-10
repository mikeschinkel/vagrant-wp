# noinspection SqlNoDataSourceInspectionForFile

CREATE DATABASE IF NOT EXISTS wplib CHARSET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'vagrant' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'vagrant' WITH GRANT OPTION;
FLUSH PRIVILEGES;

