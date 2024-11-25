function data = ct_smooth(data,cutoff)
% data = ct_smooth(data,cutoff)

N = round(1/cutoff/2)*2+1;
H = tukeywin(N,0.5).';
H = H ./ sum(H);
data = fir_dec(data,H,1);


