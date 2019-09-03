% Vypracovala: Katerina Fortova (xforto00)
% Datum vypracovani: prosinec 2018
% Projekt ISS

pkg load signal; % balicek pro Octave


% 1. uloha
fprintf('1. uloha\n');
[s, Fs] = audioread ('xforto00.wav'); s = s'; % potrebuju radkovy vektor
pocet_vzorku = length(s);
cas = pocet_vzorku/Fs;
t = (0:(length(s)-1)) / Fs;
pocet_bin_symboly = pocet_vzorku/16;
fprintf('Vzorkovaci frekvence signalu je %d\n', Fs);
fprintf('Delka signalu ve vzorcich je %d\n', pocet_vzorku);
fprintf('Delka signalu v sekundach je %d\n', cas);
fprintf('Pocet reprezentovanych binarnich symbolu je %d\n', pocet_bin_symboly);

% 2. uloha
bin_hodnoty = []; % pole pro ukladani binarnich symbolu

pocitadlo = 8; 
bin_hodnoty_index = 1; % index pro pole binarnich symbolu

while pocitadlo < pocet_vzorku
  if (s(pocitadlo) > 0)
    bin_hodnoty(bin_hodnoty_index) = 1;
  elseif (s(pocitadlo) < 0)
    bin_hodnoty(bin_hodnoty_index) = 0;
  endif
  
  pocitadlo = pocitadlo + 16;
  bin_hodnoty_index++;
endwhile

figure(1);

hold on

plot(t,s)
stem(linspace(0.0005, 2, 2000), bin_hodnoty)
axis([0 0.020 -1 1]);
title('2. uloha - Dekodovani do binarnich symbolu')
xlabel('t')
ylabel('s[n], symboly')

% 3. uloha
B = [0.0192 -0.0185 -0.0185 0.0192]; % koeficienty filtru
A = [1.0000 -2.8870 2.7997 -0.9113]; % koeficienty filtru

figure(2)
zplane(B,A); % vykresleni jednotkove kruznice
title('3. uloha - Nulove body a poly prenosove funkce filtru')

% 4. uloha
figure(3)
ukazmito(B,A,Fs); % zobrazi nejen kmitoctovou charakteristiku, ale nakonec i zkontroluje 3. ulohu

% 5. uloha
% graf z 2. ulohy:
figure(4)
while pocitadlo < pocet_vzorku
  if (s(pocitadlo) > 0)
    bin_hodnoty(bin_hodnoty_index) = 1;
  elseif (s(pocitadlo) < 0)
    bin_hodnoty(bin_hodnoty_index) = 0;
  endif
  
  pocitadlo = pocitadlo + 16;
  bin_hodnoty_index++;
endwhile

hold on
plot(t,s);
stem(linspace(0.0005, 2, 2000), bin_hodnoty)
axis([0 0.020 -1 1]);
% vykresleni filtrovaneho signalu:
hold on
filter_signal = filter(B,A,s);
t = (0:(length(s)-1)) / Fs;
figure(4)
plot (t,filter_signal);
title('5. uloha - Filtrovani signalu s[n]')
xlabel('t')
ylabel('s[n], ss[n], symboly')


% 6. uloha
% puvodni signal:
figure(5)
plot(t,s)
hold on
% filtrovany signal:
filter_signal = filter(B,A,s);
t = (0:(length(s)-1)) / Fs;
figure(5)
plot (t,filter_signal);
hold on
% posunuti filtrovaneho signalu:
t = (0:(length(s)-1)) / Fs;
posun = circshift(filter_signal,[-16 -16]);
figure(5)
plot(t,posun);
hold on
% dekodovani posunuteho signalu do bin symbolu
bin_hodnoty_posun = []; % pole pro ukladani binarnich symbolu posunuteho signalu

