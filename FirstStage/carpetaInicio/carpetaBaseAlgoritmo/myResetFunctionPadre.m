%The reset function sets the cart angle to a random value each time the environment is reset.
function [InitialObservation,LoggedSignals] = myResetFunction %[InitialObservation,LoggedSignals] = myResetFunction

%To pass information from one step to the next, such as the environment state, use LoggedSignals.
%LoggedSignals -> Any data that you want to pass from one step to the next, specified as a structure.

% Return initial environment state variables as logged
% signals.--------------------------------------------
rng('shuffle')
addpath('QNN Toolbox');addpath(genpath('FeatureExtraction'));addpath(genpath('Data'));
addpath(genpath('PreProcessing'));addpath(genpath('testingJSON'));addpath(genpath('trainingJSON'));

%Opcion = 1 (40 features) %Opcion = 2 (46 features) - 1 vector one hot encoding whith previous action
%Opcion = 3 (52 features) - 2 vectors one hot encoding whith previous actions
num_prev_actions=0;    %  CAMBIAR - 0 si no quiero acciones previas en vector de caracteristicas ; 1 hasta N CAMBIAR NUMERO DE ACCIONES PREVIAS a considerar
assignin('base','num_prev_actions',num_prev_actions); 
%Conversion de JSON a .mat (si es necesario)
root_        = pwd;
data_gtr_dir = horzcat(root_,'\Data\General\training');
data_gts_dir = horzcat(root_,'\Data\General\testing');
data_sts_dir = horzcat(root_,'\Data\Specific');
if length(dir(data_gtr_dir))>2 || length(dir(data_gts_dir))>2 || length(dir(data_sts_dir))>2
    % No Data conversion
    disp('Data conversion already done');
else
    % Data conversion needed
    jsontomat;
end
addpath(genpath('Data'));addpath(genpath('PreProcessing'));
root_        = pwd;
data_gtr_dir = horzcat(root_,'\Data\General\training');
data_gts_dir = horzcat(root_,'\Data\General\testing');
data_sts_dir = horzcat(root_,'\Data\Specific');
if length(dir(data_gtr_dir))>2 || length(dir(data_gts_dir))>2 || length(dir(data_sts_dir))>2
    % No Data conversion
    disp('Data conversion already done');
else
    % Data conversion needed
    jsontomat;
end
% Main Code
Stride=40;             %OJO stride debe tener el mismo valor q en func MyStepFunction                 
assignin('base','Stride',  Stride);
WindowsSize=300;       %OJO WindSize debe tener el mismo valor q en func MyStepFunction 
assignin('base','WindowsSize',  WindowsSize);

RepTraining   = 1;                       %solo lee una ventana
on  = true;
off = false;
assignin('base','RepTraining',  RepTraining);
assignin('base','randomGestures',     off);   
assignin('base','noGestureDetection', on); 
assignin('base','rangeValues', 300); %(1-150 /151 -300)
assignin('base','packetEMG',  off);
assignin('base','post_processing',     on);   %on si quiero post procesamiento en vector de etiquetas resultadnte 
%Timer 
%global tic;

%-------------------------------------------------------------------
%Este codigo hace que se rangeDown=1 en la primera iteracion, y luego
%aumenta en 1 hasta que se llega al limite de EMGs de entrenamiento (rangeValues). Luego
%de eso se vuelve a reiniciar a 1 indice de las muestras
global rangeDown
global contador_k2
global rangeDown2
global bandera
global number_classif_ok
global number_classif_failed
global number_recog_ok
global number_recog_failed
global counter_gestos

counter_gestos=0;
assignin('base','counter_gestos', counter_gestos);

%esto es solo para inicializar
try
    evalin('base', 'bandera') 
    LoggedSignals.number_classif_ok=number_classif_ok;
    assignin('base','number_classif_ok', number_classif_ok);
    LoggedSignals.number_classif_failed=number_classif_failed;
    assignin('base','number_classif_failed', number_classif_failed);
    LoggedSignals.number_recog_ok=number_recog_ok;
    assignin('base','number_recog_ok', number_recog_ok);
    LoggedSignals.number_recog_failed=number_recog_failed;
    assignin('base','number_recog_failed', number_recog_failed);
catch 
    LoggedSignals.number_classif_ok=0;
    number_classif_ok=0;
    assignin('base','number_classif_ok', number_classif_ok);
    LoggedSignals.number_classif_failed=0;
    number_classif_failed=0;
    assignin('base','number_classif_failed', number_classif_failed);
    LoggedSignals.number_recog_ok=0;
    number_recog_ok=0;
    assignin('base','number_recog_ok', number_recog_ok);
    LoggedSignals.number_recog_failed=0;
    number_recog_failed=0;
    assignin('base','number_recog_failed', number_recog_failed);
    bandera=1;   
    assignin('base','bandera', bandera);
