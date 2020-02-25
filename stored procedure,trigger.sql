--Girilen y�llar aras�nda ve girilen hayvan t�r�ne en �ok verilen ilac�n ismini , �retici firmas�n� ve ka� kez verildi�ini sorgulayan SELECT SP
IF OBJECT_ID('dbo.spLiderUfirma') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spLiderUfirma
	END
GO

CREATE PROCEDURE spLiderUfirma(@baslagicT  AS DATE ,@bitisT AS DATE,@tur AS VARCHAR(50))
AS
	SELECT TOP 1 IC.ADI AS IlacIsmi, UF.AD AS UreticiFirma,COUNT(*) AS VerilmeSay�s�
	 FROM vwIlacDetay ID INNER JOIN tblRecete R ON ID.ReceteID=R.ID
					     INNER JOIN Icerir I ON R.ID=I.ReceteID
					     INNER JOIN tblIlac IC ON I.IlacID=IC.ID
					     INNER JOIN tblUreticiFirma UF ON IC.UfirmaID=UF.ID
	WHERE ID.Hasta_Turu=@tur AND R.GecerlilikSuresi BETWEEN @baslagicT AND @bitisT
	GROUP BY IC.ADI,UF.AD
	ORDER BY COUNT(*) DESC

exec spLiderUfirma '2017-01-01', '2017-12-30','Kedi' 

GO


-- INSERT SP, UPDATE SP ve DELETE SP i�lemlerindeki loglar� tutmak ve de�i�en verileri g�stermek i�in
IF OBJECT_ID('dbo.etkenMaddeTablosuLoglari') IS NOT NULL
	BEGIN
		DROP TABLE dbo.etkenMaddeTablosuLoglari
	END
GO

CREATE TABLE etkenMaddeTablosuLoglari
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	tarih DATETIME,
	islem VARCHAR(10),
	yeni_eMadde VARCHAR(20),
	yeni_yanEtki VARCHAR(50),
	eski_eMadde  VARCHAR(20),
	eski_yanEtki VARCHAR(50)
)
GO

--Trigger'da kullanaca��m�z ve etken maddesi tablosuna ekleme yapt���m�z baz� i�lemler
IF COL_LENGTH('tblEtkenMaddesi','OlusturulmaTarihi') IS NOT NULL
	ALTER TABLE tblEtkenMaddesi DROP COLUMN OlustrulmaTarihi
GO
ALTER TABLE tblEtkenMaddesi ADD OlusturulmaTarihi DATETIME

GO
IF COL_LENGTH('tblEtkenMaddesi','DegistirilmeTarihi') IS NOT NULL
	ALTER TABLE tblEtkenMaddesi DROP COLUMN DegistirilmeTarihi
GO
ALTER TABLE tblEtkenMaddesi ADD DegistirilmeTarihi DATETIME

GO
IF OBJECT_ID('dbo.tblSilinmisEtkenMaddeler') IS NOT NULL
	BEGIN
		DROP TABLE dbo.tblSilinmisEtkenMaddeler
	END
GO
CREATE TABLE tblSilinmisEtkenMaddeler
(
	ID INT PRIMARY KEY,
	ADI VARCHAR(20),
	YanEtkisi VARCHAR(50),
	OlusturulmaTarihi DATETIME,
	DegistirilmeTarihi DATETIME,
	SilinmeTarihi DATETIME
)
GO

--SP ile sildi�imiz Etken madde i�in Trigger delete
IF OBJECT_ID('dbo.trgEtkenMaddeSil','TR') IS NOT NULL
	BEGIN
		DROP TRIGGER dbo.trgEtkenMaddeSil
	END
GO
CREATE TRIGGER trgEtkenMaddeSil ON tblEtkenMaddesi AFTER DELETE AS
	--sililenen kay�tlar yede�e al�n�yor
	INSERT INTO tblSilinmisEtkenMaddeler SELECT * , GETDATE() FROM deleted

GO

--SP ile g�ncelledi�imiz Etken madde i�in Trigger update
IF OBJECT_ID('dbo.trgEtkenMaddeGuncelle','TR') IS NOT NULL
	BEGIN
		DROP TRIGGER dbo.trgEtkenMaddeGuncelle
	END
GO
CREATE TRIGGER trgEtkenMaddeGuncelle ON tblEtkenMaddesi AFTER UPDATE AS
	DECLARE @edID INT  --SP de g�ncellenen etken madde sadece bir tane kayd�n g�ncellendi�ini garanti etti�i i�in de�i�ken
	SELECT @edID = ID FROM inserted         -- olarak tutmak yeterli olucakt�r.
	
	IF UPDATE(ID)
		BEGIN
			RAISERROR(' Etken Madde ID G�ncellenemez! G�ncelleme i�lemi iptal edildi',16,1)
			ROLLBACK
		END
	ELSE
		UPDATE tblEtkenMaddesi SET DegistirilmeTarihi=GETDATE() WHERE ID=@edID

