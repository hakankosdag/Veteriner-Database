USE veteriner
--Sorgu1:T�m k�pek t�rleri ve t�m hastal�k �ei�tleri i�in 2017 y�l� ay baz�nda hastal�klar�n g�r�lme s�kl���(�rne�in dobermanlarda uyuz ocak ay�nda 25 vakada g�r�lm��)


--Sorgu2:Tetanoz a��s�n�n ge�erlili�inin bitmesine �� g�n kalan hastalar�n son tedavi kay�tlar�na ait bilgiler
SELECT TOP 1 HTespitTarihi,TedaviBaslangici,KontrolTarihi,Ucret
FROM tblTedavi T
	inner join tblAsi A ON T.HastaID=A.HastaID 
    inner join tblAsiTuru asi ON  A.AsiTuruID=asi.ID
WHERE asi.Turu='Tetanoz a��s�' AND  3= DATEDIFF(dd,GETDATE(),A.GecerlilikSuresi)
ORDER BY KontrolTarihi

--Sorgu3:Kuduz a��s� olan hastalar�n hasta bilgisini veren sorgu
SELECT Ht.ADI Turu, C.ADI Cinsi
FROM tblCins C
	inner join tblHastaTuru Ht ON C.HtID=Ht.ID
	inner join tblHasta H ON Ht.ID=H.HtID
	inner join tblAsi A ON A.HastaID=H.ID
	inner join tblAsiTuru Ast ON Ast.ID=A.AsiTuruID
WHERE Ast.Turu='Kuduz a��s�'
	

--Sorgu4:Deri t�m�r� ameliyat� ge�iren hastan�n ila�lar�n�n dozaj� ,kullan�m s�resi ve uygulanma �eklini veren sorgu
SELECT I.Dozaj , I.Kulan�mSuesi,I.UygulanmaSekli
FROM Icerir I
WHERE I.ReceteID IN(SELECT R.ID
					FROM tblRecete R inner join tblVeteriner V ON R.VetID=V.ID
					inner join tblAmeliyat A ON A.VetID=V.ID
					WHERE A.ADI='Deri T�m�r� Operasyonu')

--Sorgu5:Parazit koruma ge�erlilik s�resini 1 y�l ge�mi� hastalar�n sahiplerinin isim numara ve e mailini veren sorgu
SELECT S.AD ,S.SOYAD ,S.Tel , S.Mail
FROM tblSahip S ,tblHasta H ,tblParazitKoruma P
WHERE S.ID=H.SahipID AND H.ID=P.HastaID AND 1<DATEDIFF(yy,P.GecerlilikSuresi,GETDATE())