end

%a) esta parte es para mandar los datos ordenados------------
% try
%    %evalin('base', 'rangeDown')
%    if rangeDown < 300 %rangeValues  
%    rangeDown=rangeDown+1;
%    LoggedSignals.EMGs=rangeDown ;
%    assignin('base','rangeDown', rangeDown);
%    else
%    rangeDown=1;   
%    LoggedSignals.EMGs=rangeDown;
%    assignin('base','rangeDown', rangeDown);
%    end
% catch exception
%    disp("No se ha declarado dicho dato")
%    %global rangeDown
%    rangeDown=1;
%    LoggedSignals.EMGs=rangeDown;
%    assignin('base','rangeDown', rangeDown);
% end

%b) Esta opcion es si quiero que vayan los datos 1, 26, 51, etc.
%se envian datos de un gesto a la vez sin que el gesto se repita

try     
    evalin('base', 'rangeDown2')                %evaluo a ver si existe variable
    disp("IF0")
    rangeDown2=rangeDown2+25;                  %Aumento contado en 25
    assignin('base','rangeDown2', rangeDown2);
catch
    disp("IF0-A")                              %Si no había nada en LoggedSignals.EMGs (1ra vez q leo)
    rangeDown2=1;                              %asigno valor de dato #EMGs = 1
    contador_k2=1;                             %inicializo contador en 1
    assignin('base','rangeDown2', rangeDown2);
end

    %si es mayor a 150, debería regresar al siguiente EMG de no gesto (EMGs+1)
    if rangeDown2 > 150
        disp("IF2")
        contador_k2=contador_k2+1;
        LoggedSignals.contador_k2=contador_k2;
        rangeDown2=contador_k2;
        LoggedSignals.EMGs=rangeDown2;
    end
    
    %Si ya barre todos los 25 gestos de cada uno de los 6 gestos, reinicio
    %nuevamente
    if contador_k2>=26
        disp("IF3")
        rangeDown2=1;
        LoggedSignals.EMGs=rangeDown2;
        contador_k2=1;
        LoggedSignals.contador_k2=contador_k2;
    else
    end

     rangeDown=rangeDown2;
     LoggedSignals.EMGs=rangeDown;
%c) Otra opcion es usar numeros aleatorios para mandar las muestras
% rangeDown = randi([1 300],1,1);% 250
% jpv=randi([1 300]);
% disp(rangeDown)


%%%
%%%



%rangeDown=26;                           %CAMBIAR AQUI------------- EMG #
assignin('base','rangeDown', rangeDown); 
Code_0(rangeDown);

numEpochs=1000;                           %CAMBIAR AQUI---poner lo q se pone en matlab EMG #

dataPacketSize   = evalin('base', 'dataPacketSize');
orientation      = evalin('base', 'orientation');
RepTotalTraining = RepTraining*(dataPacketSize-2);
%
fprintf("Numero de usuarios a testear:%d\n",length(orientation(:,1)));

% Select user to test

%userToSelect     = 'User12';            %CAMBIAR AQUI------------- usuario
userToSelect     = strcat('User', num2str(999));%AQUI
userToSelect     = lower(userToSelect);
fprintf('%s\n',userToSelect);%AQUI
userPos = find(strcmp(orientation(:,1), userToSelect));
assignin('base','userIndex', userPos+2);


% Select windows to analize
init_window=1;
assignin('base','goWindow', init_window);          %CAMBIAR AQUI------------- ventana desde 1 hasta 
assignin('base','modeWindow',  on);

%loops = 1; % numero de veces q repito el juego    % evalin('base', 'num_replays');

    [Numero_Ventanas_GT,EMG_GT,Features_GT,Tiempos_GT,Puntos_GT,Usuario_GT,gestureName_GT,groundTruthIndex_GT,groundTruth_GT] ...
        = Code_1(orientation,dataPacketSize,RepTraining,RepTotalTraining);
    %disp(table2array(Features_GT))
    %disp(Numero_Ventanas_GT)
    
    LoggedSignals.State = table2array(Features_GT)'; %aquí va el estado inicial
    LoggedSignals.Window =init_window-1;
    InitialObservation = table2array(Features_GT)';

%%