GO

--SP ile ekledi�imiz etken madde i�in Trigger Insert
IF OBJECT_ID('dbo.trgEtkenMaddeEkle','TR') IS NOT NULL
	BEGIN
		DROP TRIGGER dbo.trgEtkenMaddeEkle
	END
GO
CREATE TRIGGER trgEtkenMaddeEkle ON tblEtkenMaddesi AFTER INSERT AS
	DECLARE @edID INT
	SELECT @edID = ID FROM inserted

	ALTER TABLE tblEtkenMaddesi DISABLE TRIGGER trgEtkenMaddeGuncelle
	UPDATE tblEtkenMaddesi SET OlusturulmaTarihi = GETDATE() WHERE ID=@edID
	ALTER TABLE tblEtkenMaddesi ENABLE TRIGGER trgEtkenMaddeGuncelle

GO


--Yeni bir etken madde ve yan etkisini eklemek i�in verilen parametreleri etken madde tablosuna kaydeden INSERT SP
IF OBJECT_ID('dbo.spEtkenMaddeEkle') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spEtkenMaddeEkle
	END
GO

CREATE PROCEDURE spEtkenMaddeEkle(@etkenMadde AS VARCHAR(20),@yanEtki AS VARCHAR(50))
AS
SET NOCOUNT ON
	INSERT INTO tblEtkenMaddesi 
		OUTPUT GETDATE(),'INSERT',INSERTED.ADI,INSERTED.YanEtkisi,null,null INTO etkenMaddeTablosuLoglari
	VALUES(@etkenMadde,@yanEtki,null,null)
SET NOCOUNT OFF

GO

EXEC spEtkenMaddeEkle 'EBRANTIL', 'Deride bozukluk gibi alerjik reaksiyonlar'
GO
SELECT * FROM etkenMaddeTablosuLoglari
SELECT TOP 2 * FROM tblEtkenMaddesi ORDER BY ID DESC

GO


--Verilen parametredeki etken madde kayd�n� verilen bilgilerle g�ncelleyen UPDATE SP
IF OBJECT_ID('dbo.spEtkenMaddeGuncelle') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spEtkenMaddeGuncelle
	END
GO

CREATE PROCEDURE spEtkenMaddeGuncelle(@eskiEmadde AS VARCHAR(20)=NULL,@ID AS INT,@yeniEmadde AS VARCHAR(20),@yeniYanEtki AS VARCHAR(50))
AS
SET NOCOUNT ON
	IF @eskiEmadde IS NULL AND @ID IS NULL
		PRINT 'G�ncellenecek kayd�n bilgileri girilmedi�i i�in g�ncelleme yap�lamam��t�r.'
	ELSE
		UPDATE tblEtkenMaddesi
		SET ADI=@yeniEmadde,YanEtkisi=@yeniYanEtki
		OUTPUT GETDATE(),'UPDATE',INSERTED.ADI,INSERTED.YanEtkisi,DELETED.ADI,DELETED.YanEtkisi INTO etkenMaddeTablosuLoglari
		WHERE ID=ISNULL(@ID,ID) AND ADI=ISNULL(@eskiEmadde,ADI)
SET NOCOUNT OFF

GO

--Parametreler i�in farkl� g�sterimleri
EXEC spEtkenMaddeGuncelle NULL,NULL,'G�ncellenmis E Madde','G�ncellenmis Yan Etki'
EXEC spEtkenMaddeGuncelle NULL,'19','G�ncellenmis E Madde','G�ncellenmis Yan Etki'
EXEC spEtkenMaddeGuncelle 'G�ncellenmis E Madde','19','G�ncellenmis E2','G�ncellenmis Yan Etki2'

GO

SELECT * FROM etkenMaddeTablosuLoglari
SELECT TOP 2 * FROM tblEtkenMaddesi ORDER BY ID DESC

GO

--Verilen parametredeki Etken madde kayd�n� silen DELETE SP
IF OBJECT_ID('dbo.spEtkenMaddeSil') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spEtkenMaddeSil
	END
GO

