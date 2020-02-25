--Girilen yýllar arasýnda ve girilen hayvan türüne en çok verilen ilacýn ismini , üretici firmasýný ve kaç kez verildiðini sorgulayan SELECT SP
IF OBJECT_ID('dbo.spLiderUfirma') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spLiderUfirma
	END
GO

CREATE PROCEDURE spLiderUfirma(@baslagicT  AS DATE ,@bitisT AS DATE,@tur AS VARCHAR(50))
AS
	SELECT TOP 1 IC.ADI AS IlacIsmi, UF.AD AS UreticiFirma,COUNT(*) AS VerilmeSayýsý
	 FROM vwIlacDetay ID INNER JOIN tblRecete R ON ID.ReceteID=R.ID
					     INNER JOIN Icerir I ON R.ID=I.ReceteID
					     INNER JOIN tblIlac IC ON I.IlacID=IC.ID
					     INNER JOIN tblUreticiFirma UF ON IC.UfirmaID=UF.ID
	WHERE ID.Hasta_Turu=@tur AND R.GecerlilikSuresi BETWEEN @baslagicT AND @bitisT
	GROUP BY IC.ADI,UF.AD
	ORDER BY COUNT(*) DESC

exec spLiderUfirma '2017-01-01', '2017-12-30','Kedi' 

GO


-- INSERT SP, UPDATE SP ve DELETE SP iþlemlerindeki loglarý tutmak ve deðiþen verileri göstermek için
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

--Trigger'da kullanacaðýmýz ve etken maddesi tablosuna ekleme yaptýðýmýz bazý iþlemler
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

--SP ile sildiðimiz Etken madde için Trigger delete
IF OBJECT_ID('dbo.trgEtkenMaddeSil','TR') IS NOT NULL
	BEGIN
		DROP TRIGGER dbo.trgEtkenMaddeSil
	END
GO
CREATE TRIGGER trgEtkenMaddeSil ON tblEtkenMaddesi AFTER DELETE AS
	--sililenen kayýtlar yedeðe alýnýyor
	INSERT INTO tblSilinmisEtkenMaddeler SELECT * , GETDATE() FROM deleted

GO

--SP ile güncellediðimiz Etken madde için Trigger update
IF OBJECT_ID('dbo.trgEtkenMaddeGuncelle','TR') IS NOT NULL
	BEGIN
		DROP TRIGGER dbo.trgEtkenMaddeGuncelle
	END
GO
CREATE TRIGGER trgEtkenMaddeGuncelle ON tblEtkenMaddesi AFTER UPDATE AS
	DECLARE @edID INT  --SP de güncellenen etken madde sadece bir tane kaydýn güncellendiðini garanti ettiði için deðiþken
	SELECT @edID = ID FROM inserted         -- olarak tutmak yeterli olucaktýr.
	
	IF UPDATE(ID)
		BEGIN
			RAISERROR(' Etken Madde ID Güncellenemez! Güncelleme iþlemi iptal edildi',16,1)
			ROLLBACK
		END
	ELSE
		UPDATE tblEtkenMaddesi SET DegistirilmeTarihi=GETDATE() WHERE ID=@edID

GO

--SP ile eklediðimiz etken madde için Trigger Insert
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


--Yeni bir etken madde ve yan etkisini eklemek için verilen parametreleri etken madde tablosuna kaydeden INSERT SP
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


--Verilen parametredeki etken madde kaydýný verilen bilgilerle güncelleyen UPDATE SP
IF OBJECT_ID('dbo.spEtkenMaddeGuncelle') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spEtkenMaddeGuncelle
	END
GO

CREATE PROCEDURE spEtkenMaddeGuncelle(@eskiEmadde AS VARCHAR(20)=NULL,@ID AS INT,@yeniEmadde AS VARCHAR(20),@yeniYanEtki AS VARCHAR(50))
AS
SET NOCOUNT ON
	IF @eskiEmadde IS NULL AND @ID IS NULL
		PRINT 'Güncellenecek kaydýn bilgileri girilmediði için güncelleme yapýlamamýþtýr.'
	ELSE
		UPDATE tblEtkenMaddesi
		SET ADI=@yeniEmadde,YanEtkisi=@yeniYanEtki
		OUTPUT GETDATE(),'UPDATE',INSERTED.ADI,INSERTED.YanEtkisi,DELETED.ADI,DELETED.YanEtkisi INTO etkenMaddeTablosuLoglari
		WHERE ID=ISNULL(@ID,ID) AND ADI=ISNULL(@eskiEmadde,ADI)
SET NOCOUNT OFF

GO

--Parametreler için farklý gösterimleri
EXEC spEtkenMaddeGuncelle NULL,NULL,'Güncellenmis E Madde','Güncellenmis Yan Etki'
EXEC spEtkenMaddeGuncelle NULL,'19','Güncellenmis E Madde','Güncellenmis Yan Etki'
EXEC spEtkenMaddeGuncelle 'Güncellenmis E Madde','19','Güncellenmis E2','Güncellenmis Yan Etki2'

GO

SELECT * FROM etkenMaddeTablosuLoglari
SELECT TOP 2 * FROM tblEtkenMaddesi ORDER BY ID DESC

GO

--Verilen parametredeki Etken madde kaydýný silen DELETE SP
IF OBJECT_ID('dbo.spEtkenMaddeSil') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spEtkenMaddeSil
	END
GO

