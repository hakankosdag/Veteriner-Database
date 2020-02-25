IF DB_ID('veteriner') IS NOT NULL
	BEGIN
		ALTER DATABASE [veteriner] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		USE master
		DROP DATABASE  veteriner
	END
GO

CREATE DATABASE veteriner
	ON PRIMARY (
					NAME = 'veterinerdb',
					FILENAME = 'c:\database\veteriner_db.mdf',
					SIZE = 5MB,
					MAXSIZE = 100MB,
					FILEGROWTH = 2MB
				)
	LOG ON		(
					NAME = 'veterinerdb_log',
					FILENAME = 'c:\database\veteriner_log.ldf',
					SIZE = 2MB,
					MAXSIZE = 50MB,
					FILEGROWTH = 1MB
				)
GO

USE veteriner

-- Veteriner bilgilerini içerir
CREATE TABLE tblVeteriner
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	AD VARCHAR(50) NOT NULL,
	Tel CHAR(10) CONSTRAINT chktblVeterinerTel CHECK (Tel LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	Mail VARCHAR(60)
			CONSTRAINT unqtblVeterinerMail UNIQUE
			CONSTRAINT chktblVeterinerMail CHECK(Mail LIKE '%@%.%')
			CONSTRAINT notnulltblVeterinerMail NOT NULL,
)
GO

-- Hasta sahibinin bilgilerini içerir
CREATE TABLE tblSahip
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	TCNO CHAR(11) UNIQUE NOT NULL,
	AD VARCHAR(50) NOT NULL,
	SOYAD VARCHAR(50) NOT NULL,
	Tel CHAR(10) CONSTRAINT chktblSahipTel CHECK (Tel LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	Mail VARCHAR(60)
			CONSTRAINT unqtblSahipMail UNIQUE
			CONSTRAINT chktblSahipMail CHECK(Mail LIKE '%@%.%')
			CONSTRAINT notnulltblSahipMail NOT NULL,
	ADRES VARCHAR(300) 
)
GO

-- Hastalýk bilgilerini içerir
CREATE TABLE tblHastalik
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	ADI VARCHAR(50) NOT NULL ,
)
GO

-- Hasta türünü içerir
CREATE TABLE tblHastaTuru
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	ADI VARCHAR(50) NOT NULL
)
GO

-- hastanýn cins bilgisini içerir
CREATE TABLE tblCins
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	ADI VARCHAR(50) NOT NULL,
	HtID INT FOREIGN KEY REFERENCES tblHastaTuru(ID) NOT NULL
)
GO

-- Müþade türünü içerir
CREATE TABLE tblMusadeTuru
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	Turu VARCHAR(50)
)
GO

-- Müþade bilgilerini içerir
CREATE TABLE tblMusade
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	BaslangicTarihi DATE DEFAULT GETDATE(),
	BitisTarihi DATE,
	Suresi AS DATEDIFF(hh,BaslangicTarihi,BitisTarihi),
	MtID INT FOREIGN KEY REFERENCES tblMusadeTuru(ID) NOT NULL
)
GO

-- Ameliyat bilgilerini içerir
CREATE TABLE tblAmeliyat
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	ADI VARCHAR(50),
	Ucret MONEY,
	VetID INT FOREIGN KEY REFERENCES tblVeteriner(ID) NOT NULL
)
GO

-- Hasta bilgilerini içerir
CREATE TABLE tblHasta
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	Belirti VARCHAR(100),
	DogumTarihi DATE NOT NULL,
	Yas AS DATEDIFF(yy,DogumTarihi,GETDATE()),
	HtID INT FOREIGN KEY REFERENCES tblHastaTuru(ID) NOT NULL,
	MusadeID INT FOREIGN KEY REFERENCES tblMusade(ID) NOT NULL,
	SahipID INT FOREIGN KEY REFERENCES tblSahip(ID) NOT NULL
)
GO

