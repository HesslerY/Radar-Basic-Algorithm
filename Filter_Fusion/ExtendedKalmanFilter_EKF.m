%% Extend Kalman Filter (EKF) 2d

clear,clc;
close all;

T_total = 200;       %Observation time s
T= 0.5;             %Data rate = 0.1s
N = T_total/T;
t = 0.5:T:T_total;
M = 50;              %Monto-carlo time
%Motion parameters
Rx = 10;
Ry = -5;
vx = -0.2;
vy = 0.2;

Rx_e = 5;
Ry_e = 5;
vx_e = 0;
vy_e = 0;
R0 = sqrt(Rx_e^2+Ry_e^2);
beta0 = atan2(Ry_e,Rx_e);

%�۲�վ��λ��
x0=0;
y0=0;

%noise
sigma_u = sqrt(0.0001);     %��������
sigma_R = sqrt(0.1);        %������������
sigma_beta = sqrt(0.01);    %�Ƕ���������

%% Kalman filter CV 2D

%-------Kalman Parameters-------%

A = [cos(beta0) -R0*sin(beta0); sin(beta0) R0*cos(beta0)] ;
R = A*[sigma_R^2 0;0 sigma_beta^2]*A' ;
P = [R(1,1)   R(1,1)/T     R(1,2)   R(1,2)/T
     R(1,1)/T 2*R(1,1)/T^2 R(1,2)/T 2*R(1,2)/T^2
     R(1,2)   R(1,2)/T     R(2,2)   R(2,2)/T
     R(1,2)/T 2*R(1,2)/T^2 R(2,2)/T 2*R(2,2)/T^2 ];
%״̬ת�ƾ���
F = [1 T 0 0 
     0 1 0 0
     0 0 1 T
     0 0 0 1];
%�������
% H = [1 0 0 0 
%      0 0 1 0];

%��������
B = [T^2/2, 0; T, 0;
     0, T^2/2; 0, T]; %���������ֲ�����
v = sigma_u^2;   %x����Ĺ�����������//�൱��Q
V = B * v * B';
% %�۲�����??
% W = B * noise_x;

%------Data initial-------%
X_real = zeros(4,N);
X = zeros(4,N);
Z = zeros(2,N);
Z_polar = zeros(2,N);
X_EKF = zeros(4,N);
bias = zeros(2,N,M);
gain = zeros(2,N,M);
Cov = zeros(2,N,M);
%��ʼʱ��1,x��λ�ú��ٶ�

%-------Track Initial-------%
X_real(:,1) = [Rx, vx, Ry, vy]'; %x: km,km/s
X(:,1) = X_real(:,1);

X_EKF(:,1) = [5, 0, 5, 0];

%Monto-carlo
for m=1:M
    noise_u = randn(2,N).*sigma_u;
    noise_R = randn(1,N).*sigma_R; %��������
    noise_beta = randn(1,N).*sigma_beta; %�۲�����
    
    %���� ��ʵ�켣X �� �۲�켣Z //flag = 1һ���ٶȸı����
    for n=2:N
        X_real(:,n) = F * X_real(:,n-1);
    end
    X = X_real + B * noise_u;
    
    for n=1:N
        Z_polar(1,n) = sqrt((X(1,n)-x0)^2 +(X(3,n)-y0)^2) + noise_R(n);
        Z_polar(2,n) = atan2((X(3,n)-y0),(X(1,n)-x0)) + noise_beta(n);
        [Z(1,n),Z(2,n)]= pol2cart(Z_polar(2,n), Z_polar(1,n));
    end

    for n=2:N
        x_predict = F * X_EKF(:,n-1);                       %״̬һ��Ԥ��
        p_predict = F * P * F'+ V;                             %Э����һ��Ԥ��
        r = sqrt((x_predict(1)-x0)^2 +(x_predict(3)-y0)^2);
        theta = atan2(x_predict(3),x_predict(1));
        %����ſ˱Ⱦ���H	
        H=[(x_predict(1)-x0)/r,0,0,0;0,0,(x_predict(3)-y0)/r,0];        %̩��չ����һ�׽���
        Hj =[(x_predict(1)-x0)/r,0,(x_predict(3)-y0)/r,0
             -(x_predict(3)-y0)/r^2,0,(x_predict(1)-x0)/r^2,0];
        Fx = [r;theta];
        S = Hj * p_predict * Hj'+ R;                             %��ϢЭ����
        K = p_predict * Hj'/ S ;                                  %����
        X_EKF(:,n) = x_predict + K * (Z_polar(:,n) - Fx);  %״̬���·���
        P = (eye(4)-K*Hj) * p_predict;  %Э������·��� %����һ��Ҫ��Ҫ��
    end
    bias(1,:,m) = sqrt(X(1,:).^2 +X(3,:).^2) - sqrt(X_EKF(1,:).^2 +X_EKF(3,:).^2);
    bias(2,:,m) = sqrt(X(2,:).^2 +X(4,:).^2) - sqrt(X_EKF(2,:).^2 +X_EKF(4,:).^2);