CREATE PROCEDURE spEtkenMaddeSil(@etkenMadde AS VARCHAR(20)=NULL,@yanEtki AS VARCHAR(50)=NULL,@ID AS INT=NULL)
AS
SET NOCOUNT ON
	IF @etkenMadde IS NULL AND @yanEtki IS NULL AND @ID IS NULL
		PRINT 'Paremetre girilmedi�i i�in silme i�lemi yap�lamad�.'
	ELSE IF @yanEtki IS NULL AND @etkenMadde IS NOT NULL AND @ID IS NULL
		PRINT 'Yetersiz parametre girildi�i i�in silme i�lemi yap�lamad�'
	ELSE
		DELETE FROM tblEtkenMaddesi
			OUTPUT GETDATE(),'DELETE',null,null,DELETED.ADI,DELETED.YanEtkisi INTO etkenMaddeTablosuLoglari
	    WHERE ADI=ISNULL(@etkenMadde,ADI) AND YanEtkisi=ISNULL(@yanEtki,YanEtkisi) AND ID=ISNULL(@ID,ID)
SET NOCOUNT OFF

GO

--Parametreler i�in farkl� g�sterimler
--UPDATE SP de g�ncellenen son kayda g�re silme yap�lm��t�r
EXEC spEtkenMaddeSil
EXEC spEtkenMaddeSil 'G�ncellenmis Yan Etki2'
EXEC spEtkenMaddeSil NULL ,NULL ,'19'
EXEC spEtkenMaddeSil 'G�ncellenmis E2' ,'G�ncellenmis Yan Etki2' ,'19'

GO

SELECT * FROM etkenMaddeTablosuLoglari
SELECT * FROM tblSilinmisEtkenMaddeler

GO


--Ameliyat �cretlerinde parametre olarak verilen bir de�erin alt�ndaki ve �s�t�ndeki ameliyat fiyatlar� i�in verilen oranlarda art�� yapan CURSOR SP
--�rne�in 2000 liran�n alt�ndaki �cretler i�in %10 �st�ndekileri i�in %5 art�� sa�las�n
IF OBJECT_ID('dbo.spAmeliyatZam') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spAmeliyatZam
	END
GO
CREATE PROCEDURE spAmeliyatZam(@deger AS INT,@oran1 AS INT,@oran2 AS INT)
AS
SET NOCOUNT ON
	DECLARE @ucret MONEY

	DECLARE crAmeliyatZam CURSOR
	FOR SELECT Ucret FROM tblAmeliyat
	FOR UPDATE OF Ucret

	OPEN crAmeliyatZam
	FETCH NEXT FROM crAmeliyatZam INTO @ucret
	WHILE @@FETCH_STATUS=0
	BEGIN
		IF @ucret<@deger
			UPDATE tblAmeliyat SET Ucret=(Ucret+(Ucret*@oran1/100)) WHERE CURRENT OF crAmeliyatZam
		ELSE
			UPDATE tblAmeliyat SET Ucret=(Ucret+(Ucret*@oran2/100)) WHERE CURRENT OF crAmeliyatZam
		FETCH NEXT FROM crAmeliyatZam INTO @ucret
	END
	CLOSE crAmeliyatZam
	DEALLOCATE crAmeliyatZam
SET NOCOUNT OFF

GO

SELECT TOP 3 * FROM tblAmeliyat
GO
EXEC spAmeliyatZam '2000' ,'10' ,'5'
GO
SELECT TOP 3 * FROM tblAmeliyat

GO


--�smi verilen ilac� ve o ilac�n �retici firmas�n�, etken maddesini ilgili tablolardan silen DELETE SP
--Silinme i�lemleri s�ras�nda hata ile ka��la��p silinmesi gereken kay�tlar�n hepsi silinmedi�i takdirde silinenleri geri almak i�in
--transaction management ile kontrol edilmi�tir.
IF OBJECT_ID('dbo.spIlacSil') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spIlacSil
	END
GO