CREATE PROCEDURE spEtkenMaddeSil(@etkenMadde AS VARCHAR(20)=NULL,@yanEtki AS VARCHAR(50)=NULL,@ID AS INT=NULL)
AS
SET NOCOUNT ON
	IF @etkenMadde IS NULL AND @yanEtki IS NULL AND @ID IS NULL
		PRINT 'Paremetre girilmediði için silme iþlemi yapýlamadý.'
	ELSE IF @yanEtki IS NULL AND @etkenMadde IS NOT NULL AND @ID IS NULL
		PRINT 'Yetersiz parametre girildiði için silme iþlemi yapýlamadý'
	ELSE
		DELETE FROM tblEtkenMaddesi
			OUTPUT GETDATE(),'DELETE',null,null,DELETED.ADI,DELETED.YanEtkisi INTO etkenMaddeTablosuLoglari
	    WHERE ADI=ISNULL(@etkenMadde,ADI) AND YanEtkisi=ISNULL(@yanEtki,YanEtkisi) AND ID=ISNULL(@ID,ID)
SET NOCOUNT OFF

GO

--Parametreler için farklý gösterimler
--UPDATE SP de güncellenen son kayda göre silme yapýlmýþtýr
EXEC spEtkenMaddeSil
EXEC spEtkenMaddeSil 'Güncellenmis Yan Etki2'
EXEC spEtkenMaddeSil NULL ,NULL ,'19'
EXEC spEtkenMaddeSil 'Güncellenmis E2' ,'Güncellenmis Yan Etki2' ,'19'

GO

SELECT * FROM etkenMaddeTablosuLoglari
SELECT * FROM tblSilinmisEtkenMaddeler

GO


--Ameliyat ücretlerinde parametre olarak verilen bir deðerin altýndaki ve üsütündeki ameliyat fiyatlarý için verilen oranlarda artýþ yapan CURSOR SP
--Örneðin 2000 liranýn altýndaki ücretler için %10 üstündekileri için %5 artýþ saðlasýn
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


--Ýsmi verilen ilacý ve o ilacýn üretici firmasýný, etken maddesini ilgili tablolardan silen DELETE SP
--Silinme iþlemleri sýrasýnda hata ile kaþýlaþýp silinmesi gereken kayýtlarýn hepsi silinmediði takdirde silinenleri geri almak için
--transaction management ile kontrol edilmiþtir.
IF OBJECT_ID('dbo.spIlacSil') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spIlacSil
	END
GO

CREATE PROCEDURE spIlacSil(@ilacAdi AS VARCHAR(30))
AS
SET NOCOUNT ON
	DECLARE @tranCounter INT=@@TRANCOUNT
	DECLARE @ureticiID INT --üretici firmanýn ID sini tutup silmek için
	DECLARE @eMaddeID INT --Etkin madde ID sini tutup silmek için

	-- daha önceden açýlmýþ tran varsa onlarý kaybetmemek için kayýt noktasý
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
	-- Tek transantion bu ise yada oluþan hata için komple geri almaktan baþka çare yoksa tüm iþlemleri geri al
		IF @tranCounter=0 OR XACT_STATE()=-1  		
			ROLLBACK TRANSACTION
		ELSE
			BEGIN
				ROLLBACK TRANSACTION sp_IlacSil_kayit_noktasi 
				COMMIT --Kayýt noktasýna kadar olan iþlemleri geri alýp ,Açtýðýmýz traný kapattýk
			END    
		DECLARE @errorMessage NVARCHAR(4000) =ERROR_MESSAGE()
		DECLARE @errorSeverity INT =ERROR_SEVERITY()
		DECLARE @errorState INT =ERROR_STATE()
		RAISERROR(@errorMessage,@errorSeverity,@errorState)
	END CATCH
SET NOCOUNT OFF

GO

--Foreign key'ler cascade olmadýðý için foreign key hatasý alýnacaðýndan diðer tablodaki kayýtlar transaction sayesinde silinmeyecektir.
EXEC spIlacSil 'VÝLFLOKS'

GO


--Verilen ilacý üretici firmasýnýný ve etken maddesini ilgili tablolara ekleyen INSERT SP
--Yukardaki verilerin eklenmesi sýrasýnda herhangi birinin eklenmesi sýrasýnda bir hata ile karþýlaþýp eklenemediði takdirde 
--eklenenleri geri almak için transaction management ile kontrol edilmesi
IF OBJECT_ID('dbo.spIlacEkle') IS NOT NULL
	BEGIN
		DROP PROCEDURE dbo.spIlacEkle
	END
GO

CREATE PROCEDURE spIlacEkle(@ilacAdi AS VARCHAR(30),@ureticiFirma AS VARCHAR(100),@etkenMadde AS VARCHAR(20),@yanEtki AS VARCHAR(50))
AS
SET NOCOUNT ON
	DECLARE @tranCounter INT=@@TRANCOUNT
	DECLARE @ureticiID INT --üretici firmanýn ID sini tutup referans vermek için
	DECLARE @eMaddeID INT --Etkin madde ID sini tutup referans vermek için

	-- daha önceden açýlmýþ tran varsa onlarý kaybetmemek için kayýt noktasý
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
	-- Tek transantion bu ise yada oluþan hata için komple geri almaktan baþka çare yoksa tüm iþlemleri geri al
		IF @tranCounter=0 OR XACT_STATE()=-1  		
			ROLLBACK TRANSACTION
		ELSE
			BEGIN
				ROLLBACK TRANSACTION sp_IlacEkle_kayit_noktasi 
				COMMIT --Kayýt noktasýna kadar olan iþlemleri geri alýp ,Açtýðýmýz traný kapattýk
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
-- eklenenleri gösterim için
SELECT TOP 2 * FROM tblIlac ORDER BY ID DESC
SELECT TOP 2 * FROM tblUreticiFirma ORDER BY ID DESC
SELECT TOP 2 * FROM tblEtkenMaddesi ORDER BY ID DESC


