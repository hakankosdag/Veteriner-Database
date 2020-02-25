--Girilen bir y�l i�in o y�lda en �ok rastlanan hastal��� d�nd�ren fonksiyon.
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


-- Tc'si girilen sahibin , hastas�n�n a�� t�r� ,a�� yap�lma ve ge�erlilik tarihini tablo olarak d�nen fonksiyon.
IF OBJECT_ID('dbo.fncAsiBilgisi') IS NOT NULL
	BEGIN
		DROP FUNCTION dbo.fncAsiBilgisi
	END
GO

CREATE FUNCTION fncAsiBilgisi(@tcno char(11))
RETURNS TABLE AS
RETURN
(
	SELECT ATU.Turu AS A��T�r�, A.As�Tarihi AS Asi_Tarihi, A.GecerlilikSuresi AS Gecerlilik_S�resi 
	FROM tblAsiTuru ATU INNER JOIN tblAsi A ON ATU.ID=A.AsiTuruID
						INNER JOIN tblHasta H ON A.HastaID=H.ID
						INNER JOIN tblSahip S ON H.SahipID=S.ID
	WHERE S.TCNO=@tcno
)

GO

SELECT * FROM dbo.fncAsiBilgisi('14345678986')

GO


--Girilen parazit koruma t�r�n�n hayvan t�rleri baz�nda ortalama koruma s�resini g�n olarak hesaplay�p tablo olarak d�nen fonksiyon
IF OBJECT_ID('dbo.fncOrtParazitKoruma') IS NOT NULL
	BEGIN
		DROP FUNCTION dbo.fncOrtParazitKoruma
	END
GO

CREATE FUNCTION fncOrtParazitKoruma(@pKorumaTuru VARCHAR(50))
RETURNS TABLE AS
RETURN
(
	SELECT HT.ADI AS Hasta_Turu ,AVG(DATEDIFF(DAY,P.Yap�lmaTarihi,P.GecerlilikSuresi)) AS OrtSure
	FROM tblKorumaTuru K INNER JOIN tblParazitKoruma P ON K.PkorumaID=P.ID
						 INNER JOIN tblHasta H ON P.HastaID=H.ID
						 INNER JOIN tblHastaTuru HT ON H.HtID=HT.ID
	WHERE K.Turu=@pKorumaTuru
	GROUP BY HT.ADI
)
GO
SELECT * FROM dbo.fncOrtParazitKoruma('Pirelerden korur')