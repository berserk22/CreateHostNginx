CREATE USER "%webuser"@"localhost" IDENTIFIED BY "%password";
GRANT ALL PRIVILEGES ON %webuser.* TO "%webuser"@"localhost" WITH GRANT OPTION;
CREATE DATABASE %webuser;
INSERT INTO `hosts`.`hosts_liste` (`user`, `domain`, `ip`, `password`, `dname`, `duser`, `dpassword`) VALUES ('%webuser', '%host', '%ip', '%password', '%webuser', '%webuser', '%password');
