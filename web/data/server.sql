DROP TABLE IF EXISTS get_expand;
DROP TABLE IF EXISTS get_cascade;
DROP TABLE IF EXISTS tag;
DROP TABLE IF EXISTS image;
DROP TABLE IF EXISTS burst;
DROP TABLE IF EXISTS deployment_picture;
DROP TABLE IF EXISTS deployment;
DROP TABLE IF EXISTS camera;
DROP TABLE IF EXISTS token;
DROP TABLE IF EXISTS person;
DROP TABLE IF EXISTS class;
DROP TABLE IF EXISTS school;

-- added deployment person_id


CREATE TABLE school (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , name varchar(256) NOT NULL
);

INSERT INTO school (name) values ('School 1');
INSERT INTO school (name) values ('School 2');

CREATE TABLE class (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , name varchar(256) NOT NULL
    , school_id INT NOT NULL REFERENCES school(id) ON DELETE CASCADE ON UPDATE CASCADE
);

insert into class (school_id, name) values (1, 'Grade 3');
insert into class (school_id, name) values (1, 'Grade 4');
insert into class (school_id, name) values (1, 'Grade 5');
insert into class (school_id, name) values (1, 'Grade 6');
insert into class (school_id, name) values (2, 'Grade 3');
insert into class (school_id, name) values (2, 'Grade 4');
insert into class (school_id, name) values (2, 'Grade 5');
insert into class (school_id, name) values (2, 'Grade 6');

CREATE TABLE person (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , first_name varchar(256) NOT NULL
    , last_name varchar(256) NOT NULL
    , password char(60) NOT NULL
    , email VARCHAR(256) UNIQUE NOT NULL
    , is_admin BOOLEAN NOT NULL DEFAULT FALSE
    , class_id INT NOT NULL REFERENCES class(id) ON DELETE CASCADE ON UPDATE CASCADE
);
create index i_person_email on person(email);
COMMENT ON TABLE person IS 'A person may be a student or a teacher';
COMMENT ON COLUMN person.password IS 'Password hashed using bcrypt';
COMMENT ON COLUMN person.is_admin IS 'Admins are not limited to any particular school. Admins can create classes, schools, persons, and person_membership';

INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Andy', 'Avalon',  crypt('password', gen_salt('bf', 10)), 'a@example.com', 1);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Betty', 'Belvidere',  crypt('password', gen_salt('bf', 10)), 'b@example.com', 1);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Charlie', 'Chatterbox',  crypt('password', gen_salt('bf', 10)), 'c@example.com', 2);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Darlene', 'Dingleberry',  crypt('password', gen_salt('bf', 10)), 'd@example.com', 2);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Edward', 'Earhart',  crypt('password', gen_salt('bf', 10)), 'e@example.com', 3);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Francis', 'Finnegan',  crypt('password', gen_salt('bf', 10)), 'f@example.com', 3);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Gerald', 'Gamma',  crypt('password', gen_salt('bf', 10)), 'g@example.com', 4);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Harriet', 'Humboldt',  crypt('password', gen_salt('bf', 10)), 'h@example.com', 4);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Inigo', 'Infante',  crypt('password', gen_salt('bf', 10)), 'i@example.com', 5);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Josephine', 'Jufoon',  crypt('password', gen_salt('bf', 10)), 'j@example.com', 5);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Karl', 'Klavet',  crypt('password', gen_salt('bf', 10)), 'k@example.com', 6);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Linda', 'Lang',  crypt('password', gen_salt('bf', 10)), 'l@example.com', 6);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Marty', 'McInerny',  crypt('password', gen_salt('bf', 10)), 'm@example.com', 7);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Nancy', 'Nickleback',  crypt('password', gen_salt('bf', 10)), 'n@example.com', 7);
INSERT INTO PERSON (first_name, last_name, password, email, class_id) values ('Oliver', 'Oolong',  crypt('password', gen_salt('bf', 10)), 'o@example.com', 8);
INSERT INTO PERSON (first_name, last_name, password, email, class_id, is_admin) values ('Admin', 'One',  crypt('password', gen_salt('bf', 10)), 'admin@example.com', 1, true);



