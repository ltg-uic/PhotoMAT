
create table trapDatabaseVersion (
    versionNumber int not null default 1
);


create table trapSettings ( 
      schoolId int not null default 0
    , classId int not null default 0
);

create table trapPendingPictures (
      assetURL text not null
    , pictureId int not null
    , resource text not null default 'image' -- image or deployment_picture
    , done int not null default 0
);

create index pending_done on trapPendingPictures(done);

    