pocitadlo_posun = 8; 
bin_hodnoty_index_posun = 1; % index pro pole binarnich symbolu posunuteho signalu
while pocitadlo_posun < pocet_vzorku
  if (posun(pocitadlo_posun) > 0)
    bin_hodnoty_posun(bin_hodnoty_index_posun) = 1;
  elseif (posun(pocitadlo_posun) < 0)
    bin_hodnoty_posun(bin_hodnoty_index_posun) = 0;
  endif
  
  pocitadlo_posun = pocitadlo_posun + 16;
  bin_hodnoty_index_posun++;
endwhile

hold on
plot(t,posun);
stem(linspace(0.0005, 2, 2000), bin_hodnoty_posun)
axis([0 0.020 -1 1]);


title('6. uloha - Posun filtrovaneho signalu ss[n], dekodovani ss_{shifted}[n] do binarnich symbolu')
xlabel('t')
ylabel('s[n], ss[n], ss_{shifted}[n], symboly')

% 7. uloha
fprintf('7. uloha\n');
xor_poli = xor(bin_hodnoty, bin_hodnoty_posun);
nenulove_hodnoty = nnz(xor_poli); % potrebuju zjistit pocet jednicek - chyb
chybovost = (nenulove_hodnoty/pocet_bin_symboly)*100;
fprintf('Pocet chyb cini %d\n', nenulove_hodnoty);
fprintf('Chybovost cini %f%%\n', chybovost);
% 8. uloha
% modul spektra filtrovaneho signalu:
fft_filter_s = abs(fft(filter_signal));
figure(6)
plot(fft_filter_s(1:Fs/2));
title('8. uloha - Modul spektra filtrovaneho signalu')
xlabel('Hz');
% modul spektra puvodniho signalu:
fft_puvodni_s = abs(fft(s));
figure(7);
plot(fft_puvodni_s(1:Fs/2));
title('8. uloha - Modul spektra puvodniho signalu')
xlabel('Hz');


% 9. uloha
fprintf('9. uloha\n');
hustota_rozdeleni = hist(s, 100)
T = linspace(min(s), max(s)); % pole rovnomerne rozdelenych hodnot

figure(8)
plot(T,hustota_rozdeleni)
title('9. uloha - Odhad funkce hustoty rozdeleni pravdepodobnosti p(x)')
xlabel('x')
ylabel('p(x)')

% kontrola integralu funkce:
kontrola_int = sum(hustota_rozdeleni/pocet_vzorku);
fprintf('Kontrola - Integral hustoty rozdeleni pravdepodobnosti je %d\n', kontrola_int);

% 10. uloha
k = (-50 : 50);
R = xcorr(s) / pocet_vzorku;
R = R(k + pocet_vzorku);
figure(9)
plot(k, R);
title('10. uloha - Korelacni koeficienty')
xlabel('k');
ylabel('R[k]');
% 11. uloha
fprintf('11. uloha\n');
fprintf('Hodnota koeficientu R[0] je %f\n', R(51));
fprintf('Hodnota koeficientu R[1] je %f\n', R(52));
fprintf('Hodnota koeficientu R[16] je %f\n', R(67));

% 12. uloha
x_2D = linspace(min(s), max(s), 100);
[h,p,r] = hist2opt(s(1:pocet_vzorku-1), s(2:pocet_vzorku), x_2D); % vyuziti pomocne funkce
figure(10)
imagesc(-x_2D,x_2D,p); % vytvoreni obrazku
colorbar; % legenda - barevna skala
title('12. uloha - Casovy odhad sdruzene funkce hustoty rozdeleni pravdepodobnosti');

% 13. uloha
fprintf('13. uloha\n');
[h,p,r] = hist2opt(s(1:pocet_vzorku-1), s(2:pocet_vzorku), x_2D);
% vystup z funkce hist2opt - kontrola - hist2: check -- 2d integral should be 1 and is 1

%14. uloha
fprintf('14. uloha\n');
fprintf('Hodnota koeficientu R[1] z odhadnute funkce hustoty rozdeleni pravdepodobnosti z 13. ulohy je %f\n', r);





