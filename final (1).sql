
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_AlbumID_Lowercase')
    DROP TRIGGER trg_AlbumID_Lowercase;
GO

-- Drop procedures
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'FindAlbumbyID')
    DROP PROCEDURE FindAlbumbyID;
GO

-- Drop views
IF EXISTS (SELECT * FROM sys.views WHERE name = 'ShowAllTracks')
    DROP VIEW ShowAllTracks;
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'ShowTrackCount')
    DROP VIEW ShowTrackCount;
GO

-- Drop indexes (must drop before tables)
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_Album_ArtistID')
    DROP INDEX ix_Album_ArtistID ON Album;
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_Album_GenreID')
    DROP INDEX ix_Album_GenreID ON Album;
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_Tracks_AlbumID')
    DROP INDEX ix_Tracks_AlbumID ON Tracks;
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_PlaylistTrack_TrackID')
    DROP INDEX ix_PlaylistTrack_TrackID ON PlaylistTrack;
GO

-- Drop tables (in reverse FK order)
IF OBJECT_ID('PlaylistTrack', 'U') IS NOT NULL DROP TABLE PlaylistTrack;
IF OBJECT_ID('Tracks', 'U') IS NOT NULL DROP TABLE Tracks;
IF OBJECT_ID('Playlist', 'U') IS NOT NULL DROP TABLE Playlist;
IF OBJECT_ID('Album', 'U') IS NOT NULL DROP TABLE Album;
IF OBJECT_ID('Artist', 'U') IS NOT NULL DROP TABLE Artist;
IF OBJECT_ID('Genre', 'U') IS NOT NULL DROP TABLE Genre;
GO

-- Drop user and login
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'MusicLover')
    DROP USER MusicLover;
GO

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'MusicLover')
    DROP LOGIN MusicLover;
GO

-- Drop and recreate database
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'MusicLibrary')
BEGIN
    ALTER DATABASE MusicLibrary SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MusicLibrary;
END
GO

CREATE DATABASE MusicLibrary;
GO

USE MusicLibrary;
GO


CREATE TABLE Genre (
    GenreID    int           NOT NULL  PRIMARY KEY,
    GenreName  varchar(50)   NOT NULL
);
GO

-- Artist Table
CREATE TABLE Artist (
    ArtistID    int           NOT NULL  PRIMARY KEY  IDENTITY(1,1),
    ArtistName  varchar(100)  NOT NULL,
    Country     varchar(60)   NULL
);
GO


CREATE TABLE Album (
    AlbumID       char(5)        NOT NULL  PRIMARY KEY,
    AlbumName     varchar(150)   NOT NULL,
    DateReleased  date           NULL,
    Price         smallmoney     NOT NULL,
    ArtistID      int            NOT NULL,
    GenreID       int            NOT NULL,

    CONSTRAINT fk_Album_Artist  FOREIGN KEY (ArtistID)  REFERENCES Artist(ArtistID),
    CONSTRAINT fk_Album_Genre   FOREIGN KEY (GenreID)   REFERENCES Genre(GenreID),

    
    CONSTRAINT chk_AlbumID_Len  CHECK (LEN(AlbumID) = 5),

    
    CONSTRAINT chk_Price_Pos    CHECK (Price > 0)
);
GO


CREATE TABLE Tracks (
    TrackID    int           NOT NULL  PRIMARY KEY  IDENTITY(1,1),
    TrackName  varchar(200)  NOT NULL,
    Duration   time          NULL,       
    AlbumID    char(5)       NOT NULL,

    CONSTRAINT fk_Tracks_Album  FOREIGN KEY (AlbumID)  REFERENCES Album(AlbumID)
);
GO


CREATE TABLE Playlist (
    PlaylistID    int           NOT NULL  PRIMARY KEY  IDENTITY(1,1),
    
    PlayListName  varchar(100)  NULL  DEFAULT 'NewPlayList'
);
GO


CREATE TABLE PlaylistTrack (
    PlaylistID  int  NOT NULL,
    TrackID     int  NOT NULL,

    CONSTRAINT pk_PlaylistTrack  PRIMARY KEY (PlaylistID, TrackID),
    CONSTRAINT fk_PLT_Playlist   FOREIGN KEY (PlaylistID)  REFERENCES Playlist(PlaylistID),
    CONSTRAINT fk_PLT_Track      FOREIGN KEY (TrackID)     REFERENCES Tracks(TrackID)
);
GO


