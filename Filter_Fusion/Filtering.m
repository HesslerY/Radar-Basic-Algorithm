%% alpha-beta Filter 2D
T_total = 15;       %Observation time s
T= 0.1;             %Data rate = 0.1s
N = T_total/T;

%noise
sigma = 1;
noise = randn(2,N).*sigma;
%initial data
X = zeros(4,N);
Z = zeros(2,N);
X(:,1) = [0, 5, 0, 10];
Z(:,1) = [X(1,1),X(3,1)];
sigma_error=[1,1];

a = 0.3;                %alpha 0.3-0.5
b = 2*(2-a)-4*sqrt(1-a);%beta, determined by alpha
K = [a, b/T, 0, 0
     0, 0, a, b/T]';           %filter gain
%transition matrix
F = [1 T 0 0 
     0 1 0 0
     0 0 1 T
     0 0 0 1];
%observation matrix
H = [1 0 0 0 
     0 0 1 0];

%real & observed data
for n=2:N
    X(:,n) = F * X(:,n-1);
    Z(:,n) = H * X(:,n) + noise(:,n);
end
figure;
hold on;grid on;
plot(X(1,:),X(3,:),'LineWidth',2);
plot(Z(1,:),Z(2,:),'.-');

X_update = zeros(4,N);
X_update(:,1) = X(:,1); 
%filter
a = [0 0.1 0.3 0.5 1];  

for n=2:N
    X_p = F * X_update(:,n-1);
    Z_p = H * X_p;
    X_update(:,n) = X_p + K*(Z(:,n)-Z_p);
end

plot(X_update(1,:),X_update(3,:));
xlabel('x/m');ylabel('y/m');legend('Real track','Observed track','Filtered track');
title('\fontsize{14}Range filtering track')

figure;
hold on;grid on;
plot(X_real(2,:),'LineWidth',2);
plot(X_update(2,:),'LineWidth',2);

plot(X_real(4,:),'LineWidth',1);
plot(X_update(4,:),'LineWidth',1);
xlabel('N');ylabel('v m/s');legend('Observed track','Filtered track');
title('Range filtering track')

figure;grid on;
plot(abs(X_update(1,:)-X(1,:))./X(1,:));
title('��һ������������');xlabel('����');ylabel('����');
figure;grid on;
plot(abs(X_update(2,:)-X(2,:))./X(2,:));
title('��һ���ٶȸ������');xlabel('����');ylabel('����');

%% Kalman filter 2D
T_total = 30;       %Observation time s
T= 0.1;             %Data rate = 0.1s
N = T_total/T;
%noise
sigma_x = 0.5;     %�������� / ״̬�������˴�Ϊ�ٶȲ���
sigma_z = 1;        %����������������˹��
sigma_theta = 0.1;  %��λ�ǲ�������
sigma_phi = 0.1;    %�����ǲ����������
noise_x = [randn(1,N).*sigma_x;zeros(1,N);randn(1,N).*sigma_x; zeros(1,N)];
noise_z = randn(2,N).*sigma_z;
%initial data
X = zeros(4,N);
X_real = zeros(4,N);
Z = zeros(2,N);
X(:,1) = [1, 5, 1, 10];
X_real(:,1) = X(:,1);
Z(:,1) = [X(1,1),X(3,1)];
%��ʼ��Э������󣬼����ʼtheta=60������ٶȽǵó�
theta0 = pi/3 ;
r = sqrt(X(1,1)^2+X(3,1)^2);
A = [cos(theta0) -r*sin(theta0); sin(theta0) r*cos(theta0)] ;
R = A*[sigma_z^2 0;0 sigma_theta^2]*A' ;%R�ǶԳ���,Ϊ��ʼʱ������������ֱ������ϵ�µ�Э����
%��ʼ��Э�������
P = [R(1,1)   R(1,1)/T     R(1,2)   R(1,2)/T
     R(1,1)/T 2*R(1,1)/T^2 R(1,2)/T 2*R(1,2)/T^2
     R(1,2)   R(1,2)/T     R(2,2)   R(2,2)/T
     R(1,2)/T 2*R(1,2)/T^2 R(2,2)/T 2*R(2,2)/T^2 ];
%P = 100*eye(4);
%״̬ת�ƾ���
F = [1 T 0 0 
     0 1 0 0
     0 0 1 T
     0 0 0 1];
%�������
H = [1 0 0 0 
     0 0 1 0];
%״̬����Э�������ȫ�������ٶ��ϣ�
Q = [0 0 0 0 
     0 sigma_x 0 0 
     0 0 0 0 
     0 0 0 sigma_x ];
%��������Э�������
% R = [sigma_z 0 
%      0 sigma_z ];       
%���������ֲ�����
B = [T^2/2 0
     T     0
     0 T^2/2
     0     T];
v = [sigma_x sigma_x]';%�ֱ���x��y����Ĺ�����������
%��������??
V = B*v;
%�۲�����??
W = 0;

%���� ��ʵ�켣X �� �۲�켣Z
for n=2:N
    X(:,n) = F * X(:,n-1);
    X_real(:,n) = X(:,n) + noise_x(:,n);
    Z(:,n) = H * X_real(:,n) + noise_z(:,n);
end

X_update = zeros(4,N);
X_update(:,1) = X(:,1);
%P_update(:,1) = P;
for n=2:N
     x_predict = F * X_update(:,n-1);                       %״̬һ��Ԥ��
     p_predict = F * P * F'+ Q;                             %Э����һ��Ԥ��
     S = H * p_predict * H'+ R;                             %��ϢЭ����
     K = p_predict * H'/ S;                                  %����
     X_update(:,n) = x_predict+K*(Z(:,n)-H*x_predict);      %״̬���·���
     P = (eye(4)-K*H) * p_predict * (eye(4)+K*H)'- K*R*K';  %Э������·���
end
figure;
hold on;grid on;
plot(X(1,:),X(3,:),'LineWidth',2);
plot(Z(1,:),Z(2,:),'.-');
plot(X_update(1,:),X_update(3,:),'LineWidth',2);
xlabel('x/m');ylabel('y/m');legend('Real track','Observed track','Filtered track');
title('Range filtering track')

figure;
hold on;grid on;
plot(X_real(2,:),'LineWidth',2);
plot(X_update(2,:),'LineWidth',2);

plot(X_real(4,:),'LineWidth',1);
plot(X_update(4,:),'LineWidth',1);
xlabel('N');ylabel('v m/s');legend('Observed track','Filtered track');
title('Range filtering track')


figure;grid on;
plot(abs(X_update(1,:)-X_real(1,:))./X_real(1,:));
title('��һ������������');xlabel('����');ylabel('����');
figure;grid on;
plot(abs(X_update(2,:)-X_real(2,:))./X_real(2,:));
title('��һ���ٶȸ������');xlabel('����');ylabel('����');
% figure;
% hold on;grid on;
% plot(X(1,:),'LineWidth',2);
% plot(Z(1,:),'.-');
% plot(X_update(1,:),'LineWidth',2);
% xlabel('x/m');ylabel('y/m');legend('Real track','Observed track','Filtered track');
% title('Range filtering track')