end
Bias = sum(bias.^2 , 3) / M;
RMSE = sqrt(sum(bias.^2 , 3)/M);

%% Draw the Result
figure;
hold on;grid on;
p1=plot(X_real(1,:),X_real(3,:),'k');
p2=plot(X(1,:),X(3,:),'LineWidth',1.5);
plot(X(1,1),X(3,1),'pb');
p3=plot(X_EKF(1,:),X_EKF(3,:),'LineWidth',1.5);
plot(X_EKF(1,1),X_EKF(3,1),'pr');
p4=plot(Z(1,:),Z(2,:),'.-');
legend([p1,p2,p3,p4],{'Ideal track','Real track','Filtered track','Observed track'});
xlabel('x ');ylabel('y ');title('\fontsize{12} Range filtering track');

figure;
hold on;grid on;
plot(X_real(2,:),X_real(4,:),'k');
plot(t, X(2,:),'LineWidth',1.5);
plot(t, X_EKF(2,:),'LineWidth',1.5);
%ylim([0,1.5]);
legend('Real track','Filtered track');
xlabel('t/s');ylabel('v km/s');title('\fontsize{12} Velocity filtering track');

figure;
grid on;hold on;
plot(Bias(1,end-200:end),'LineWidth',1.5);
plot(Bias(2,end-200:end),'LineWidth',1.5);
%ylim([0,0.4]);legend('Range','Velocity');
xlabel('t/s');ylabel('Amplitude');title('Bias');

figure;
grid on;hold on;
plot(t(end-50:end),RMSE(1,end-50:end),'LineWidth',1.5);
plot(t(end-50:end),RMSE(2,end-50:end),'LineWidth',1.5);
%ylim([0,1]);legend('Range','Velocity');
xlabel('t/s');ylabel('Amplitude');title('RMSE');


%% EKF Track Fusion 2D
% 
% clear,clc;
% close all;

T_total = 200;       %Observation time s
T= 1;             %Data rate = 0.1s
N = T_total/T;
t = 1:T:T_total;
M = 1;              %Monto-carlo time
%Motion parameters
Rx = 50;
Ry = -100;
vx = -1;
vy = 2;

%�۲�վ��λ��
x0=0;
y0=0;

Rx_e = 50;
Ry_e = -100;
vx_e = 0;
vy_e = 0;
R0 = sqrt((Rx_e-x0)^2+(Ry_e-y0)^2);
beta0 = atan2((Ry_e-y0),(Rx_e-x0));


%noise
sigma_u = sqrt(0.0001);     %��������
sigma_R = sqrt(5);        %������������
sigma_beta = sqrt(0.01);    %�Ƕ���������

% Kalman filter CV 2D

%-------Kalman Parameters-------%

A = [cos(beta0) -R0*sin(beta0); sin(beta0) R0*cos(beta0)] ;
R = A*[sigma_R^2 0;0 sigma_beta^2]*A' ;
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
% H = [1 0 0 0 
%      0 0 1 0];

%��������
B = [T^2/2, 0; T, 0;
     0, T^2/2; 0, T]; %���������ֲ�����
v = sigma_u^2;   %x����Ĺ�����������//�൱��Q
V = B * v * B';
% %�۲�����??
% W = B * noise_x;

%------Data initial-------%
X_real = zeros(4,N);
X = zeros(4,N);
Z = zeros(2,N);
Z_polar = zeros(2,N);
X_EKF = zeros(4,N);
bias = zeros(2,N,M);
gain = zeros(2,N,M);
Cov = zeros(2,N,M);
%��ʼʱ��1,x��λ�ú��ٶ�

%-------Track Initial-------%
X_real(:,1) = [Rx, vx, Ry, vy]'; %x: km,km/s
X(:,1) = X_real(:,1);

X_EKF(:,1) = [Rx_e, 0, Ry_e, 0];