-- HASTA AMELÝYAT OLUR ÝLÝÞKÝSÝ
CREATE TABLE Olur
(
	Tarih DATE,
	AmeliyatID INT FOREIGN KEY REFERENCES tblAmeliyat(ID) NOT NULL,
	HastaID INT FOREIGN KEY REFERENCES tblHasta(ID) NOT NULL,

	CONSTRAINT pktblOlur PRIMARY KEY (AmeliyatID,HastaID)
)
GO

-- Tedavi bilgilerini içerir
CREATE TABLE tblTedavi
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	HTespitTarihi DATE,
	TedaviBaslangici DATE,
	KontrolTarihi DATE,
	Ucret MONEY,
	HastaID INT FOREIGN KEY REFERENCES tblHasta(ID) NOT NULL,
	HastalikID INT FOREIGN KEY REFERENCES tblHastalik(ID) NOT NULL,
	VetID INT FOREIGN KEY REFERENCES tblVeteriner(ID) NOT NULL
)
GO

-- Aþý türünü içerir
CREATE TABLE tblAsiTuru
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	Turu VARCHAR(50)
)
GO

-- Aþý bilgilerini içerir
CREATE TABLE tblAsi
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	AsýTarihi DATE DEFAULT GETDATE(),
	GecerlilikSuresi DATE,
	AsiTuruID INT FOREIGN KEY REFERENCES tblAsiTuru(ID) NOT NULL,
	HastaID INT FOREIGN KEY REFERENCES tblHasta(ID) NOT NULL
)
GO

--Parazit korumanýn uygulanma þeklini içerir
CREATE TABLE tblUygulanmaSekli
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	UygSekli VARCHAR(100)
)
GO

-- Parazit koruma ile ilgili bilgileri içerir
CREATE TABLE tblParazitKoruma
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	YapýlmaTarihi DATE DEFAULT GETDATE(),
	GecerlilikSuresi DATE,
	UsekliID INT FOREIGN KEY REFERENCES tblUygulanmaSekli(ID) NOT NULL,
	HastaID INT FOREIGN KEY REFERENCES tblHasta(ID) NOT NULL
)
GO

-- Parazit korumanýn türünü içerir
CREATE TABLE tblKorumaTuru
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	Turu VARCHAR(50),
	PkorumaID INT FOREIGN KEY REFERENCES tblParazitKoruma(ID) NOT NULL
)
GO

-- Üretici firma bilgileri
 CREATE TABLE tblUreticiFirma
 (
	ID INT IDENTITY(1,1) PRIMARY KEY,
	AD VARCHAR(100) 
 )
 GO

 -- Etken madde bilgisi
 CREATE TABLE tblEtkenMaddesi
 (
	ID INT IDENTITY(1,1) PRIMARY KEY,
	ADI VARCHAR(20),
	YanEtkisi VARCHAR(50)
 )
 GO

 -- Ýlaç bilgilerini içerir
 CREATE TABLE tblIlac
 (
	ID INT IDENTITY(1,1) PRIMARY KEY,
	ADI VARCHAR(30),
	UfirmaID INT FOREIGN KEY REFERENCES tblUreticiFirma(ID) NOT NULL,
	EmaddeID INT FOREIGN KEY REFERENCES tblEtkenMaddesi(ID) NOT NULL 
 )
 GO

 -- Reçete bilgilerini içerir
 CREATE TABLE tblRecete
 (
	ID INT IDENTITY(1,1) PRIMARY KEY,
	Turu VARCHAR(20),
	GecerlilikSuresi DATE,
	VetID INT FOREIGN KEY REFERENCES tblVeteriner(ID) NOT NULL,
	HastaID INT FOREIGN KEY REFERENCES tblHasta(ID) NOT NULL
 )
 GO

 -- Recete Ýlaç iliþki tablosunu içerir
 CREATE TABLE Icerir
 (
	Dozaj VARCHAR(20),
	KulanýmSuesi VARCHAR(30),
	UygulanmaSekli VARCHAR(30),

	IlacID INT FOREIGN KEY REFERENCES tblIlac(ID) NOT NULL,
	ReceteID INT FOREIGN KEY REFERENCES tblRecete(ID) NOT NULL,

	CONSTRAINT pktblIcerir PRIMARY KEY (IlacID,ReceteID)
 )