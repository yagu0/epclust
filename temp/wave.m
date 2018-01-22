t = 1:128

n=length(t);

%----------default arguments for the wavelet transform-----------
Args=struct('Pad',1,...      % pad the time series with zeroes (recommended)
            'Dj',1/12, ...    % this will do 12 sub-octaves per octave
            'S0',2*dt,...    % this says start at a scale of 2 years
            'J1',[],...
            'Mother','Morlet', ...
            'MaxScale',[],...   %a more simple way to specify J1

J1 = noctave * nvoice - 1

nx=size(x,1);
ny=size(y,1);

[X,period,scale] = wavelet(x,Args.Dj,Args.S0,Args.J1);
[Y,period,scale] = wavelet(y,Args.Dj,Args.S0,Args.J1);





## pad with 0 ?
## compare Rwave and biwavelets
x = runif(128) #runif(100)
w1 = wt(cbind(1:128,x), pad = TRUE, dt = NULL, do.sig=FALSE, dj=1/12, J1=51)
w2 = Rwave::cwt(x, 13, 4, w0=2*pi, twoD=TRUE, plot=FALSE)








%Smooth X and Y before truncating!  (minimize coi)
sinv=1./(scale');
sX=smoothwavelet(sinv(:,ones(1,nx)).*(abs(X).^2),dt,period,Args.Dj,scale);
sY=smoothwavelet(sinv(:,ones(1,ny)).*(abs(Y).^2),dt,period,Args.Dj,scale);

% -------- Cross wavelet -------
Wxy=X.*conj(Y);

% ----------------------- Wavelet coherence ---------------------------------
sWxy=smoothwavelet(sinv(:,ones(1,n)).*Wxy,dt,period,Args.Dj,scale);

%%%%%% SMOOTHWAVELET
n=size(wave,2);

%swave=zeros(size(wave));
twave=zeros(size(wave));

%zero-pad to power of 2... Speeds up fft calcs if n is large
npad=2.^ceil(log2(n));

k = 1:fix(npad/2);
k = k.*((2.*pi)/npad);
k = [0., k, -k(fix((npad-1)/2):-1:1)];

k2=k.^2;
snorm=scale./dt;
for ii=1:size(wave,1)
    F=exp(-.5*(snorm(ii)^2)*k2); %Thanks to Bing Si for finding a bug here.
    smooth=ifft(F.*fft(wave(ii,:),npad));
    twave(ii,:)=smooth(1:n);
end

if isreal(wave)
    twave=real(twave); %-------hack-----------
end

%scale smoothing (boxcar with width of .6)

%
% TODO: optimize. Because this is done many times in the monte carlo run.
%


dj0=0.6;
dj0steps=dj0/(dj*2);
% for ii=1:size(twave,1)
%     number=0;
%     for l=1:size(twave,1);
%         if ((abs(ii-l)+.5)<=dj0steps)
%             number=number+1;
%             swave(ii,:)=swave(ii,:)+twave(l,:);
%         elseif ((abs(ii-l)+.5)<=(dj0steps+1))
%             fraction=mod(dj0steps,1);
%             number=number+fraction;
%             swave(ii,:)=swave(ii,:)+twave(l,:)*fraction;
%         end
%     end
%     swave(ii,:)=swave(ii,:)/number;
% end

kernel=[mod(dj0steps,1); ones(2 * round(dj0steps)-1,1); ...
   mod(dj0steps,1)]./(2*round(dj0steps)-1+2*mod(dj0steps,1));
swave=conv2(twave,kernel,'same'); %thanks for optimization by Uwe Graichen








Rsq=abs(sWxy).^2./(sX.*sY);
return Rsq

%varargout={Rsq,period,scale,coi,wtcsig,t};
%varargout=varargout(1:nargout);