CREATE NONCLUSTERED INDEX ix_Album_ArtistID
    ON Album (ArtistID);
GO


CREATE NONCLUSTERED INDEX ix_Album_GenreID
    ON Album (GenreID);
GO


CREATE NONCLUSTERED INDEX ix_Tracks_AlbumID
    ON Tracks (AlbumID);
GO


CREATE NONCLUSTERED INDEX ix_PlaylistTrack_TrackID
    ON PlaylistTrack (TrackID);
GO

-- ============================================================
-- PART A.3: Insert Data
-- ============================================================

-- Genres (at least 2; Pop will have multiple albums)
INSERT INTO Genre (GenreID, GenreName) VALUES
    (1, 'Pop'),
    (2, 'Rock');
GO

-- Artists (at least 2)
INSERT INTO Artist (ArtistName, Country) VALUES
    ('Taylor Swift', 'United States'),    -- ArtistID = 1
    ('The Beatles',  'United Kingdom');   -- ArtistID = 2
GO

-- Albums (at least 3; Taylor Swift has 2 albums; Pop genre has 2 albums)
INSERT INTO Album (AlbumID, AlbumName, DateReleased, Price, ArtistID, GenreID) VALUES
    ('alb01', '1989',           '2014-10-27', 9.99,  1, 1),   -- Taylor Swift, Pop
    ('alb02', 'Lover',          '2019-08-23', 9.99,  1, 1),   -- Taylor Swift, Pop
    ('alb03', 'Abbey Road',     '1969-09-26', 7.99,  2, 2);   -- The Beatles, Rock
GO

-- Tracks (3-4 per album; every album has at least one track)
-- Album alb01 - 1989
INSERT INTO Tracks (TrackName, Duration, AlbumID) VALUES
    ('Welcome to New York',  '00:03:32', 'alb01'),
    ('Blank Space',          '00:03:51', 'alb01'),
    ('Style',                '00:03:51', 'alb01'),
    ('Shake It Off',         '00:03:39', 'alb01');

-- Album alb02 - Lover
INSERT INTO Tracks (TrackName, Duration, AlbumID) VALUES
    ('I Forgot That You Existed', '00:02:53', 'alb02'),
    ('Cruel Summer',              '00:02:58', 'alb02'),
    ('Lover',                     '00:03:41', 'alb02');

-- Album alb03 - Abbey Road
INSERT INTO Tracks (TrackName, Duration, AlbumID) VALUES
    ('Come Together',    '00:04:19', 'alb03'),
    ('Something',        '00:03:02', 'alb03'),
    ('Here Comes the Sun', '00:03:05', 'alb03');
GO

-- Playlist (one playlist with at least 3 tracks from different albums)
INSERT INTO Playlist (PlayListName) VALUES ('My Favorites');
GO

-- PlaylistTrack - add tracks from different albums
-- TrackID 2 = Blank Space (alb01), TrackID 6 = Cruel Summer (alb02), TrackID 8 = Come Together (alb03)
INSERT INTO PlaylistTrack (PlaylistID, TrackID) VALUES
    (1, 2),   -- Blank Space (alb01)
    (1, 6),   -- Cruel Summer (alb02)
    (1, 8);   -- Come Together (alb03)
GO

-- ============================================================
-- PART B.1: View - ShowAllTracks
-- ============================================================
CREATE VIEW ShowAllTracks AS
    SELECT
        a.AlbumName,
        ar.ArtistName,
        g.GenreName,
        t.TrackName,
        a.DateReleased
    FROM Tracks t
        JOIN Album  a  ON t.AlbumID  = a.AlbumID
        JOIN Artist ar ON a.ArtistID = ar.ArtistID
        JOIN Genre  g  ON a.GenreID  = g.GenreID;
GO

-- Test view
SELECT * FROM ShowAllTracks;
GO

-- ============================================================
-- PART B.2: View - ShowTrackCount
-- ============================================================
CREATE VIEW ShowTrackCount AS
    SELECT
        a.AlbumName,
        a.AlbumID,
        COUNT(t.TrackID) AS TrackCount
    FROM Album a
        JOIN Tracks t ON a.AlbumID = t.AlbumID
    GROUP BY a.AlbumName, a.AlbumID;
