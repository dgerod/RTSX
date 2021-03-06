// maniplty.sci Manipulability measure
// M = maniplty(robot, Q, OPTIONS) is the manipulability index measure for the robot
// at the joint configuration Q.  It indicates dexterity, that is, how isotropic 
// the robot's motion is with respect to the 6 degrees of Cartesian motion.
// The measure is high when the manipulator is capable of equal motion in all
// directions and low when the manipulator is close to a singularity.
//
// If Q is a matrix (MxN) then M (Mx1) is a vector of  manipulability 
// indices for each pose specified by a row of Q.
//
// [M,CI] = maniplty(robot, Q, OPTIONS) as above, but for the case of the Asada
// measure returns the Cartesian inertia matrix CI.
//
// Two measures can be selected:
// - Yoshikawa's manipulability measure is based on the shape of the velocity
//   ellipsoid and depends only on kinematic parameters.
// - Asada's manipulability measure is based on the shape of the acceleration
//   ellipsoid which in turn is a function of the Cartesian inertia matrix and
//   the dynamic parameters.  The scalar measure computed here is the ratio of 
//   the smallest/largest ellipsoid axis.  Ideally the ellipsoid would be 
//   spherical, giving a ratio of 1, but in practice will be less than 1.
//
// Options::
// 'T'           manipulability for transational motion only
// 'R'           manipulability for rotational motion only
// 'yoshikawa'   use Yoshikawa algorithm (default)
// 'asada'       use Asada algorithm
//
// Notes::
// - By default the measure includes rotational and translational dexterity, but
//   this involves adding different units.  It can be more useful to look at the
//   translational and rotational manipulability separately.
//
// References::
//
// - Analysis and control of robot manipulators with redundancy,
//   T. Yoshikawa,
//   Robotics Research: The First International Symposium (M. Brady and R. Paul, eds.),
//   pp. 735-747, The MIT press, 1984.
// - A geometrical representation of manipulator dynamics and its application to 
//   arm design,
//   H. Asada, 
//   Journal of Dynamic Systems, Measurement, and Control,
//   vol. 105, p. 131, 1983.
//
// See also SerialLink.inertia, SerialLink.jacob0.




//
// This file is adapted from The Robotics Toolbox for Matlab (RTB).
// Copyright (C) 1993-2011, by Peter I. Corke 


function [w,mx] = maniplty(robot, q, varargin)

    //opt.method = {'yoshikawa', 'asada'};
    //opt.axes = {'T', 'all', 'R'};
    opt.method = 'yoshikawa';
    opt.axes = 'all';
    nargout = argn(1);
    nargin = argn(2);

    varnum=length(varargin);  // number of arguments
    for iv =1:varnum
        if type(varargin(iv))==10 then  // string
            varargin(iv)=convstr(varargin(iv),'l');   // convert to lower case
        end
        if varargin(iv)=='yoshikawa' | varargin(iv)=='asada' then
            opt.method = varargin(iv);       
        elseif varargin(iv)== 't' | varargin(iv)=='r' | varargin(iv)=='all' then
            opt.axes = varargin(iv);
         end
    end

    dof = [1 1 1 1 1 1];
    select opt.axes
        case 't'
            dof = [1 1 1 0 0 0];
        case 'r'
            dof = [0 0 0 1 1 1];
        case 'all'
            dof = [1 1 1 1 1 1];
    end
    
    //opt.dof = logical(opt.dof);
    opt.dof = [dof(1)==1 dof(2)==1 dof(3)==1 dof(4)==1 dof(5)==1 dof(6)==1];

    if opt.method=='yoshikawa'  //strcmp(opt.method, 'yoshikawa')
        w = zeros(numrows(q),1);
        for i=1:numrows(q)
            w(i) = yoshi(robot, q(i,:), opt);
        end
    elseif opt.method=='asada' //strcmp(opt.method, 'asada')
        w = zeros(numrows(q),1);
        if nargout > 1
            dof = sum(opt.dof);
            MX = zeros(dof,dof,numrows(q));
            for i=1:numrows(q)
                [ww,mm] = asada(robot, q(i,:), opt);
                w(i) = ww;
                MX(:,:,i) = mm;
            end
        else
            for i=1:numrows(q)
                w(i) = asada(robot, q(i,:), opt);
            end
        end
    end

    if nargout > 1
        mx = MX;
    end
endfunction

function m = yoshi(robot, q, opt)
    J = jacob0(robot,q);
    
    J = J(opt.dof,:);
    m = sqrt(det(J * J'));
endfunction

function [m, mx] = asada(robot, q, opt)
    J = jacob0(robot,q);
    
    if rank(J) < 6
        warning('robot is in degenerate configuration')
        m = 0;
        return;
    end

    Ji = pinv(J);
    M = inertia(robot, q);
    Mx = Ji' * M * Ji;
    d = find(opt.dof);
    Mx = Mx(d,d);
    e = real(spec(Mx));
    m = min(e) / max(e);
    
    if nargout > 1
        mx = Mx;
    end
endfunction