%Monto-carlo
for m=1:M
    noise_u = randn(2,N).*sigma_u;
    noise_R = randn(1,N).*sigma_R; %��������
    noise_beta = randn(1,N).*sigma_beta; %�۲�����
    
    %���� ��ʵ�켣X �� �۲�켣Z //flag = 1һ���ٶȸı����
    for n=2:N
        if n == 30
            X_real(2,n-1) = 1;
        end
        X_real(:,n) = F * X_real(:,n-1);
    end
    X = X_real + B * noise_u;
    
    for n=1:N
        Z_polar(1,n) = sqrt((X(1,n)-x0)^2 +(X(3,n)-y0)^2) + noise_R(n);%��ʵ���״�������
        Z_polar(2,n) = atan2((X(3,n)-y0),(X(1,n)-x0)) + noise_beta(n);
        [Z(1,n),Z(2,n)]= pol2cart(Z_polar(2,n), Z_polar(1,n)); %������ͼ
    end

    for n=2:N
        x_predict = F * X_EKF(:,n-1);                       %״̬һ��Ԥ��
        p_predict = F * P * F'+ V;                             %Э����һ��Ԥ��
        r = sqrt((x_predict(1)-x0)^2 +(x_predict(3)-y0)^2);
        theta = atan2((x_predict(3)-y0),(x_predict(1)-x0));
        %����ſ˱Ⱦ���H	
        H=[(x_predict(1)-x0)/r,0,0,0;0,0,(x_predict(3)-y0)/r,0];        %̩��չ����һ�׽���
        Hj =[(x_predict(1)-x0)/r,0,(x_predict(3)-y0)/r,0
             -(x_predict(3)-y0)/r^2,0,(x_predict(1)-x0)/r^2,0];
        Fx = [r;theta];
        S = Hj * p_predict * Hj'+ R;                             %��ϢЭ����
        K = p_predict * Hj'/ S ;                                  %����
        X_EKF(:,n) = x_predict + K * (Z_polar(:,n) - Fx);  %״̬���·���
        P = (eye(4)-K*Hj) * p_predict;  %Э������·��� %����һ��Ҫ��Ҫ��
    end
    bias(1,:,m) = sqrt(X(1,:).^2 +X(3,:).^2) - sqrt(X_EKF(1,:).^2 +X_EKF(3,:).^2);
    bias(2,:,m) = sqrt(X(2,:).^2 +X(4,:).^2) - sqrt(X_EKF(2,:).^2 +X_EKF(4,:).^2);
end
Bias = sum(bias.^2 , 3) / M;
RMSE = sqrt(sum(bias.^2 , 3)/M);

%% Draw the Result
figure;
hold on;grid on;
p2=plot(X(1,:),X(3,:),'LineWidth',1.5);
p3=plot(X_EKF(1,:),X_EKF(3,:),'LineWidth',1.5);
legend([p2,p3],{'Real track','Filtered track 0'});
xlabel('x ');ylabel('y ');title('\fontsize{12} Range filtering track');

%%
hold on;
p3=plot(X_EKF(1,:),X_EKF(3,:),'LineWidth',1.5);
legend([p3],{'Filtered track 1'});
%%
figure;
hold on;grid on;
plot(t, X(1,:),'LineWidth',1.5);
plot(t, X_EKF(1,:),'LineWidth',1.5);
plot(t, Z(1,:),'.-');
legend('Real track','Observed track','Filtered track');
xlabel('t/s');ylabel('x/km');title('Range filtering track');

figure;
hold on;grid on;
plot(t, X(2,:),'LineWidth',1.5);
plot(t, X_EKF(2,:),'LineWidth',1.5);
%ylim([0,1.5]);
legend('Real track','Filtered track');
xlabel('t/s');ylabel('v km/s');title('Velocity filtering track');

figure;
hold on;grid on;
plot(t, X(3,:),'LineWidth',1.5);
plot(t, X_EKF(3,:),'LineWidth',1.5);
ylim([-1.5,1.5]);
legend('Real track','Filtered track');
xlabel('t/s');ylabel('a km/s^2');title('Acceleration filtering track');

figure;
grid on;hold on;
plot(t,Bias(1,:),'LineWidth',1.5);
plot(t,Bias(2,:),'LineWidth',1.5);
plot(t,Bias(3,:),'LineWidth',1.5);
%ylim([0,0.4]);
legend('Range','Velocity','Acceleration');
xlabel('t/s');ylabel('Amplitude');title('Bias');

figure;
grid on;hold on;
plot(t,RMSE(1,:),'LineWidth',1.5);
plot(t,RMSE(2,:),'LineWidth',1.5);
plot(t,RMSE(3,:),'LineWidth',1.5);
%ylim([0,0.8]);
legend('Range','Velocity','Acceleration');
xlabel('t/s');ylabel('Amplitude');title('RMSE');

figure;
grid on;hold on;
plot(t,gain_avg(1,:),'LineWidth',1.5);
plot(t,gain_avg(2,:),'LineWidth',1.5);
plot(t,gain_avg(3,:),'LineWidth',1.5);
legend('Range','Velocity','Acceleration');
xlabel('t/s');ylabel('Amplitude');title('Gain');

figure;
grid on;hold on;
plot(t,Cov_avg(1,:),'LineWidth',1.5);
plot(t,Cov_avg(2,:),'LineWidth',1.5);
plot(t,Cov_avg(3,:),'LineWidth',1.5);
legend('Range','Velocity','Acceleration');
xlabel('t/s');ylabel('Amplitude');title('Covariance');
