--Girilen bir yýl için o yýlda en çok rastlanan hastalýðý döndüren fonksiyon.
IF OBJECT_ID('dbo.fncFazlaHastalik') IS NOT NULL
	BEGIN
		DROP FUNCTION dbo.fncFazlaHastalik
	END
GO

CREATE FUNCTION fncFazlaHastalik(@yil INT)
RETURNS NVARCHAR(50)
AS
	BEGIN
		DECLARE @hastalik VARCHAR(50)
		SELECT  TOP 1 @hastalik = H.ADI 
		FROM tblHastalik H INNER JOIN tblTedavi T ON H.ID=T.HastalikID
		WHERE YEAR( T.TedaviBaslangici)=@yil
		GROUP BY H.ADI
		ORDER BY COUNT(*) DESC

		RETURN @hastalik
	END

GO
SELECT dbo.fncFazlaHastalik('2012')

GO


-- Tc'si girilen sahibin , hastasýnýn aþý türü ,aþý yapýlma ve geçerlilik tarihini tablo olarak dönen fonksiyon.
IF OBJECT_ID('dbo.fncAsiBilgisi') IS NOT NULL
	BEGIN
		DROP FUNCTION dbo.fncAsiBilgisi
	END
GO

CREATE FUNCTION fncAsiBilgisi(@tcno char(11))
RETURNS TABLE AS
RETURN
(
	SELECT ATU.Turu AS AþýTürü, A.AsýTarihi AS Asi_Tarihi, A.GecerlilikSuresi AS Gecerlilik_Süresi 
	FROM tblAsiTuru ATU INNER JOIN tblAsi A ON ATU.ID=A.AsiTuruID
						INNER JOIN tblHasta H ON A.HastaID=H.ID
						INNER JOIN tblSahip S ON H.SahipID=S.ID
	WHERE S.TCNO=@tcno
)

GO

SELECT * FROM dbo.fncAsiBilgisi('14345678986')

GO


--Girilen parazit koruma türünün hayvan türleri bazýnda ortalama koruma süresini gün olarak hesaplayýp tablo olarak dönen fonksiyon
IF OBJECT_ID('dbo.fncOrtParazitKoruma') IS NOT NULL
	BEGIN
		DROP FUNCTION dbo.fncOrtParazitKoruma
	END
GO

CREATE FUNCTION fncOrtParazitKoruma(@pKorumaTuru VARCHAR(50))
RETURNS TABLE AS
RETURN
(
	SELECT HT.ADI AS Hasta_Turu ,AVG(DATEDIFF(DAY,P.YapýlmaTarihi,P.GecerlilikSuresi)) AS OrtSure
	FROM tblKorumaTuru K INNER JOIN tblParazitKoruma P ON K.PkorumaID=P.ID
						 INNER JOIN tblHasta H ON P.HastaID=H.ID
						 INNER JOIN tblHastaTuru HT ON H.HtID=HT.ID
	WHERE K.Turu=@pKorumaTuru
	GROUP BY HT.ADI
)
GO
SELECT * FROM dbo.fncOrtParazitKoruma('Pirelerden korur')