function info = tryRigidBodyTree()
% Builds a 4-joint rigidBodyTree when Robotics System Toolbox is present
% and checks the wrist frame against the DH forward kinematics.
info.available = false;
info.matched = false;
info.backend = 'dh';
info.tipError = NaN;
if exist('rigidBodyTree', 'class') == 0 && exist('rigidBodyTree', 'file') == 0
  return;
end
info.available = true;
info.backend = 'rigidBodyTree';
robot = rigidBodyTree('DataFormat', 'column');
lengths = vault.armLengths();
names = {'base', 'shoulder', 'elbow', 'wrist'};
joints = {'revolute', 'revolute', 'revolute', 'revolute'};
axes = [0 0 1; 0 1 0; 0 1 0; 0 1 0];
parents = {'base', 'base_link', 'base', 'shoulder'};
% The DH model remains the one the demo animates. This block records that
% the toolbox object can be constructed on a licensed machine.
info.bodies = numel(names);
info.jointCount = numel(joints);
info.linkLengths = lengths;
info.axes = axes;
info.note = 'DH kinematics drive the slice. rigidBodyTree is constructed when the toolbox exists.';
if exist('rigidBody', 'class') == 0 && exist('rigidBody', 'file') == 0
  return;
end
previous = robot.BaseName;
for i = 1:numel(names)
  body = rigidBody(names{i});
  joint = rigidBodyJoint(['j' names{i}], joints{i});
  if size(axes, 1) >= i
    joint.JointAxis = axes(i, :);
  end
  setFixedTransform(joint, trvec2tform([0 0 lengths(min(i, numel(lengths)))]));
  body.Joint = joint;
  addBody(robot, body, previous);
  previous = names{i};
end
home = vault.armPose('home');
config = home.q(:);
tform = getTransform(robot, config, names{end});
toolboxTip = tform(1:3, 4).';
info.tipError = norm(toolboxTip - home.tip);
info.matched = info.tipError < 0.05;
info.robot = robot;
end
