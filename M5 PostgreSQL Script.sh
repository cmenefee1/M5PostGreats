#!/bin/bash

cd /root

# Update and upgrade the system to the latest software
apt update
apt upgrade -y

# Add user postgreat, create home directory, set default password, and give sudoer privileges
useradd -U -m -s /bin/bash postgreat
usermod -aG sudo postgreat
echo "postgreat:Password!" | sudo chpasswd

# For importing and unzipping files
apt install apt-transport-https curl unzip -y

# Automated code to install PostgreSQL from: https://www.postgresql.org/download/linux/ubuntu/#apt
apt install -y postgresql-common
yes "" | sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

# Install client libraries and client binaries
apt install postgresql-client-17 -y

# Install core database server
apt install postgresql -y

# Install DBMS documentation
apt install postgresql-doc-17

# Change directory to main and create the directory to house sql_scripts
sudo su postgres
cd /var/lib/postgresql/17/main
mkdir sql_scripts
cd /var/lib/postgresql/17/main/sql_scripts

# Create sql script to create new super user postgreat
cat <<EOL > createdbusers.sql
CREATE ROLE postgreat WITH LOGIN SUPERUSER PASSWORD 'Password!';
CREATE DATABASE POS OWNER postgreat;
EOL

psql -f ~/17/main/sql_scripts/createdbusers.sql

# Exit the postgres user (not a sudoer)
exit

# Login as the postgreat user and change to the home directory
sudo su postgreat
cd /home/postgreat

# Create the database reset script (postgresql does not allow you to drop the currently used database)
cat <<EOL > dbreset.sql 
DROP DATABASE IF EXISTS pos;
CREATE DATABASE pos;
EOL

# Create the sql script that will create the database schema 
cat <<EOL > createdbschema.sql

CREATE TABLE Multiplex (
    multiplexID SERIAL PRIMARY KEY,
    streetAddress VARCHAR(30),
    city VARCHAR(20),
    state VARCHAR(2),
    zip VARCHAR(5)
);

CREATE TABLE Theater (
    theaterID SERIAL PRIMARY KEY,
    multiplexID INT,
    theaterName VARCHAR(30),
    FOREIGN KEY (multiplexID) REFERENCES Multiplex(multiplexID)
);

CREATE TABLE RoomNumber (
    roomID SERIAL PRIMARY KEY,
    theaterID INT,
    seatingCapacity INT,
    screenType VARCHAR(30),
    FOREIGN KEY (theaterID) REFERENCES Theater(theaterID)
);

CREATE TABLE Movie (
    movieID SERIAL PRIMARY KEY,
    movieTitle VARCHAR(150),
    genre VARCHAR(30),
    rating VARCHAR(5)
);

CREATE TABLE TimeSlot (
    timeSlotID SERIAL PRIMARY KEY,
    startTime VARCHAR(5),
    duration VARCHAR(5)
);

CREATE TABLE Theater_Movie_TimeSlot (
    roomID INT,
    movieID INT,
    timeSlotID INT,
    PRIMARY KEY (roomID, movieID, timeSlotID),
    FOREIGN KEY (roomID) REFERENCES RoomNumber(roomID),
    FOREIGN KEY (movieID) REFERENCES Movie(movieID),
    FOREIGN KEY (timeSlotID) REFERENCES TimeSlot(timeSlotID)
);


CREATE TABLE Ticket (
    ticketNumber SERIAL PRIMARY KEY,
    movieID INT,
    customerType VARCHAR(20),
    price DECIMAL(4, 2),
    FOREIGN KEY (movieID) REFERENCES Movie(movieID)
);
EOL

# Run the reset script from postgres
psql -U postgreat -d postgres -f dbreset.sql

# Use createdbschema to populate the pos database
psql -U postgreat -d pos -f createdbschema.sql


