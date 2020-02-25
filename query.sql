USE veteriner
--Sorgu1:Tüm köpek türleri ve tüm hastalýk çeiþtleri için 2017 yýlý ay bazýnda hastalýklarýn görülme sýklýðý(örneðin dobermanlarda uyuz ocak ayýnda 25 vakada görülmüþ)


--Sorgu2:Tetanoz aþýsýnýn geçerliliðinin bitmesine üç gün kalan hastalarýn son tedavi kayýtlarýna ait bilgiler
SELECT TOP 1 HTespitTarihi,TedaviBaslangici,KontrolTarihi,Ucret
FROM tblTedavi T
	inner join tblAsi A ON T.HastaID=A.HastaID 
    inner join tblAsiTuru asi ON  A.AsiTuruID=asi.ID
WHERE asi.Turu='Tetanoz aþýsý' AND  3= DATEDIFF(dd,GETDATE(),A.GecerlilikSuresi)
ORDER BY KontrolTarihi

--Sorgu3:Kuduz aþýsý olan hastalarýn hasta bilgisini veren sorgu
SELECT Ht.ADI Turu, C.ADI Cinsi
FROM tblCins C
	inner join tblHastaTuru Ht ON C.HtID=Ht.ID
	inner join tblHasta H ON Ht.ID=H.HtID
	inner join tblAsi A ON A.HastaID=H.ID
	inner join tblAsiTuru Ast ON Ast.ID=A.AsiTuruID
WHERE Ast.Turu='Kuduz aþýsý'
	

--Sorgu4:Deri tümörü ameliyatý geçiren hastanýn ilaçlarýnýn dozajý ,kullaným süresi ve uygulanma þeklini veren sorgu
SELECT I.Dozaj , I.KulanýmSuesi,I.UygulanmaSekli
FROM Icerir I
WHERE I.ReceteID IN(SELECT R.ID
					FROM tblRecete R inner join tblVeteriner V ON R.VetID=V.ID
					inner join tblAmeliyat A ON A.VetID=V.ID
					WHERE A.ADI='Deri Tümörü Operasyonu')

--Sorgu5:Parazit koruma geçerlilik süresini 1 yýl geçmiþ hastalarýn sahiplerinin isim numara ve e mailini veren sorgu
SELECT S.AD ,S.SOYAD ,S.Tel , S.Mail
FROM tblSahip S ,tblHasta H ,tblParazitKoruma P
WHERE S.ID=H.SahipID AND H.ID=P.HastaID AND 1<DATEDIFF(yy,P.GecerlilikSuresi,GETDATE())