clear,clc;
close all;

T_total = 20;       %Observation time s
T= 0.5;             %Data rate = 0.1s
N = T_total/T;
t = 0.5:T:T_total;
M = 50;              %Monto-carlo time
%Motion parameters
R0 = 80;  %km
v0 = 0.8; %km/s
v1 = -0.4; %km/s
a0 = 0;
a1 = 0.5; %km/s2
%noise
sigma_x = sqrt(0.1);     %�������� / ״̬���� ��ƽ�����˴�Ϊ�ٶȲ���
sigma_z = sqrt(0.05);    %��������������ƽ������˹��

%% Kalman filter CV 1-dimension

%-------Kalman Parameters-------%
R = sigma_z^2;
P = [R   R/T     
     R/T 2*R/T^2 ];
F = [1 T 
     0 1];%״̬ת�ƾ���
H = [1 0];%�������
%���ڸ���ʵ�ʹ켣��ת�ƾ���
F_track = [1 T T^2/2
           0 1 T
           0 0 1];
%��������
B = [T^2/2; T]; %���������ֲ�����
v = sigma_x^2;   %x����Ĺ�����������//�൱��Q
V = B * v * B';
% %�۲�����??
% W = B * noise_x;

%------Data initial-------%
X_real = zeros(3,N);
X = zeros(2,N);
Z = zeros(1,N);
X_filter = zeros(2,N);
bias = zeros(2,N,M);
gain = zeros(2,N,M);
Cov = zeros(2,N,M);
%��ʼʱ��1,x��λ�ú��ٶ�

%-------Track Initial-------%
%flag=1,Track1;flag=2,Track2;flag=3,Track3
flag = 3; 
if flag == 3
    a = a1;
else
    a = a0;
end
X_real(:,1) = [R0, v0, a]'; %x: km,km/s
X(:,1) = X_real(1:2,1);
Z(:,1) = X_real(1,1);
X_filter(:,1) = X_real(1:2,1);


%Monto-carlo

for m=1:M
    
    noise_x = randn(1,N).*sigma_x; %��������
    noise_z = randn(1,N).*sigma_z; %�۲�����
    
    %���� ��ʵ�켣X �� �۲�켣Z //flag = 1һ���ٶȸı����
    for n=2:N
        if flag == 2 && n == 16
            X_real(2,n-1) = v1;
        end
        X_real(:,n) = F_track * X_real(:,n-1);
    end
    X = X_real(1:2,:)+ B * noise_x;
    Z = H * X + noise_z;
    
    %P_update(:,1) = P;
    for n=2:N
        x_predict = F * X_filter(:,n-1);                       %״̬һ��Ԥ��
        p_predict = F * P * F'+ V;                             %Э����һ��Ԥ��
        S = H * p_predict * H'+ R;                             %��ϢЭ����
        K = p_predict * H'/ S ;                                  %����
        X_filter(:,n) = x_predict + K * (Z(:,n) - H * x_predict);  %״̬���·���
        P = (eye(2)-K*H) * p_predict * (eye(2)+K*H)'- K*R*K';  %Э������·��� %����һ��Ҫ��Ҫ��
        
        gain(:,n,m) = K;
        Cov(1,n,m) = P(1,1);
        Cov(2,n,m) = P(2,2);
    end
    bias(:,:,m) = X - X_filter;
end
Bias = sum(bias.^2 , 3) / M;
RMSE = sqrt(sum(bias.^2 , 3)/M);
gain_avg = sum(gain,3)/M;
Cov_avg = sum(Cov,3)/M;

%% Draw the Result
figure;
hold on;grid on;
plot(t, X(1,:),'LineWidth',1.5);
plot(t, X_filter(1,:),'LineWidth',1.5);
plot(t, Z(1,:),'.-');
legend('Real track','Filtered track','Observed track');
xlabel('t/s');ylabel('x/km');title('Range filtering track');

figure;
hold on;grid on;
plot(t, X(2,:),'LineWidth',1.5);
plot(t, X_filter(2,:),'LineWidth',1.5);
%ylim([0,1.5]);
legend('Real track','Filtered track');
xlabel('t/s');ylabel('v km/s');title('Velocity filtering track');

figure;
grid on;hold on;
plot(t,Bias(1,:),'LineWidth',1.5);
plot(t,Bias(2,:),'LineWidth',1.5);
ylim([0,1.6]);legend('Range','Velocity');
xlabel('t/s');ylabel('Amplitude');title('Bias');

figure;
grid on;hold on;
plot(t,RMSE(1,:),'LineWidth',1.5);
plot(t,RMSE(2,:),'LineWidth',1.5);
ylim([0,1.6]);legend('Range','Velocity');
xlabel('t/s');ylabel('Amplitude');title('RMSE');