%---------------feb------------------------
LoggedSignals.etiquetas_labels_predichas_matrix=strings(42,numEpochs);
%------------------------------------------


    EMG_window_size=WindowsSize;
    
    % GROUND TRUTH - VECTORES DE PUNTOS - VECTORES DE PREDICCION - VECTORES DE TIEMPOS
  cumulativeIterationReward = 0;
  assignin('base','cumulativeIterationReward', cumulativeIterationReward);
   
        %Creo vector con limite derecho de cada ventana----------
        gt_gestures_pts=zeros(1,Numero_Ventanas_GT);
        gt_gestures_pts(1,1)=EMG_window_size;
        for k = 1:Numero_Ventanas_GT-1
            gt_gestures_pts(1,k+1)=gt_gestures_pts(1,k)+Stride;
        end
        %disp('gt_gestures_pts');disp(gt_gestures_pts);
        assignin('base','gt_gestures_pts',gt_gestures_pts);
        LoggedSignals.gt_gestures_pts=gt_gestures_pts;
        
        %Creo vector de etiquetas para Ground truth x ventana--------
        gt_gestures_labels=strings;
        %gt_gestures_labels(1,1)="noGesture";
        for k2 = 1:Numero_Ventanas_GT
            if gt_gestures_pts(1,k2) >= (groundTruthIndex_GT(1,1) + EMG_window_size/5) && gt_gestures_pts(1,k2) <= groundTruthIndex_GT(1,2)
                %disp('case1')
                gt_gestures_labels(1,k2)=string(gestureName_GT);
            elseif  gt_gestures_pts(1,k2)-EMG_window_size <= (groundTruthIndex_GT(1,2)-EMG_window_size/5 ) && gt_gestures_pts(1,k2) >= groundTruthIndex_GT(1,2)
                %Considero 1/5 el tamaño de la ventana
                %disp('case2')
                gt_gestures_labels(1,k2)=string(gestureName_GT);
            else
                %disp('case3')
                gt_gestures_labels(1,k2)="noGesture";
            end
        end
        %disp('gt_gestures_labels');disp(gt_gestures_labels);
        assignin('base','gt_gestures_labels',gt_gestures_labels);
        LoggedSignals.gt_gestures_labels=gt_gestures_labels;
        
        %Creo vector de etiquetas de Ground truth con valores numericos----
        gt_gestures_labels_num=zeros(Numero_Ventanas_GT-1,1);
        %gt_gestures_labels_num(1,1)=6;
        for k3 = 1:Numero_Ventanas_GT
            if gt_gestures_labels(1,k3) == "waveOut"
                gt_gestures_labels_num(k3,1)=1;
            elseif gt_gestures_labels(1,k3) == "waveIn"
                gt_gestures_labels_num(k3,1)=2;        %CAMBIAR
            elseif gt_gestures_labels(1,k3) == "fist"
                gt_gestures_labels_num(k3,1)=3 ;         %CAMBIAR
            elseif gt_gestures_labels(1,k3) == "open"
                gt_gestures_labels_num(k3,1)=4;         %CAMBIAR
            elseif gt_gestures_labels(1,k3) == "pinch"
                gt_gestures_labels_num(k3,1)=5;       %CAMBIAR
            elseif gt_gestures_labels(1,k3) == "noGesture"
                gt_gestures_labels_num(k3,1)=6;        %CAMBIAR
            end
        end
        %disp('gt_gestures_labels_num');disp(gt_gestures_labels_num);
        assignin('base','gt_gestures_labels_num',gt_gestures_labels_num);
        LoggedSignals.gt_gestures_labels_num=gt_gestures_labels_num;
        %----------------------------------------------

    
    %-----------------------------------------------------------------------------------
    window_n=init_window;                               %ESTA VAR ********
    assignin('base','window_n',window_n);
    Vector_EMG_Tiempos_GT=zeros(1,Numero_Ventanas_GT); %creo vector de tiempos de gt
%     assignin('base','Vector_EMG_Tiempos_GT',Vector_EMG_Tiempos_GT);
%     LoggedSignals.Vector_EMG_Tiempos_GT=Vector_EMG_Tiempos_GT;
    Vector_EMG_Puntos_GT=zeros(1,Numero_Ventanas_GT);  %creo vector de puntos de gt
