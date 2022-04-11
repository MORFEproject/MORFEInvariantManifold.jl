function vec5 = multilinear5(odefile,tens5,q1,q2,q3,q4,q5,x0,p,increment)%--------------------------------------------------------------%This file computes the multilinear function E(q1,q2,q3,q4,q5) where%E = D^5(F(x0)), the fifth derivative of the vectorfield wrt to phase%variables only. We use this for normal form computations in which we%will have q1=q2=q3=q4=q5 or q1=q2=q3\neq q4=q5. We decide on these%cases only. Otherwise we just compute the thing directly without%optimization.% Latest update; 7-9-20 Split complex qi into real ones.%--------------------------------------------------------------nphase=size(x0,1);[nq1,q1]=vecscale(q1);[nq2,q2]=vecscale(q2);[nq3,q3]=vecscale(q3);[nq4,q4]=vecscale(q4);[nq5,q5]=vecscale(q5);if (~isempty(tens5))  vec5=tensor5op(tens5,q1,q2,q3,q4,q5,nphase);elseif (isreal(q1) && isreal(q2) && isreal(q3) && isreal(q4) && isreal(q5))  if (isequal(q1,q2) && isequal(q1,q3))    if (isequal(q1,q4) && isequal(q1,q5))      vec5 = Evvvvv(odefile,q1,x0,p,increment);    else      part1 = Evvvvv(odefile,3.0*q1+2.0*q4,x0,p,increment);      part2 = Evvvvv(odefile,3.0*q1-2.0*q4,x0,p,increment);      part3 = Evvvvv(odefile,3.0*q1,x0,p,increment);      part4 = Evvvvv(odefile,q1,x0,p,increment);      part5 = Evvvvv(odefile,q1+2.0*q4,x0,p,increment);      part6 = Evvvvv(odefile,q1-2.0*q4,x0,p,increment);      vec5 = (part1 + part2 - 2.0*part3 + 6.0*part4 - 3.0*part5 - 3.0*part6)/1920.0;    end  else    part1 = Evvvvv(odefile,q1+q2+q3+q4+q5,x0,p,increment);    part2 = Evvvvv(odefile,q1+q2+q3+q4-q5,x0,p,increment);    part3 = Evvvvv(odefile,q1+q2+q3-q4-q5,x0,p,increment);    part4 = Evvvvv(odefile,q1+q2+q3-q4+q5,x0,p,increment);    part5 = Evvvvv(odefile,q1+q2-q3+q4+q5,x0,p,increment);    part6 = Evvvvv(odefile,q1+q2-q3+q4-q5,x0,p,increment);    part7 = Evvvvv(odefile,q1+q2-q3-q4-q5,x0,p,increment);    part8 = Evvvvv(odefile,q1+q2-q3-q4+q5,x0,p,increment);    vec5 = (part1 - part2 + part3 - part4 - part5 + part6 - part7 + part8)/1920.0;    part1 = Evvvvv(odefile,q1-q2+q3+q4+q5,x0,p,increment);    part2 = Evvvvv(odefile,q1-q2+q3+q4-q5,x0,p,increment);    part3 = Evvvvv(odefile,q1-q2+q3-q4-q5,x0,p,increment);    part4 = Evvvvv(odefile,q1-q2+q3-q4+q5,x0,p,increment);    part5 = Evvvvv(odefile,q1-q2-q3+q4+q5,x0,p,increment);    part6 = Evvvvv(odefile,q1-q2-q3+q4-q5,x0,p,increment);    part7 = Evvvvv(odefile,q1-q2-q3-q4-q5,x0,p,increment);    part8 = Evvvvv(odefile,q1-q2-q3-q4+q5,x0,p,increment);    vec5 = vec5 - (part1 - part2 + part3 - part4 - part5 + part6 - part7 + part8)/1920.0;  endelse %Case of complex vectors q1,q2,q3,q4 call to self with real ones.  q1r=real(q1);q1i=imag(q1);  q2r=real(q2);q2i=imag(q2);  q3r=real(q3);q3i=imag(q3);  q4r=real(q4);q4i=imag(q4);  q5r=real(q5);q5i=imag(q5);  vec5 = multilinear5(odefile,[],q1r,q2r,q3r,q4r,q5r,x0,p,increment);% one imaginary  vec5 = vec5+(1i)*multilinear5(odefile,[],q1i,q2r,q3r,q4r,q5r,x0,p,increment);  vec5 = vec5+(1i)*multilinear5(odefile,[],q1r,q2i,q3r,q4r,q5r,x0,p,increment);  vec5 = vec5+(1i)*multilinear5(odefile,[],q1r,q2r,q3i,q4r,q5r,x0,p,increment);  vec5 = vec5+(1i)*multilinear5(odefile,[],q1r,q2r,q3r,q4i,q5r,x0,p,increment);  vec5 = vec5+(1i)*multilinear5(odefile,[],q1r,q2r,q3r,q4r,q5i,x0,p,increment);% two imaginary  vec5 = vec5+(-1)*multilinear5(odefile,[],q1i,q2i,q3r,q4r,q5r,x0,p,increment);  vec5 = vec5+(-1)*multilinear5(odefile,[],q1i,q2r,q3i,q4r,q5r,x0,p,increment);  vec5 = vec5+(-1)*multilinear5(odefile,[],q1i,q2r,q3r,q4i,q5r,x0,p,increment);  vec5 = vec5+(-1)*multilinear5(odefile,[],q1i,q2r,q3r,q4r,q5i,x0,p,increment);  vec5 = vec5+(-1)*multilinear5(odefile,[],q1r,q2i,q3i,q4r,q5r,x0,p,increment);  vec5 = vec5+(-1)*multilinear5(odefile,[],q1r,q2i,q3r,q4i,q5r,x0,p,increment);  vec5 = vec5+(-1)*multilinear5(odefile,[],q1r,q2i,q3r,q4r,q5i,x0,p,increment);  vec5 = vec5+(-1)*multilinear5(odefile,[],q1r,q2r,q3i,q4i,q5r,x0,p,increment);  vec5 = vec5+(-1)*multilinear5(odefile,[],q1r,q2r,q3i,q4r,q5i,x0,p,increment);  vec5 = vec5+(-1)*multilinear5(odefile,[],q1r,q2r,q3r,q4i,q5i,x0,p,increment);% three imaginary  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1i,q2i,q3i,q4r,q5r,x0,p,increment);  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1i,q2i,q3r,q4i,q5r,x0,p,increment);  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1i,q2i,q3r,q4r,q5i,x0,p,increment);  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1i,q2r,q3i,q4i,q5r,x0,p,increment);  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1i,q2r,q3i,q4r,q5i,x0,p,increment);  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1i,q2r,q3r,q4i,q5i,x0,p,increment);  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1r,q2i,q3i,q4i,q5r,x0,p,increment);  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1r,q2i,q3i,q4r,q5i,x0,p,increment);  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1r,q2i,q3r,q4i,q5i,x0,p,increment);  vec5 = vec5+(-1i)*multilinear5(odefile,[],q1r,q2r,q3i,q4i,q5i,x0,p,increment);% four imaginary, and five  vec5 = vec5+(+1)*multilinear5(odefile,[],q1r,q2i,q3i,q4i,q5i,x0,p,increment);  vec5 = vec5+(+1)*multilinear5(odefile,[],q1i,q2r,q3i,q4i,q5i,x0,p,increment);  vec5 = vec5+(+1)*multilinear5(odefile,[],q1i,q2i,q3r,q4i,q5i,x0,p,increment);  vec5 = vec5+(+1)*multilinear5(odefile,[],q1i,q2i,q3i,q4r,q5i,x0,p,increment);  vec5 = vec5+(+1)*multilinear5(odefile,[],q1i,q2i,q3i,q4i,q5r,x0,p,increment);  vec5 = vec5+(1i)*multilinear5(odefile,[],q1i,q2i,q3i,q4i,q5i,x0,p,increment);end    vec5=nq1*nq2*nq3*nq4*nq5*vec5;%----------------------------------------------------% Computing the fifth order directional derivative w.r.t. vqfunction tempvec = Evvvvv(odefile,vq,x0,p,increment)  f1 = x0 + 5.0*increment*vq;  f2 = x0 + 3.0*increment*vq;  f3 = x0 + 1.0*increment*vq;  f4 = x0 - 1.0*increment*vq;  f5 = x0 - 3.0*increment*vq;  f6 = x0 - 5.0*increment*vq;  f1 = feval(odefile, 0, f1, p{:});  f2 = feval(odefile, 0, f2, p{:});  f3 = feval(odefile, 0, f3, p{:});  f4 = feval(odefile, 0, f4, p{:});  f5 = feval(odefile, 0, f5, p{:});  f6 = feval(odefile, 0, f6, p{:});  tempvec =  (f1 - 5.0*f2 + 10.0*f3 - 10.0*f4 + 5.0*f5 - f6)/((2*increment)^5); %----------------------------------------------------%Scaling q to vector with norm 1, or keep q if smaller to improve accuracy.function [nq,q_scaled]=vecscale(q)  if (norm(q)>1)    nq=norm(q);    q_scaled=q/nq;  else    nq=1;    q_scaled=q;  end