GO

-- Test view
SELECT * FROM ShowTrackCount;
GO

-- ============================================================
-- PART B.3: Stored Procedure - FindAlbumbyID
-- ============================================================
CREATE PROCEDURE FindAlbumbyID
    @value varchar(10)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Album WHERE AlbumID = @value)
    BEGIN
        SELECT
            a.AlbumName,
            ar.ArtistName,
            g.GenreName,
            a.DateReleased,
            a.Price
        FROM Album a
            JOIN Artist ar ON a.ArtistID = ar.ArtistID
            JOIN Genre  g  ON a.GenreID  = g.GenreID
        WHERE a.AlbumID = @value;

        RETURN 1;
    END
    ELSE
    BEGIN
        PRINT 'Cannot find the album with ID: ' + @value;
        RETURN 0;
    END
END;
GO

-- Test procedure: album that exists
EXEC FindAlbumbyID 'alb01';
GO

-- Test procedure: album that does not exist
EXEC FindAlbumbyID 'alb99';
GO

-- ============================================================
-- PART B.4: AFTER INSERT Trigger - enforce lowercase AlbumID
-- ============================================================
CREATE TRIGGER trg_AlbumID_Lowercase
ON Album
AFTER INSERT
AS
BEGIN
    -- Update any newly inserted rows where AlbumID is not all lowercase
    UPDATE Album
    SET AlbumID = LOWER(inserted.AlbumID)
    FROM Album
        JOIN inserted ON Album.AlbumID = inserted.AlbumID
    WHERE Album.AlbumID <> LOWER(inserted.AlbumID);
END;
GO

-- Test trigger: insert with uppercase AlbumID (should be converted to 'alb04')
INSERT INTO Album (AlbumID, AlbumName, DateReleased, Price, ArtistID, GenreID)
    VALUES ('ALB04', 'Help!', '1965-08-06', 7.99, 2, 2);
GO

-- Verify trigger worked
SELECT AlbumID, AlbumName FROM Album WHERE AlbumName = 'Help!';
GO

-- ============================================================
-- PART A - Check Constraint Verification Tests (expect errors)
-- ============================================================

-- Error 1: AlbumID not 5 characters (should fail chk_AlbumID_Len)
INSERT INTO Album (AlbumID, AlbumName, DateReleased, Price, ArtistID, GenreID)
    VALUES ('ab', 'Bad ID Album', '2020-01-01', 9.99, 1, 1);
GO

-- Error 2: Price = 0 (should fail chk_Price_Pos)
INSERT INTO Album (AlbumID, AlbumName, DateReleased, Price, ArtistID, GenreID)
    VALUES ('alb05', 'Free Album', '2020-01-01', 0, 1, 1);
GO

-- Error 3: AlbumID 6 characters (should fail chk_AlbumID_Len)
INSERT INTO Album (AlbumID, AlbumName, DateReleased, Price, ArtistID, GenreID)
    VALUES ('alb999', 'Too Long ID', '2020-01-01', 5.99, 1, 1);
GO

-- Trigger error test: insert uppercase AlbumID that already exists after trigger fires
-- (Trigger will try to update, but if a duplicate key results, SQL will error)
-- This is the expected trigger error test demonstrating the trigger fires
INSERT INTO Album (AlbumID, AlbumName, DateReleased, Price, ArtistID, GenreID)
    VALUES ('ALB01', 'Duplicate Test', '2020-01-01', 9.99, 1, 1);
GO

-- ============================================================
-- PART C: Create Login, User, and Permissions
-- ============================================================

USE master;
GO

-- Part C.1: Create login (CHECK_POLICY OFF so songs123 password works)
CREATE LOGIN MusicLover
    WITH PASSWORD = 'songs123',
         CHECK_POLICY = OFF;
GO

USE MusicLibrary;
GO

-- Create database user mapped to the login
CREATE USER MusicLover FOR LOGIN MusicLover;
GO

-- Part C.2: Grant SELECT-only permissions using db_datareader fixed database role
-- db_datareader allows SELECT on all tables; no INSERT/UPDATE/DELETE
EXEC sp_addrolemember 'db_datareader', 'MusicLover';
GO

-- ============================================================
-- END OF SCRIPT
-- ============================================================