%     assignin('base','Vector_EMG_Puntos_GT',Vector_EMG_Puntos_GT);
%     LoggedSignals.Vector_EMG_Puntos_GT=Vector_EMG_Puntos_GT;
    Vector_EMG_Tiempos_GT(1,window_n)=Tiempos_GT;      %copio primer valor en vector de tiempos de gt
    assignin('base','Vector_EMG_Tiempos_GT',Vector_EMG_Tiempos_GT);
    LoggedSignals.Vector_EMG_Tiempos_GT=Vector_EMG_Tiempos_GT;
    Vector_EMG_Puntos_GT(1,window_n)=Puntos_GT;        %copio primer valor en vector de tiempos de gt
    assignin('base','Vector_EMG_Puntos_GT',Vector_EMG_Puntos_GT);
    LoggedSignals.Vector_EMG_Puntos_GT=Vector_EMG_Puntos_GT;
    Rewards_clasif=zeros(1,Numero_Ventanas_GT); %creo vector de tiempos de gt
    assignin('base','Rewards_clasif',Rewards_clasif);
    LoggedSignals.Rewards_clasif=Rewards_clasif;
    %---- Defino estado inicial en base a cada ventana EMG  -----------------------------------------------------*
    %state = rand(1, 40);
    state =table2array(Features_GT)';           %Defino ESTADO inicial
    assignin('base','state',state);
    %disp('initial state')
    
    %---------------feb----------------------
    prev_action_0=zeros(1, num_prev_actions*6);
    assignin('base','prev_action_0',prev_action_0);
    if num_prev_actions>0
        state=[state prev_action_0];
        assignin('base','state',state);
    end
    %---------------------------------------

    % ---- Inicializo variables requeridas para guardar datos de prediccion
    etiquetas = gt_gestures_labels_num; %1+round((5)*rand(Numero_Ventanas_GT,1));   %1+round((5)*rand(maxWindowsAllowed,1)); %%%%%%%% AQUI PONER ground truth de cada ventana EMG - gestos de 1 a 6
    assignin('base','etiquetas',etiquetas);
    LoggedSignals.etiquetas=etiquetas;
    etiquetas_labels_predichas_vector=strings;
    assignin('base','etiquetas_labels_predichas_vector',etiquetas_labels_predichas_vector);
    LoggedSignals.etiquetas_labels_predichas_vector=etiquetas_labels_predichas_vector;
    etiquetas_labels_predichas_vector_without_NoGesture=strings;
    assignin('base','etiquetas_labels_predichas_vector_without_NoGesture',etiquetas_labels_predichas_vector_without_NoGesture);
    LoggedSignals.etiquetas_labels_predichas_vector_without_NoGesture=etiquetas_labels_predichas_vector_without_NoGesture;
    acciones_predichas_vector = zeros(Numero_Ventanas_GT,1);%zeros(maxWindowsAllowed,1);         %%%%%%%%   EN ESTE VECTOR VAN A IR LAS ACCIONES PREDICHAS, LAS
    assignin('base','acciones_predichas_vector',acciones_predichas_vector);
    LoggedSignals.acciones_predichas_vector=acciones_predichas_vector;
    % ---- inicializo parametros medicion tiempo, y vectores de prediccion
    % necesarios para evaluar reconocimiento en cada epoca -----------------
    ProcessingTimes_vector=[];
    assignin('base','ProcessingTimes_vector',ProcessingTimes_vector);
    LoggedSignals.ProcessingTimes_vector=ProcessingTimes_vector;
    TimePoints_vector=[];
    assignin('base','TimePoints_vector',TimePoints_vector);
    LoggedSignals.TimePoints_vector=TimePoints_vector;
    n1=0;
    assignin('base','n1',n1);
    etiquetas_labels_predichas_vector_simplif=strings;
    assignin('base','etiquetas_labels_predichas_vector_simplif',etiquetas_labels_predichas_vector_simplif);
    LoggedSignals.etiquetas_labels_predichas_vector_simplif=etiquetas_labels_predichas_vector_simplif;
    %----------------------------------------------------------------

        % Interaction of agent with the world
    gameOn = true;                                               % Indicator of reaching a final state
    assignin('base','gameOn',gameOn);
    cumulativeGameReward = 0;                                    % Inicializo reward acumulado
    assignin('base','cumulativeGameReward',cumulativeGameReward);
    numIteration = 0;                                            % Inicializo  numIteration
    assignin('base','numIteration',numIteration);

    %maxNumSteps = 10;
    stepNum = 0;
    assignin('base','stepNum',stepNum);
    
    global conta
    
    try
        evalin('base', 'conta')                %evaluo a ver si existe variable
        conta=1+conta;
        disp(conta)
        LoggedSignals.conta=conta;
    catch
        conta=1;
        LoggedSignals.conta=conta;
        assignin('base','conta', conta);
    end
    
    
%     if exist('conta','var')
%         conta=1+conta;
%         LoggedSignals.conta=conta;
%     else
%         conta=1;
%         LoggedSignals.conta=conta;
%     end
    
    LoggedSignals.gestureName_GT=gestureName_GT;
    LoggedSignals.groundTruth_GT=groundTruth_GT;
end

