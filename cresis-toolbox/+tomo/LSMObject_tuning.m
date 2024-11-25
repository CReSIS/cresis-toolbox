classdef LSMObject_tuning <handle
  %LSMObject constructor
  %requires a list of images (full file paths), file type, and image resize rate
  % LSMObject(listOfFiles,fileType,resizeRate)
  %   Detailed explanation goes here
  
  properties (Access=protected)
    imds
    % fileType='png'
    phi
    resizeRate
    initiArgs
    lsmArgs
    contours
  end
  
  methods
    
    function this = LSMObject_tuning(imds)
      this.imds= imds; %dir(imds.inputPath);
      %this.inFolder=this.imds.folder;
      this.resizeRate=.5;
      this.setLSMOptions()
      
      % Set file type
      %this.fileType=fileType;
      
      % Initialize Contours
      this.contours=cell(numel(this.imds),...
        1+ceil(this.lsmArgs.outerIter*this.lsmArgs.innerIter/10));
    end
    
    function setResize(this, rate)
      this.resizeRate=rate;
    end
    
    function [fname,ftype]=getFileName(file)
      [a,~]=strtok(wrev(file), filesep);
      [fname,ftype]=strtok(wrev(a), '.');
    end
    
    function  setLSMOptions(this, varargin)
      try
        parser = createParserLSM();
        parser.parse(varargin{:});
        [this.initiArgs, this.lsmArgs] = convertToCanonicalFormLSM(parser);
        this.initiArgs.resize=this.resizeRate;
        this.contours=cell(numel(this.imds),...
          1+ceil(this.lsmArgs.outerIter*this.lsmArgs.innerIter/10));
      catch e
        % Reduce the stack trace of the error message by throwing as caller
        throwAsCaller(e)
      end
    end
    
    function out = getLSMoptions(this)
      out.lambda = this.lsmArgs.lambda;
      out.alpha = this.lsmArgs.alpha;
      out.mu = this.lsmArgs.mu;
      out.innerIter = this.lsmArgs.innerIter;
      out.storeIter = this.lsmArgs.storeIter;
      out.outerIter = this.lsmArgs.outerIter;
      out.timestep = this.lsmArgs.timestep;
      out.narrowBand = this.lsmArgs.narrowBand;
      out.snapshots = this.lsmArgs.snapshots;
    end
    
    function cs=getContours(this,imgIdx,step)
      cs= this.contours{imgIdx,step};
    end
    
    function last=lastContour(this)
      last= size(this.contours,2);
    end
    
    function [fname,ftype]=fileInfo(this,k)
      [fname,ftype]= getFileName(this.imds{k});
    end
    
    function showContours(this, k,s)
      %[img, ~, ftype]=readImage(this.imds{k});
      img = double(this.imds{k});
      ce=this.contours{k,s}; %returns the contours for image k
      showImage(img, ftype)  %show the image
      hold on
      keyboard
      for j=1:numel(ce) %draw the contour
        plot(ce{j}(1,:), ce{j}(2,:), 'b');
      end
    end
    
    function [fname,ftype]=disp(this,k)
      if isfield(this,'imds')
        [fname,ftype]=getFileName(this.imds{k});
      end
      if isfield(this,'lastContour')
        this.showContours(k,this.lastContour);
      end
    end
    
    function [flag, top, bot, matrix_x, matrix_y] = runLSM(this)
      
      flag = ones(1,length(this.lsmArgs.storeIter));
      
      % Read the image
      %[img_orig,~,~] = readImage(this.imds{1});
      img_orig = double(this.imds{1});
      img = imresize(img_orig, this.resizeRate);
      
      matrix_x = ones(2, size(img_orig, 2), length(this.lsmArgs.storeIter));
      matrix_y = ones(2, size(img_orig, 2), length(this.lsmArgs.storeIter));
      g=indicateEdge(img);
      this.phi=initializeLSM(img, this.initiArgs);
      this.contours{1,1}= getLSF(this.phi, 1/this.resizeRate);
      % LSM
      last_fprintf_time = -inf;
      for n=1:this.lsmArgs.outerIter
        if now > last_fprintf_time+30/86400
          fprintf('  Iteration %.0f of %.0f (%s)\n', n, this.lsmArgs.outerIter, datestr(now));
          last_fprintf_time = now;
        end
        
        this.phi=lsmReg(this.phi, g, this.lsmArgs);
        
        m=this.lsmArgs.innerIter*n;
        if rem(m,10)==0
          this.contours{1,m/10+1}= getLSF(this.phi, 1/this.resizeRate);
        end
        
        match_idx = find(n==this.lsmArgs.storeIter);
        if any(match_idx)
          c = contourc(this.phi, [0,0]);
          s = tomo.contourdata(c);
          % Ensure proper order of layers
          if 0
            % Debug plot to show contours
            figure;
            c = contour(this.phi, [0,0], 'r');
          end
          try
            if sum(s(1).ydata) > sum(s(2).ydata)
              s = s([2 1]);
            end
            top.x = (1 / this.resizeRate) * imresize(s(1).xdata, [size(img_orig, 2) 1]);
            top.y = (1 / this.resizeRate) * imresize(s(1).ydata, [size(img_orig, 2) 1]);
            bot.x = (1 / this.resizeRate) * imresize(s(2).xdata, [size(img_orig, 2) 1]);
            bot.y = (1 / this.resizeRate) * imresize(s(2).ydata, [size(img_orig, 2) 1]);
          catch ME
            try
              top.x = (1 / this.resizeRate) * imresize(s(1).xdata, [size(img_orig, 2) 1]);
              top.y = (1 / this.resizeRate) * imresize(s(1).ydata, [size(img_orig, 2) 1]);
              bot.x = top.x;
              bot.y = top.y;
            catch ME
              keyboard
            end
          end
          matrix_x(1, :, match_idx)  = top.x';
          matrix_x(2, :, match_idx)  = bot.x';
          matrix_y(1, :, match_idx)  = top.y';
          matrix_y(2, :, match_idx)  = bot.y';
          
          if any(any(isnan(this.phi)))
            flag(ctr) = 0;
            matrix_x(1, :, match_idx)  = '';
            matrix_x(2, :, match_idx)  = '';
            matrix_y(1, :, match_idx)  = '';
            matrix_y(2, :, match_idx)  = '';
          end
          % Use below code to get echogram images with different number of iterations (n)
          %           if(n==25||n==100||n==200||n==300||n==350)
          %              figure;imagesc(img_orig);colormap(1-gray(256));hold on; plot(top.x,top.y);plot(bot.x,bot.y);
          %            end
        end
      end
    end
  end
