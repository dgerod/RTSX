// =====================================================================
// FKine.sci - Computes direct/forward kinematics of a robot
// www.controlsystemslab.com   July 2012
// =====================================================================

function T = _fkine (robot,q)
// Usage T = FKine(robot,q) where robo is a robot structure created
// by SerialLink(), and q is a joint variable vector
// FKine() simply calls Link2AT()
// q can be a set of trajectory. In this case, FKine() returns a 
// multi-dimensional matrix 
//

    L=robot.Link;
    Tb=robot.base;
    Tt=robot.tool;
    nlinks=size(L,1);    // number of links 
   
    if nlinks~=size(q,2) then
          error("Numbers of links and joint variables do not match.")
    end  
    for i=1:size(q,1) 
        [A,Ti]=Link2AT(L,q(i,:));
        T(:,:,i)=clean(Tb*Ti*Tt);
     end
endfunction

// ---------------------------------------------------------------------

FKine = _fkine;
fkine = _fkine;
dirkinem = _fkine;
fwdkinem = _fkine;

// =====================================================================
