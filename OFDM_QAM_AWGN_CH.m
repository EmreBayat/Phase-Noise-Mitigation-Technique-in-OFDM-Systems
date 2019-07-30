close all;clear all;clc;

numberBitsPerSymbol = 52 ;
numberSymbol = 10^4 ;
subCarrier = 52 ;

EbNo = 0:2:15 ;

EsNo = EbNo+10*log10(4) ;
snr = EsNo ;

M = modem.qammod('M',16);

%Data üretiliyor 
data = randint (96*numberSymbol*4,1,2);

qamdata = bi2de(reshape(data,4,960000).','left-msb');
maping = bin2gray(qamdata,'qam',16);





%modulasyon 

mod_data = modulate(M,maping);
%ser to par
par_data = reshape(mod_data,96,10^4);
%IFFT 
IFFT_data = ifft(par_data);

%add cylic prefix 
cylic_add=[IFFT_data(65:96,:);IFFT_data];
ser_data=reshape(cylic_add,128*10000,1);





error = [] ;
ratio = [] ;
for i =1:length(snr) 
awgnchannel = awgn(ser_data,snr(i),'measured');
ser2par = reshape(awgnchannel,128,10000);
ser2par(1:32,:) = [];

FFT_data = fft(ser2par );
serdata1 = reshape(FFT_data,96*10000,1);
z = modem.qamdemod('M',16);
demod_data = demodulate(z,serdata1);
demaping = gray2bin(demod_data,'qam',16);
data1 = de2bi(demaping,'left-msb');
data2 = reshape(data1.',96*10000*4,1);
[error(i),ratio(i)] = biterr(data,data2);


end

semilogy(EbNo,ratio,'--*r','linewidth',2);
hold on;
theoryBer = (1/4)*3/2*erfc(sqrt(4*0.1*(10.^(EbNo/10))));
semilogy(EbNo,theoryBer ,'--b','linewidth',2);
axis([0 15 10^-5 1])
legend('simulated','theoritical')
grid on
xlabel('EbNo');
ylabel('BER')
title('Bit error probability curve for qam using OFDM');