end
%% initialization
function phi=initializeLSM(img, initiArgs)
c0=initiArgs.c0;
x=(initiArgs.x).*(initiArgs.resize); dx=initiArgs.dx;
y=(initiArgs.y).*(initiArgs.resize); dy=initiArgs.dy;
initialLSF = c0*ones(size(img));
for i=1:numel(x)
  if x(i)>0
    initialLSF(:, x(i):x(i)+dx)=-c0;
  end
  if y(i)>0
    initialLSF(y(i):y(i)+dy, :)=-c0;
  end
end
phi=initialLSF;
end
%% LSF and Edge
function lsc=getLSF(phi, rs)
phi=imresize(phi,rs);
c = contourc(phi, [0,0]);
x1=1;
k=0;
lsc=cell(1,100);
while x1<size(c,2)
  k=k+1;
  x2=c(2,x1)+x1+1;
  lsc{k}=[c(1,x1+1:x2-1) ; c(2,x1+1:x2-1)];
  x1=x2;
end
if k>0 && k<100
  lsc=lsc(1:k);
end
end

function  g=indicateEdge(image)
G=fspecial('average',5); % Average kernel
img_smooth=conv2(image,G,'same');  % smooth image by Gaussiin convolution
[Ix,Iy]=gradient(img_smooth);
f=Ix.^2+Iy.^2;
g=1./(1+f);  % edge indicator function.
end
%% show progress

function c = dispc(h,phi) %display image and contours
figure(h);
hold on;
c  = contour(phi, [0,0], 'r');
end

function [fname,ftype]=getFileName(file)
[a,~]=strtok(wrev(file), filesep);
[fname,ftype]=strtok(wrev(a), '.');
end
%% parser

function p = createParserLSM()

p = inputParser;

%LSM Args
defaultLambda = 5;
defaultAlpah = -3;
defaultMu = 0.1;
defaultInnerIter = 2;
defaultOuterIter = 400;
defaultStoreIter = defaultOuterIter;
defaultTimestep = 2;
defaultViewSnaps = 100;
defaultNarrowBand = false;

p.addParameter('lambda', defaultLambda, @numeric);
p.addParameter('alpha', defaultAlpah, @numeric);
p.addParameter('mu', defaultMu, @numeric);
p.addParameter('innerIter', defaultInnerIter, @isPositiveInteger);
p.addParameter('outerIter', defaultOuterIter, @isPositiveInteger);
p.addParameter('storeIter', defaultStoreIter, @isPositiveInteger);
p.addParameter('timestep', defaultTimestep, @isPositiveInteger);
p.addParameter('snapshots', defaultViewSnaps, @isPositiveInteger);
p.addParameter('narrowBand', defaultNarrowBand, @islogical);

