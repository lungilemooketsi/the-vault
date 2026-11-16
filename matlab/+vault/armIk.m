function q = armIk(tip, gamma)
if nargin < 2
  gamma = -pi / 2;
end
L = vault.armLengths();
yaw = atan2(tip(2), tip(1));
if hypot(tip(1), tip(2)) < 1e-9
  yaw = 0;
end
wrist = tip - L(4) * [cos(yaw) * cos(gamma), sin(yaw) * cos(gamma), sin(gamma)];
radius = hypot(wrist(1), wrist(2));
z = wrist(3) - L(1);
c3 = (radius * radius + z * z - L(2) * L(2) - L(3) * L(3)) / (2 * L(2) * L(3));
c3 = max(-1, min(1, c3));
elbow = atan2(-sqrt(max(0, 1 - c3 * c3)), c3);
k1 = L(2) + L(3) * cos(elbow);
k2 = L(3) * sin(elbow);
shoulder = atan2(z, radius) - atan2(k2, k1);
wristJoint = gamma - shoulder - elbow;
q = [yaw, shoulder, elbow, wristJoint];
end
