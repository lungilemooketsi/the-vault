function pose = armPose(name)
switch name
  case 'home'
    pose.q = [0, -pi / 2, pi / 2, 0];
    pose.locked = false;
  case 'lock'
    pose.q = [0, -2.4, 2.6, -0.8];
    pose.locked = true;
  case 'pick'
    pose.q = vault.armIk([0.26, 0.00, 0.12]);
    pose.locked = false;
  case 'place'
    pose.q = vault.armIk([0.22, 0.10, 0.14]);
    pose.locked = false;
  otherwise
    error('vault:arm:pose', 'Unknown arm pose.');
end
pose.name = name;
pose.tip = vault.armFk(pose.q);
end
