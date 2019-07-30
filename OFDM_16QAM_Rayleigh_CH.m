close all
clear all
clc

nbitpersym  = 52;   % number of bits per OFDM symbol (same as the number of subcarriers for BPSK)
nsym        = 10^4; % number of symbols
len_fft     = 64;   % fft size
sub_car     = 52;   % number of data subcarriers
EbNo        = 0:5:40;

EsNo= EbNo +10*log10(4); % symbol to noise ratio

snr= EsNo 

M = modem.qammod('M',16) ;

% Generating data

t_data=randint(96*10000*4,1,2);
qamdata = bi2de(reshape(t_data,4,960000).','left-msb');
maping = bin2gray(qamdata,'qam',16);
% modulating data

mod_data = modulate(M,maping);

% serial to parallel conversion

par_data = reshape(mod_data,96,10000);


% fourier transform time doamain data and normalizing the data

IFFT_data = ifft(par_data);

% addition cyclic prefix

cylic_add_data = [IFFT_data(49:96,:);IFFT_data];

% parallel to serial coversion

ser_data = reshape(cylic_add_data,144*10000,1);

% passing thru channel

h=rayleighchan(1/1000000,100);

changain1=filter(h,ones(10000*144,1));
a=max(max(abs(changain1)));
changain1=changain1./a;

chan_data = changain1.*ser_data;
no_of_error=[];
ratio=[];

for ii=1:length(snr)
  
chan_awgn = awgn(chan_data,snr(ii),'measured'); % awgn addition

chan_awgn =chan_awgn./changain1; % assuming ideal channel estimation

ser_to_para = reshape(chan_awgn,144,nsym); % serial to parallel coversion
ser_to_para (1:48,:) = [];

FFT_recdata =fft(ser_to_para);    % freq domain transform

%  FFT_recdata = FFT_recdata./FFT_recdata1;



ser_data_1 = reshape(FFT_recdata,96*10000,1);  % serial coversion

%  ser_data_1  =  ser_data_1./abs(FFT_recdata1);

z=modem.qamdemod('M',16); %demodulation object

demod_Data = demodulate(z,ser_data_1);  %demodulating the data
demaping = gray2bin(demod_Data,'qam',16);
data1 = de2bi(demaping,'left-msb');
data2 = reshape(data1.',96*10000*4,1);
[no_of_error(ii),ratio(ii)]=biterr(t_data,data2) ; % error rate calculation

end

% plotting the result

semilogy(EbNo,ratio,'--or','linewidth',2);
hold on;
EbN0Lin = 10.^(EbNo/10);
theoryBer = 0.5.*(1-sqrt(EbN0Lin./(EbN0Lin+1)));
theory_BER=berfading(EbNo,'qam',16,1);
semilogy(EbNo,theory_BER,'--b','linewidth',2);
legend('simulated','theoritical')
grid on

xlabel('EbNo');
ylabel('BER')
title('Bit error probability curve for qam16  using OFDM');