% initial Args
defaultc0 = 2;
defaultx =0;
defaultdx = 5;
defaulty = 120;
defaultdy = 5;


p.addParameter('c0', defaultc0, @isnumeric);
p.addParameter('x', defaultx, @isnumeric);
p.addParameter('dx', defaultdx, @isnumeric);
p.addParameter('y', defaulty, @isnumeric);
p.addParameter('dy', defaultdy, @isnumeric);
end

function [initiArgs , lsmArgs] = convertToCanonicalFormLSM(parser)
results = parser.Results;
lsmArgs = struct;
lsmArgs.lambda = results.lambda;
lsmArgs.alpha = results.alpha;
lsmArgs.mu = results.mu;
lsmArgs.innerIter = results.innerIter;
lsmArgs.storeIter = results.storeIter;
lsmArgs.outerIter = results.outerIter;
lsmArgs.timestep = results.timestep;
lsmArgs.snapshots = results.snapshots;
lsmArgs.narrowBand = results.narrowBand;

initiArgs=struct;
initiArgs.c0 = results.c0;
initiArgs.x= results.x;
initiArgs.dx = results.dx;
initiArgs.y = results.y;
initiArgs.dy = results.dy;
end


function tf = isPositiveInteger(x)
isPositive = all(x>0);
isInteger = all(isreal(x)) && all(isnumeric(x)) && all(mod(x,1)==0);
tf = isPositive && isInteger;
end

function tf = numeric(x)
tf= isreal(x) && isnumeric(x) && isscalar(x);
end

%% lsmReg
function phi = lsmReg(phi0, g,lsmArgs )
%This Matlab code implements an edge-based active contour model without
%narrow band
%
%  Input:
%      phi0: level set function to be updated by level set evolution
%      g: edge indicator function
% .    lambda:  length termcoefficient
%      mu: distance regularization term coefficient
%      alfa:   area term coefficient
%      timestep: time step
%
%
%  Output:
%      phi: updated level set function after level set evolution

lambda=lsmArgs.lambda;
mu=lsmArgs.mu;
alpha=lsmArgs.alpha;
timestep=lsmArgs.timestep;
iter=lsmArgs.innerIter;
nb=lsmArgs.narrowBand;
epsiln=1e-10;
sigma=1.5; %width of Dirac Delta function
phi=phi0;
[vx, vy]=gradient(g);
for k=1:iter %% iteration_inner
  phi=nbc(phi);
  phi1=phi;%nb
  [phi_x,phi_y]=gradient(phi);
  if nb
    phi=phi.*(phi_x+phi_y~=0); %nb
  end
  s=sqrt(phi_x.^2 + phi_y.^2);
  Nx=phi_x./(s+epsiln);
  Ny=phi_y./(s+epsiln);
  curvature=divergence(Nx,Ny);
  
  diracPhi=ddirac(phi,sigma);
  % terms
  areaTerm=diracPhi.*g;
  edgeTerm=diracPhi.*(vx.*Nx+vy.*Ny) + diracPhi.*g.*curvature;
  regTerm=distReg(phi);
  phi=phi1 + timestep*(mu*regTerm + lambda*edgeTerm + alpha*areaTerm);
end
end


function f = distReg(phi)
% compute the distance regularization term with a double-well potential
[phi_x,phi_y]=gradient(phi);
s=sqrt(phi_x.^2 + phi_y.^2);
ps=((s>=0) & (s<=1)).*sin(2*pi*s)/(2*pi)+(s>1).*(s-1);
dps=((ps~=0).*ps+(ps==0))./((s~=0).*s+(s==0));
f = divergence(dps.*phi_x - phi_x, dps.*phi_y - phi_y) + 4*del2(phi);

end
function f = ddirac(x, sigma)
f=(1/2/sigma)*(1+cos(pi*x/sigma));
b = (x<=sigma) & (x>=-sigma);
f = f.*b;
end

function g = nbc(f)
g = f;
g(1,:)=f(3,:);
g(end,:)=f(end-2,:);
g(:,end)=g(:,end-2);
g(:,1)=g(:,3);
end

function [img, fname , ftype]= readImage(filepath)
[fname,ftype]=getFileName(filepath);
if ftype=='.mat'
  in = load(filepath, 'Data');
  %   img=lp(in.Data);
  img = 20*log10(in.Data);
elseif ftype=='.png'
  img=imread(filepath);
  img=img(:,:,1);
else
  disp('Error. Specify the file type.')
  return;
end
img=double(img);
end