CREATE TABLE token (
      token CHAR(32)  UNIQUE PRIMARY KEY NOT NULL
    , person_id INT NOT NULL REFERENCES person(id) ON DELETE CASCADE ON UPDATE CASCADE
    , token_date TIMESTAMP NOT NULL DEFAULT statement_timestamp()
);
COMMENT ON TABLE "token" IS 'When a POST is sent to a person, the email and password are validated and a token is created (if necessary) and then returned.  A logout is performed by sending a delete.';
COMMENT ON COLUMN "token"."token_date" IS 'Tokens should expire at some point in time';  


CREATE TABLE camera (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , make VARCHAR(256) NOT NULL
    , model VARCHAR(256)
);

INSERT INTO camera (make, model) values ('Trap', 'Alpha');
INSERT INTO camera (make, model) values ('Trap', 'Beta');
INSERT INTO camera (make, model) values ('Trap', 'Gamma');


CREATE TABLE deployment (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , owner INT NOT NULL REFERENCES person(id) ON UPDATE CASCADE -- this is for internal use only. Do not use this column
    , person_id INT NOT NULL REFERENCES person(id) ON DELETE CASCADE ON UPDATE CASCADE
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
);
COMMENT ON COLUMN "deployment"."owner" IS 'This column is for internal use only. Do not use this column.';


-- CREATE TABLE deployment_person (
--       deployment_id INT NOT NULL REFERENCES deployment(id) ON DELETE CASCADE ON UPDATE CASCADE
--     , person_id INT NOT NULL REFERENCES person(id) ON DELETE CASCADE ON UPDATE CASCADE
-- );
-- CREATE INDEX i_deployment_person_deployment on deployment_person(deployment_id);

CREATE TABLE deployment_picture (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , owner INT NOT NULL REFERENCES person(id) ON UPDATE CASCADE
    , deployment_id INT NOT NULL REFERENCES deployment(id) ON DELETE CASCADE ON UPDATE CASCADE
    , file_name TEXT NOT NULL
    , caption TEXT NULL
    , description TEXT NULL
);

CREATE TABLE burst (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , owner INT NOT NULL REFERENCES person(id) ON UPDATE CASCADE
    , burst_date TIMESTAMP not NULL
    , deployment_id INT NOT NULL REFERENCES deployment (id) ON DELETE CASCADE ON UPDATE CASCADE
    , temperature_in_celsius INT NULL
    , moon_phase varchar(32) NULL
    , notes TEXT 
);


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

CREATE TABLE tag (
      id SERIAL UNIQUE PRIMARY KEY NOT NULL
    , owner INT NOT NULL REFERENCES person(id) ON UPDATE CASCADE
    , tag_name VARCHAR(256) NOT NULL
    , image_id INT NOT NULL REFERENCES image(id) ON DELETE CASCADE ON UPDATE CASCADE
    , x INT NOT NULL 
    , y INT NOT NULL
    , deployment_id INT NOT NULL REFERENCES deployment (id) ON DELETE CASCADE ON UPDATE CASCADE

);


CREATE TABLE get_cascade (
      parent_table varchar(256) NOT NULL
    , child_table varchar(256) NOT NULL
    , membership_table VARCHAR (256) NULL
);
CREATE index i_get_cascade_parent on get_cascade(parent_table);

INSERT INTO get_cascade values ('school', 'class');
INSERT INTO get_cascade values ('class', 'person');
INSERT INTO get_cascade values ('deployment', 'deployment_picture');
INSERT INTO get_cascade values ('deployment', 'burst');
INSERT INTO get_cascade values ('burst', 'image');
INSERT INTO get_cascade values ('image', 'tag');

CREATE TABLE get_expand (
      parent_table varchar(256) NOT NULL
    , child_table varchar(256) NOT NULL
);
CREATE index i_get_expand_parent on get_expand(parent_table);

INSERT INTO get_expand values ('deployment', 'person');



-- temp deployments

insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (1, 1, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (1, 1, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (2, 2, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (2, 2, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (3, 3, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (3, 3, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (4, 4, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (4, 4, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (5, 5, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (5, 5, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (6, 6, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (6, 6, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (7, 7, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (7, 7, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (8, 8, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (8, 8, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (9, 9, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (9, 9, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (10, 10, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (10, 10, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (11, 11, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (11, 11, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (12, 12, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (12, 12, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (13, 13, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (13, 13, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (14, 14, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (14, 14, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (15, 15, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());
insert into deployment(owner, person_id, deployment_date, camera, nominal_mark_time, actual_mark_time) values (15, 15, statement_timestamp(), 1, statement_timestamp(), statement_timestamp());