CREATE PROCEDURE spIlacSil(@ilacAdi AS VARCHAR(30))
AS
SET NOCOUNT ON
	DECLARE @tranCounter INT=@@TRANCOUNT
	DECLARE @ureticiID INT --�retici firman�n ID sini tutup silmek i�in
	DECLARE @eMaddeID INT --Etkin madde ID sini tutup silmek i�in

	-- daha �nceden a��lm�� tran varsa onlar� kaybetmemek i�in kay�t noktas�
	IF @tranCounter>0
		SAVE TRANSACTION sp_IlacSil_kayit_noktasi

	BEGIN TRANSACTION

	BEGIN TRY 
		SELECT @ureticiID = I.UfirmaID , @eMaddeID=I.EmaddeID FROM tblIlac I WHERE I.ADI=@ilacAdi
		DELETE FROM tblIlac WHERE ADI=@ilacAdi

		DELETE FROM tblUreticiFirma WHERE ID=@ureticiID

		DELETE FROM tblEtkenMaddesi WHERE ID=@eMaddeID

		COMMIT
	END TRY
	BEGIN CATCH
	-- Tek transantion bu ise yada olu�an hata i�in komple geri almaktan ba�ka �are yoksa t�m i�lemleri geri al
		IF @tranCounter=0 OR XACT_STATE()=-1  		
			ROLLBACK TRANSACTION
		ELSE
			BEGIN
				ROLLBACK TRANSACTION sp_IlacSil_kayit_noktasi 
				COMMIT --Kay�t noktas�na kadar olan i�lemleri geri al�p ,A�t���m�z tran� kapatt�k
			END    
		DECLARE @errorMessage NVARCHAR(4000) =ERROR_MESSAGE()
		DECLARE @errorSeverity INT =ERROR_SEVERITY()
		DECLARE @errorState INT =ERROR_STATE()
		RAISERROR(@errorMessage,@errorSeverity,@errorState)
	END CATCH
SET NOCOUNT OFF

GO

--Foreign key'ler cascade olmad��� i�in foreign key hatas� al�naca��ndan di�er tablodaki kay�tlar transaction sayesinde silinmeyecektir.
EXEC spIlacSil 'V�LFLOKS'

GO


--Verilen ilac� �retici firmas�n�n� ve etken maddesini ilgili tablolara ekleyen INSERT SP
--Yukardaki verilerin eklenmesi s�ras�nda herhangi birinin eklenmesi s�ras�nda bir hata ile kar��la��p eklenemedi�i takdirde 
--eklenenleri geri almak i�in transaction management ile kontrol edilmesi
IF OBJECT_ID('dbo.spIlacEkle') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spIlacEkle
	END
GO

CREATE PROCEDURE spIlacEkle(@ilacAdi AS VARCHAR(30),@ureticiFirma AS VARCHAR(100),@etkenMadde AS VARCHAR(20),@yanEtki AS VARCHAR(50))
AS
SET NOCOUNT ON
	DECLARE @tranCounter INT=@@TRANCOUNT
	DECLARE @ureticiID INT --�retici firman�n ID sini tutup referans vermek i�in
	DECLARE @eMaddeID INT --Etkin madde ID sini tutup referans vermek i�in

	-- daha �nceden a��lm�� tran varsa onlar� kaybetmemek i�in kay�t noktas�
	IF @tranCounter>0
		SAVE TRANSACTION sp_IlacEkle_kayit_noktasi

	BEGIN TRANSACTION

	BEGIN TRY 
		INSERT INTO tblUreticiFirma VALUES (@ureticiFirma)
		SELECT @ureticiID = U.ID  FROM tblUreticiFirma U WHERE U.AD=@ureticiFirma
		
		INSERT INTO tblEtkenMaddesi VALUES (@etkenMadde,@yanEtki,null,null)
		SELECT @eMaddeID = E.ID FROM tblEtkenMaddesi E WHERE E.ADI=@etkenMadde AND E.YanEtkisi=@yanEtki

		INSERT INTO tblIlac VALUES (@ilacAdi,@ureticiID,@eMaddeID)

		COMMIT
	END TRY
	BEGIN CATCH
	-- Tek transantion bu ise yada olu�an hata i�in komple geri almaktan ba�ka �are yoksa t�m i�lemleri geri al
		IF @tranCounter=0 OR XACT_STATE()=-1  		
			ROLLBACK TRANSACTION
		ELSE
			BEGIN
				ROLLBACK TRANSACTION sp_IlacEkle_kayit_noktasi 
				COMMIT --Kay�t noktas�na kadar olan i�lemleri geri al�p ,A�t���m�z tran� kapatt�k
			END    
		DECLARE @errorMessage NVARCHAR(4000) =ERROR_MESSAGE()
		DECLARE @errorSeverity INT =ERROR_SEVERITY()
		DECLARE @errorState INT =ERROR_STATE()
		RAISERROR(@errorMessage,@errorSeverity,@errorState)
	END CATCH
SET NOCOUNT OFF

GO

SELECT TOP 2 * FROM tblIlac ORDER BY ID DESC
EXEC spIlacEkle 'Yeni Ilac' ,'Yeni Uretici Firma','Yeni Etken Madde','Yeni Yan Etki'
-- eklenenleri g�sterim i�in
SELECT TOP 2 * FROM tblIlac ORDER BY ID DESC
SELECT TOP 2 * FROM tblUreticiFirma ORDER BY ID DESC
SELECT TOP 2 * FROM tblEtkenMaddesi ORDER BY ID DESC


