
create table databaseVersion (
    versionNumber int not null default 1
);


create table settings ( 
      schoolId int not null default 0
    , classId int not null default 0
    , personId int not null default 0
    , visibility TEXT NOT NULL default 'class' -- class, school or all
);


insert into databaseVersion values(1);
insert into settings values(0, 0, 0, 'school');

CREATE TABLE school (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , name varchar(256) NOT NULL
);

CREATE TABLE class (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , name varchar(256) NOT NULL
    , school_id INT NOT NULL REFERENCES school(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE person (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , first_name varchar(256) NOT NULL
    , last_name varchar(256) NOT NULL
    , is_admin BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE person_membership (
      person_id INT NOT NULL REFERENCES person(id) ON DELETE CASCADE ON UPDATE CASCADE
    , class_id INT NOT NULL REFERENCES class(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE camera (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , make VARCHAR(256) NOT NULL
    , model VARCHAR(256)
);






create table pendingPictures (
      assetURL text not null
    , pictureId int not null
    , resource text not null default 'image' -- image or deployment_picture
    , done int not null default 0
);
create index pending_done on pendingPictures(done);

create table currentPeople (
      id int NOT null
);


CREATE TABLE deployment (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , deployment_date TIMESTAMP NOT NULL
    , latitude NUMERIC (9,7) NULL
    , longitude NUMERIC (9,7)  NULL
    , notes TEXT NULL
    , short_name VARCHAR (256)
    , camera_height_cm NUMERIC (7,2) NULL
    , camera_azimuth_rad NUMERIC (9,7) NULL
    , camera_elevation_rad NUMERIC (9,7) NULL
    , camera INT NOT NULL REFERENCES camera(id) ON UPDATE CASCADE
    , nominal_mark_time TIMESTAMP NOT NULL
    , actual_mark_time TIMESTAMP NOT NULL
    , names TEXT NOT NULL
);
create index i_dep_id on deployment(id);

CREATE TABLE deployment_picture (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , owner INT NOT NULL REFERENCES person(id) ON UPDATE CASCADE
    , deployment_id INT NOT NULL REFERENCES deployment(id) ON DELETE CASCADE ON UPDATE CASCADE
    , file_name TEXT NOT NULL
    , caption TEXT NULL
    , description TEXT NULL
);
create index i_deployment_picture_id on deployment_picture(id);
CREATE index i_deployment_picture_did on deployment_picture(deployment_id);

CREATE TABLE burst (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , owner INT NOT NULL REFERENCES person(id) ON UPDATE CASCADE
    , burst_date TIMESTAMP not NULL
    , deployment_id INT NOT NULL REFERENCES deployment (id) ON DELETE CASCADE ON UPDATE CASCADE
    , temperature_in_celsius INT NULL
    , moon_phase varchar(32) NULL
);
create index i_burst_id on burst(id);
CREATE index i_burst_did on burst(deployment_id);


CREATE TABLE image (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , owner INT NOT NULL REFERENCES person(id) ON UPDATE CASCADE
    , image_date TIMESTAMP NOT NULL
    , burst_id INT NOT NULL REFERENCES burst(id) ON DELETE CASCADE ON UPDATE CASCADE
    , file_name TEXT NOT NULL
    -- exif data follows
    , width INT NOT NULL
    , height INT NOT NULL
    , shutter_speed NUMERIC (8,6) NULL
    , aperture INT NULL
    , flash BOOLEAN NULL
    , focal_length_mm NUMERIC (5, 2)

);
create index i_image_id on image(id);
CREATE index i_image_bid on image(burst_id);


CREATE TABLE tag (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , owner INT NOT NULL REFERENCES person(id) ON UPDATE CASCADE
    , tag_name VARCHAR(256) NOT NULL
    , image_id INT NOT NULL REFERENCES image(id) ON DELETE CASCADE ON UPDATE CASCADE
    , x INT NOT NULL 
    , y INT NOT NULL
    , deployment_id INT NOT NULL REFERENCES deployment (id) ON DELETE CASCADE ON UPDATE CASCADE

);
create index i_tag_id on tag(id);
CREATE index i_tag_iid on tag(image_id);
CREATE index i_tag_did on tag(deployment_id);





