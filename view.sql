-- Hastalara verilen ila�lar�n ismini ,dozaj�n�,etken maddesini, yan etkilerini re�ete bilgilerini g�steren view
IF OBJECT_ID('dbo.vwIlacDetay') IS NOT NULL
	BEGIN
		DROP VIEW dbo.vwIlacDetay
	END
GO

CREATE VIEW vwIlacDetay
AS
	SELECT I.ID AS IlacID,
		   I.ADI AS Ilac_Ad�,
		   IC.Dozaj AS Ilac_Dozaji,
		   IC.Kulan�mSuesi AS Kullan�mS�resi,
		   IC.UygulanmaSekli AS UygulanmaSekli,
		   E.ID AS E_ID,E.YanEtkisi,
		   E.ADI AS EtkenMaddesi,
		   H.ID AS HastaID,
		   H.Yas AS Yas,
		   R.ID AS ReceteID,
		   R.GecerlilikSuresi AS ReceteSuresi,
		   R.Turu AS ReceteTuru,
		   HT.ID AS HTuruID,
		   HT.ADI AS Hasta_Turu,
		   C.ID AS CinsID,
		   C.ADI AS Hasta_Cinsi
FROM tblEtkenMaddesi E INNER JOIN tblIlac I ON E.ID=I.EmaddeID
					   INNER JOIN Icerir IC ON I.ID=IC.IlacID
					   INNER JOIN tblRecete R ON IC.ReceteID=R.ID
					   INNER JOIN tblHasta H ON R.HastaID=H.ID
					   INNER JOIN tblHastaTuru HT ON H.HtID=HT.ID
					   INNER JOIN tblCins C ON HT.ID=C.HtID

GO

--View dan yararlanarak, Ameliyat olmu� hastalara verilen ila�lar�, yan etkilerini ve ameliyat� yapan veterineri g�steren sorgu.
SELECT ID.Ilac_Ad�,ID.Ilac_Dozaji,ID.YanEtkisi,A.ADI,V.AD 
FROM vwIlacDetay ID INNER JOIN Olur O ON ID.HastaID=O.HastaID
					INNER JOIN tblAmeliyat A ON O.AmeliyatID=A.ID
					INNER JOIN tblVeteriner V ON A.VetID=V.ID


GO




--Hastalar�n sahibini , t�r�n� , cinsini ,ya��n� ,hastal���n� , tedavi masraf�n� getiren view
IF OBJECT_ID('dbo.vwHastaDetay') IS NOT NULL
	BEGIN
		DROP VIEW dbo.vwHastaDetay
	END
GO

CREATE VIEW vwHastaDetay
AS
	SELECT S.ID AS SahipID,
		   S.TCNO AS SahipTC,
		   S.AD + ' ' + S.SOYAD AS AdSoyad,
		   HT.ID AS HTuruID,
		   HT.ADI AS HastaT�r�,
		   C.ADI AS Cinsi,
		   H.ID AS HastaID,
		   H.Yas AS HastaYasi,
		   HK.ID AS HastalikID,
		   HK.ADI AS Hastal�k,
		   T.Ucret AS TedaviUcreti
	FROM tblSahip S INNER JOIN tblHasta H ON S.ID=H.SahipID
					INNER JOIN tblTedavi T ON T.HastaID=H.ID
					INNER JOIN tblHastalik HK ON T.HastalikID=HK.ID
					INNER JOIN tblHastaTuru HT ON HT.ID=H.HtID
					INNER JOIN tblCins C ON C.HtID=HT.ID

GO
--View'� kullanarak, TC numaras� verilen hasta sahibinin �imdiye kadar �dedi�i toplam tedavi ve ameliyat �cretlerinin toplam�n� g�steren sorgu.
SELECT HD.AdSoyad , SUM(HD.TedaviUcreti+A.Ucret)
FROM vwHastaDetay HD LEFT JOIN Olur O ON HD.HastaID=O.HastaID
					 LEFT JOIN tblAmeliyat A ON A.ID=O.AmeliyatID
WHERE HD.SahipTC='10000255689'
GROUP BY HD.AdSoyad