figure;
grid on;hold on;
plot(t,gain_avg(1,:),'LineWidth',1.5);
plot(t,gain_avg(2,:),'LineWidth',1.5);
xlabel('t/s');ylabel('Amplitude');legend('Range','Velocity');
title('Gain');
figure;
grid on;hold on;
plot(t,Cov_avg(1,:),'LineWidth',1.5);
plot(t,Cov_avg(2,:),'LineWidth',1.5);
xlabel('t/s');ylabel('Amplitude');legend('Range','Velocity');
title('Covariance');


%% Kalman filter CA 1-dimension

%-------Kalman Parameters-------%
%״̬ת�ƾ���
F = [1 T T^2/2
     0 1 T
     0 0 1];
%�������
H = [1 0 0];
%��������
R = sigma_z^2;
%��ʼЭ�������
P = [R       R/T     2*R/T^2 
     R/T     2*R/T^2 3*R/T^3
     2*R/T^2 3*R/T^3 4*R/T^4];
%��������
B = [T^2/2; T; 1]; %���������ֲ�����
v = sigma_x^2;   %x����Ĺ�����������
V = B * v * B'; %�൱��Q

%------Data initial-------%
X_real = zeros(3,N);
X = zeros(3,N);
Z = zeros(1,N);
X_filter = zeros(3,N);
bias = zeros(3,N,M);
gain = zeros(3,N,M);
Cov = zeros(3,N,M);
%��ʼʱ��1,x��λ�ú��ٶ�

%-------Track Initial-------%
%flag=1,Track1;flag=2,Track2;flag=3,Track3
flag = 3; 
if flag == 3
    a = a1;
else
    a = a0;
end
X_real(:,1) = [R0, v0, a]'; %x: km,km/s
X(:,1) = X_real(:,1);
Z(:,1) = X_real(1,1);
X_filter(:,1) = X_real(:,1);

%Monto-carlo
for m=1:M
    
    noise_x = randn(1,N).*sigma_x; %��������
    noise_z = randn(1,N).*sigma_z; %�۲�����
    
    %���� ��ʵ�켣X �� �۲�켣Z //flag = 1һ���ٶȸı����
    for n=2:N
        if flag == 2 && n == 16
            X_real(2,n-1) = v1;
        end
        X_real(:,n) = F * X_real(:,n-1);
    end
    X = X_real + B * noise_x;
    Z = H * X + noise_z;
    
    for n=2:N
        x_predict = F * X_filter(:,n-1);                       %״̬һ��Ԥ��
        p_predict = F * P * F'+ V;                             %Э����һ��Ԥ��
        S = H * p_predict * H'+ R;                             %��ϢЭ����
        K = p_predict * H'/ S ;                                  %����
        X_filter(:,n) = x_predict + K * (Z(:,n) - H * x_predict);  %״̬���·���
        P = (eye(3)-K*H) * p_predict * (eye(3)+K*H)'- K*R*K';  %Э������·��� %����һ��Ҫ��Ҫ��
        gain(:,n,m) = K;
        Cov(1,n,m) = P(1,1);
        Cov(2,n,m) = P(2,2);
        Cov(3,n,m) = P(3,3);
    end
    bias(:,:,m) = X - X_filter;
end
Bias = sum(bias.^2 , 3) / M;
RMSE = sqrt(sum(bias.^2 , 3)/M);
gain_avg = sum(gain,3)/M;
Cov_avg = sum(Cov,3)/M;

%% Draw the Result
figure;
hold on;grid on;
plot(t, X(1,:),'LineWidth',1.5);
plot(t, X_filter(1,:),'LineWidth',1.5);
plot(t, Z(1,:),'.-');
legend('Real track','Filtered track','Observed track');
xlabel('t/s');ylabel('x/km');title('Range filtering track');

figure;
hold on;grid on;
plot(t, X(2,:),'LineWidth',1.5);
plot(t, X_filter(2,:),'LineWidth',1.5);
%ylim([0,1.5]);
legend('Real track','Filtered track');
xlabel('t/s');ylabel('v km/s');title('Velocity filtering track');

figure;
hold on;grid on;
plot(t, X(3,:),'LineWidth',1.5);
plot(t, X_filter(3,:),'LineWidth',1.5);
ylim([-1.5,1.5]);
legend('Real track','Filtered track');
xlabel('t/s');ylabel('a km/s^2');title('Acceleration filtering track');

figure;
grid on;hold on;
plot(t,Bias(1,:),'LineWidth',1.5);
plot(t,Bias(2,:),'LineWidth',1.5);
plot(t,Bias(3,:),'LineWidth',1.5);
ylim([0,0.4]);
legend('Range','Velocity','Acceleration');
xlabel('t/s');ylabel('Amplitude');title('Bias');

figure;
grid on;hold on;
plot(t,RMSE(1,:),'LineWidth',1.5);
plot(t,RMSE(2,:),'LineWidth',1.5);
plot(t,RMSE(3,:),'LineWidth',1.5);
ylim([0,0.8]);
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
