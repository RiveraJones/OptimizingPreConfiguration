% The custom step function specifies how the environment advances to the
% next state based on a given action.
% This function must have the following signature.
% [Observation,Reward,IsDone,LoggedSignals] = myStepFunction(Action,LoggedSignals)
% To get the new state, the environment applies the dynamic equation to the current state
% stored in LoggedSignals, which is similar to giving an initial condition to a differential
% equation. The new state is stored in LoggedSignals and returned as an output.
%[Observation,Reward,IsDone,LoggedSignals]
function [Observation,Reward,IsDone,LoggedSignals] = myStepFunctionTesting(Action_data,LoggedSignals)
% This function applies the given action to the environment and evaluates
% the system dynamics for one simulation step.

global conta
global results_test_eval
global number_classif_ok
global number_classif_failed
global number_recog_ok
global number_recog_failed
global counter_gestos

temporal=tic;
assignin('base','temporal',  temporal);

% Unpack the state vector from the logged signals.
State = LoggedSignals.State;  %en nuestro caso, el estado no tiene efecto en el sig estado
EMGs = LoggedSignals.EMGs;
Window = LoggedSignals.Window+1; %+1 xq primera ventana es cond inicial 0
LoggedSignals.Window = Window;


addpath('QNN Toolbox');addpath(genpath('FeatureExtraction'));addpath(genpath('Data'));
addpath(genpath('PreProcessing'));addpath(genpath('testingJSON'));addpath(genpath('trainingJSON'));
addpath('Gridworld Toolbox');
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
addpath(genpath('Data')); addpath(genpath('PreProcessing'));
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
Stride=40;            %OJO stride debe tener el mismo valor q en func MyResetFunction
assignin('base','Stride',  Stride);
WindowsSize=300;      %OJO WindSize debe tener el mismo valor q en func MyResetFunction
assignin('base','WindowsSize',  WindowsSize);
RepTraining   = 1;                       %solo lee una ventana
on  = true; off = false;
assignin('base','RepTraining',  RepTraining);
assignin('base','randomGestures',     off);
assignin('base','noGestureDetection', on);
assignin('base','rangeValues', 300);     %(1-150 /151 -300)
assignin('base','packetEMG',  off);
rangeDown= EMGs;  %200;                           %CAMBIAR AQUI------------- EMG #
assignin('base','rangeDown', rangeDown);
Code_0(rangeDown);

dataPacketSize   = evalin('base', 'dataPacketSize');
orientation      = evalin('base', 'orientation');
RepTotalTraining = RepTraining*(dataPacketSize-2);
%
fprintf("Numero de usuarios a testear:%d\n",length(orientation(:,1)));

% Select user to test

Reward_type=on;
assignin('base','Reward_type',on);%on si quiero recompensa -1 x ventana (clasif) y -10 x recog

userToSelect     = 'User12';    %OJO             %CAMBIAR AQUI------------- usuario
userToSelect     = lower(userToSelect);
userPos = find(strcmp(orientation(:,1), userToSelect));
assignin('base','userIndex', userPos+2);

assignin('base','goWindow', Window);          %CAMBIAR AQUI------------- ventana desde 1 hasta
assignin('base','modeWindow',  on);
assignin('base','post_processing',     on);   %on si quiero post procesamiento en vector de etiquetas resultadnte
post_processing      =  evalin('base', 'post_processing');
loops = 1; % numero de veces q repito el juego    % evalin('base', 'num_replays');
% numIterationTotal = 0;
% window_n=0; %contador de numero de ventanas
% conta=1;
% numEpochs  = RepTraining*(dataPacketSize-2);
% etiquetas_labels_predichas_matrix=strings(42,numEpochs);
% countWins=0;
% countLoses=0;
% countWins2=0;
% countLoses2=0;
% number_classif_ok=0;
% number_classif_failed=0;
% knum=0;
% score = 0;

%%

%numero de repeticiones por cada usuario (CAMBIAR SEGUN SE REQUIERA - up to 300)  CAMBIAR CAMBIAR CAMBIAR
RepTotalTraining =  RepTraining*(dataPacketSize-2);
numEpochs  = RepTraining*(dataPacketSize-2);  %numero total de carpetas de muestra de todos los usuarios

s2 = '1';                   %CAMBIAR # de EXPERIMENTO
s1 = 'QNN_Trained_Model_';
assignin('base','s2', s2);
s3 = '.mat';
s = strcat(s1,s2,s3);
%----------------------------------------------------

EMG_window_size = evalin('base', 'WindowsSize');                                                %AQUI PONER WINDOW SIZE
Stride = evalin('base', 'Stride');
% numIterationTotal = 0; window_n=0; %contador de numero de ventanas
% conta=1;
% etiquetas_labels_predichas_matrix=strings(42,numEpochs*loops);
% countWins=0;countLoses=0;countWins2=0;countLoses2=0;number_classif_ok=0;number_classif_failed=0;epoch_counter=0;


%%
%LECTURA de EMGs -----------------------------------------

[Numero_Ventanas_GT,EMG_GT,Features_GT,Tiempos_GT,Puntos_GT,Usuario_GT,gestureName_GT,groundTruthIndex_GT,groundTruth_GT] ...
    = Code_1(orientation,dataPacketSize,RepTraining,RepTotalTraining);
assignin('base','Numero_Ventanas_GT',  Numero_Ventanas_GT);
Status = evalin('base', 'EMG_Activity');

%OBTENCION DE ESTADO (FEATURE VECTOR), OBSERVATION, Y AUMENTO VENTANA EN +1
LoggedSignals.State = table2array(Features_GT)';
Observation=LoggedSignals.State;

LoggedSignals.gestureName_GT=gestureName_GT;
LoggedSignals.groundTruth_GT=groundTruth_GT;
%%

% numIterationTotal = numIterationTotal + 1;

%         numIteration      = evalin('base', 'numIteration');
%         numIteration = numIteration + 1;
%         assignin('base','numIteration',numIteration);
%
%          stepNum = evalin('base', 'stepNum');
%          stepNum = stepNum + 1;
%          assignin('base','stepNum',stepNum);

%         %if strcmp(typeControl, 'AI')
%         [dummyVar, A] = forwardPropagation(state(:)', weights,...
%             transferFunctions, options);
%         Qval = A{end}(:, 2:end);
%         [dummyVar, action] = max(Qval);
%
%         acciones_predichas_vector(numIteration,1)=action;   % AQUI SE VAN GUARDADNO LAS ACCIONES PREDICHAS DENTRO DEl vector de UNA EPOCA


%
%         [Numero_Ventanas_GT,EMG_GT,Features_GT,Tiempos_GT,Puntos_GT,Usuario_GT,gestureName_GT,groundTruthIndex_GT,groundTruth_GT] = ...
%             Code_1(orientation,dataPacketSize,RepTraining,RepTotalTraining);
%
%
%         while Usuario_GT=="NaN"
%             if Usuario_GT~="NaN"
%                 break
%             end
%             [Numero_Ventanas_GT,EMG_GT,Features_GT,Tiempos_GT,Puntos_GT,Usuario_GT,gestureName_GT,groundTruthIndex_GT,groundTruth_GT] = ...
%                 Code_1(orientation,dataPacketSize,RepTraining,RepTotalTraining);
%         end
%
%         window_n=window_n+1; %window_n == 2 hasta window final
%
%         %---- Vectorizo datos necesarios de vectores de tiempos y de puntos de Ground truth -----------------*
%         %  if window_n==Numero_Ventanas_GT -> FIN DE JUEGO
if Window==Numero_Ventanas_GT%+1  %REV este +1  %window_n==Numero_Ventanas_GT
    %Vector_EMG_Tiempos_GT(1,window_n)=Tiempos_GT;  % al final tengo vector de tiempos ej: (1xNumero_Ventanas_GT) - ultima ventana
    LoggedSignals.Vector_EMG_Tiempos_GT(Window) = Tiempos_GT;
    %Vector_EMG_Puntos_GT(1,window_n)=Puntos_GT;    % al final tengo vector de puntos ej: (1xNumero_Ventanas_GT) - ultima ventana
    LoggedSignals.Vector_EMG_Puntos_GT(Window) = Puntos_GT;
    %fin_del_juego=1;                               % bandera fin de juego
    %window_n=0;                                    % reinicio cont ventana
    %disp('fin del juego')
else % EN ESTE ELSE se hace el barrido de ventanas, y se concatena datos en vectores
    %Vector_EMG_Tiempos_GT(1,window_n)=Tiempos_GT;  %dato escalar guardo en vector
    LoggedSignals.Vector_EMG_Tiempos_GT(Window) = Tiempos_GT;
    %Vector_EMG_Puntos_GT(1,window_n)=Puntos_GT;    %dato escalar guardo en vector
    LoggedSignals.Vector_EMG_Puntos_GT(Window) = Puntos_GT;
    %fin_del_juego=0;
end
%

%          new_state = table2array(Features_GT);
%
%         if numIteration==1
%             new_state_full=horzcat(new_state,prev_action_0);
%         elseif numIteration>1
%             new_state_full=horzcat(new_state,new_state_full(41:num_prev_actions*6+40));
%         end
%
%         %--------------feb--------------
%         %funcion concatena 'N=num_prev_actions' acciones pasadas predichas en vector de caracteristicas
%         new_state_full=action_despl(new_state_full,num_prev_actions,action);
%         disp('new_state_full');disp(new_state_full)
%         %------------------------------
%
%
%         %disp("etiquetas");disp(etiquetas);
%         %disp(size(etiquetas))
%         assignin('base','etiquetas',etiquetas);
%         %disp("numIteration");disp(numIteration);
%         assignin('base','numIteration',numIteration);
%         etiqueta_actual=etiquetas(numIteration,1);                           % ground truth de cada ventana EMG - CAMBIAR -
%         %disp("etiqueta_actual");disp(etiqueta_actual);
%         assignin('base','etiqueta_actual',etiqueta_actual);

%         acciones_predichas_actual=acciones_predichas_vector(numIteration,1); % accion predicha por ANN
LoggedSignals.acciones_predichas_vector(Window) = Action_data;
acciones_predichas_actual=LoggedSignals.acciones_predichas_vector(Window); % accion predicha por ANN
assignin('base','acciones_predichas_actual',acciones_predichas_actual);
etiqueta_actual=LoggedSignals.etiquetas(Window);
assignin('base','etiqueta_actual',etiqueta_actual);

if Reward_type ==true
    %disp('-1 reward')
    rewardC = getReward_emg(acciones_predichas_actual, etiqueta_actual); % AQUI HAY QUE DEFINIR RECOMPENSAS EN BASE A GROUNDTRUTH EMG
    LoggedSignals.Rewards_clasif(Window)=rewardC;
    if rewardC==+1
        LoggedSignals.number_classif_ok=LoggedSignals.number_classif_ok+1;
        number_classif_ok=LoggedSignals.number_classif_ok;
        assignin('base','number_classif_ok', number_classif_ok);
    else
        LoggedSignals.number_classif_failed=LoggedSignals.number_classif_failed+1;
        number_classif_failed=LoggedSignals.number_classif_failed;
        assignin('base','number_classif_failed', number_classif_failed);
    end
    %score = score + reward;
else
    %disp('0 reward')
    rewardC = getReward_emg_0reward(acciones_predichas_actual, etiqueta_actual);
    LoggedSignals.Rewards_clasif(Window)=rewardC;
    if rewardC==+1
        LoggedSignals.number_classif_ok=LoggedSignals.number_classif_ok+1;
        number_classif_ok=LoggedSignals.number_classif_ok;
        assignin('base','number_classif_ok', number_classif_ok);
    else
        LoggedSignals.number_classif_failed=LoggedSignals.number_classif_failed+1;
        number_classif_failed=LoggedSignals.number_classif_failed;
        assignin('base','number_classif_failed', number_classif_failed);
    end
    %score = score + reward;
end
%
%        if  acciones_predichas_actual ~= etiqueta_actual  %conteo de clasificaciones exitosas
%            countLoses2 = countLoses2 +1;
%            disp("countLoses2");disp(countLoses2);
%        else
%            countWins2 = countWins2 + 1;
%            disp("countWins2");disp(countWins2);
%        end
%
%         %     if strcmp(typeControl, 'AI')
%         %         displayWorld(new_state);
%         %     else
%         %         displayWorld(new_state, false);
%         %     end
%
%         %title(['Trial = ' num2str(stepNum) ' of ' num2str(maxNumSteps)]);
%         %pause(0.10);
%         %     if reward == +10
%         %         result = 1;
%         %         title('Game over: Your agent WON :)');
%         %         drawnow;
%         %         break;
%         %     elseif reward == -10
%         %         result = 0;
%         %         title('Game over: Your agent LOST :(');
%         %         drawnow;
%         %         break;
%         %     end
%         %     if stepNum >= maxNumSteps
%         %         result = 0;
%         %         title('Game over: Your agent LOST :(');
%         %         drawnow;
%         %         break;
%         %     end
%
%assignin('base','acciones_predichas_vector',acciones_predichas_vector);
% asigno a gesto --1 a 6-- una etiqueta categorica  %ESTO CAMBIAR - Etiquetas de PREDICCIONES
% class(etiquetas_labels_predichas_vector)
if acciones_predichas_actual == 1
    LoggedSignals.etiquetas_labels_predichas_vector(Window)="waveOut";
elseif acciones_predichas_actual == 2
    LoggedSignals.etiquetas_labels_predichas_vector(Window)="waveIn";        %CAMBIAR
elseif acciones_predichas_actual == 3
    LoggedSignals.etiquetas_labels_predichas_vector(Window)="fist" ;         %CAMBIAR
elseif acciones_predichas_actual == 4
    LoggedSignals.etiquetas_labels_predichas_vector(Window)="open";         %CAMBIAR
elseif acciones_predichas_actual == 5
    LoggedSignals.etiquetas_labels_predichas_vector(Window)="pinch" ;       %CAMBIAR
elseif acciones_predichas_actual == 6
    LoggedSignals.etiquetas_labels_predichas_vector(Window)="noGesture" ;        %CAMBIAR
end
%
%         %         disp('numIteration');disp(numIteration);
%         %         disp('Numero_Ventanas_GT-1');disp(Numero_Ventanas_GT-1);
%
%         %Acondicionar vectores - si el signo anterior no es igual al signo acual entocnes mido tiempo


if Window>=1 && Window~=Numero_Ventanas_GT  %&& ...                                                                    %numIteration~=maxWindowsAllowed
    %LoggedSignals.etiquetas_labels_predichas_vector(1,Window) ~= LoggedSignals.etiquetas_labels_predichas_vector(1,Window-1)
    
    %n1=n1+1;
    %ProcessingTimes_vector(1,n1) = toc;  %mido tiempo transcurrido desde ultimo cambio de gesto
    
    LoggedSignals.ProcessingTimes_vector(1,Window) = toc; %toc;  %mido tiempo transcurrido desde ultimo cambio de gesto
    
    
    %obtengo solo etiqueta que se ha venido repetiendo hasta instante numIteration-1
    %etiquetas_labels_predichas_vector_simplif(1,n1)=etiquetas_labels_predichas_vector(numIteration-1,1);
    LoggedSignals.etiquetas_labels_predichas_vector_simplif(1,Window)=LoggedSignals.etiquetas_labels_predichas_vector(1,Window); %(1,Window-1)
    
    %obtengo nuevo dato para vector de tiempos
    %TimePoints_vector(1,n1)=Stride*numIteration+EMG_window_size/2;           %necesito dato de stride y tamaño de ventana de Victor
    LoggedSignals.TimePoints_vector(1,Window)=Stride*Window+EMG_window_size/2;  %Window+1
%     disp('Vector de teimpos: Stride*Window+EMG_window_size/2')
%     disp(LoggedSignals.TimePoints_vector)
    
elseif Window== Numero_Ventanas_GT %==maxWindowsAllowed    % si proceso la ultima ventana de la muestra de señal EMG
    
    %disp('final window')
    
    %n1=n1+1;
    LoggedSignals.ProcessingTimes_vector(1,Window) = toc; %toc;  %mido tiempo transcurrido desde ultimo cambio de gesto
    
    
    %obtengo solo etiqueta que no se ha repetido hasta instante numIteration-1
    LoggedSignals.etiquetas_labels_predichas_vector_simplif(1,Window)=LoggedSignals.etiquetas_labels_predichas_vector(1,Window);
    
    %obtengo dato final para vector de tiempos
    %kj=size(LoggedSignals.groundTruth_GT);  %  se supone q son 1000 puntos
    LoggedSignals.TimePoints_vector(1,Window)= Stride*Window+EMG_window_size/2;% kj(1,2);
%     disp('Vector de teimpos: Stride*Window+EMG_window_size/2')
%     disp(LoggedSignals.TimePoints_vector)
%     assignin('base','TimePoints_vector_data', LoggedSignals.TimePoints_vector);
end

%         %Saco la moda de los gestos diferentes a NoGesture
temp1=(size(LoggedSignals.etiquetas_labels_predichas_vector));
temp1=temp1(1,2);
%
%         %disp('etiquetas_labels_predichas_vector')
%         %disp(etiquetas_labels_predichas_vector)
%         %saco no gesture de este vector para poder usar funcion moda
%         %-------- REVISAR-ESTO HABILITAR SI REQUIERO QUITAR NO GESTURE -----
for i=1:temp1 %ERROR size 15 y en otro lado size 16
    if LoggedSignals.etiquetas_labels_predichas_vector(1,i)~="noGesture"
        LoggedSignals.etiquetas_labels_predichas_vector_without_NoGesture(i,1)=LoggedSignals.etiquetas_labels_predichas_vector(1,i);
    else
        LoggedSignals.etiquetas_labels_predichas_vector_without_NoGesture(i,1)='';
    end
end
%disp('etiquetas_labels_predichas_vector_without_NoGesture')
%disp(etiquetas_labels_predichas_vector_without_NoGesture)

%dependiendo variable "noGestureDetection" Saco moda 1) sin considerar no gesto ,o 2) considerando no gesto
noGestureDetection   = evalin('base', 'noGestureDetection');
if noGestureDetection == false
    LoggedSignals.class_result=mode(categorical(LoggedSignals.etiquetas_labels_predichas_vector_without_NoGesture));  %Saco la moda de las etiquetas dif a no gesture
    disp('Etiquetas predichas')
    disp(categorical(LoggedSignals.etiquetas_labels_predichas_vector_without_NoGesture))
    disp('Resultado Moda')
    disp(LoggedSignals.class_result)
elseif noGestureDetection == true
    %Ojo que si hay muchos no gesto, la moda en este caso sale no gesto,
    %lo cual esta bien para las señales de no gesto. Pero para señales en
    %donde tengo por ejemplo 10 no gesto y 6 gestos, aca sigue saliendo la
    %moda. Problem solved en linea 421 (no lo resolví aca xq)
    LoggedSignals.class_result=mode(categorical(LoggedSignals.etiquetas_labels_predichas_vector));    %Saco moda incluyendo etiqueta de NoGesture
    
    %         elseif noGestureDetection == true && LoggedSignals.class_result~="noGesture"
    %             LoggedSignals.class_result=mode(categorical(LoggedSignals.etiquetas_labels_predichas_vector_without_NoGesture));    %Saco moda incluyendo etiqueta de NoGesture
    %             disp('Etiquetas predichas')
    %             disp(categorical(LoggedSignals.etiquetas_labels_predichas_vector))
    %             disp('Resultado Moda')
    %             disp(LoggedSignals.class_result)
end

%        %Si al sacar la moda todo es no gesto (<missing>), entonces la moda es no gesto
if ismissing(LoggedSignals.class_result)
    LoggedSignals.class_result="noGesture";
else
end

%esto es para guardar resultados de clasificacion
LoggedSignals.class_result_vector(1,LoggedSignals.conta)=string(LoggedSignals.class_result); %
assignin('base','class_result_vector', LoggedSignals.class_result_vector);

%disp(class_result)
%assignin('base','class_result_vector',class_result_vector);
% desde AQUI -------------------------------------------------------
%         Window<Numero_Ventanas_GT
%         disp("Numero_Ventanas_GT");disp(Numero_Ventanas_GT-1)
%         assignin('base','Numero_Ventanas_GT',Numero_Ventanas_GT-1);


if  Window==Numero_Ventanas_GT  % numIteration == Numero_Ventanas_GT -1 %==maxWindowsAllowed % reward == -10  end the game - lose
    %             %este lazo es para corregir el problema de que la moda
    %             cuando hay muchos no gestos sale "bogesto"
    %fd=ismissing(LoggedSignals.etiquetas_labels_predichas_vector_without_NoGesture);
    for i=1:temp1
        if LoggedSignals.etiquetas_labels_predichas_vector_without_NoGesture(i,1)==LoggedSignals.gestureName_GT   %fd(i,1)==1
            counter_gestos=counter_gestos+1; %cueta los no gestos en el vector
        else
        end
    end
    % hasta aqui esta ok
    if abs(counter_gestos-temp1)>3
        LoggedSignals.class_result=mode(categorical(LoggedSignals.etiquetas_labels_predichas_vector_without_NoGesture));
    else
        %El no gesto resultante de la moda sigue siendo no
        %gesto
    end
    disp('Etiquetas predichas')
    disp(categorical(LoggedSignals.etiquetas_labels_predichas_vector))
    disp('Resultado Moda')
    disp(LoggedSignals.class_result)
    %----------------------------------------------------------
    
    % %             %-----------check de las variables predichas que entran a eval de reconocimiento
    % %             %disp('etiquetas_labels_predichas_vector');
    % %             %disp(etiquetas_labels_predichas_vector); %[N,1] %vector Full
    % %             assignin('base','etiquetas_labels_predichas_vector',etiquetas_labels_predichas_vector);
    var1=size(LoggedSignals.etiquetas_labels_predichas_vector);
    var2=size(LoggedSignals.etiquetas_labels_predichas_matrix);
    %             %etiquetas_labels_predichas_matrix(:,conta)=etiquetas_labels_predichas_vector;
    %
    %             %Este lazo completa el vector etiquetas_labels_predichas_vector de ser neceario
    %             %, ya que tiene q coincidir con la
    %             %dimension del vector etiquetas_labels_predichas_matrix para poder imprimirlo en cvs
    for t1=var1(1,2)+1:var2(1,1)
        LoggedSignals.etiquetas_labels_predichas_vector(1,t1)=("N/A");
    end
    LoggedSignals.etiquetas_labels_predichas_matrix(:,LoggedSignals.conta)=LoggedSignals.etiquetas_labels_predichas_vector';
    
    %             assignin('base','etiquetas_labels_predichas_matrix',etiquetas_labels_predichas_matrix);
    %             %disp(etiquetas_labels_predichas_matrix)
    %
    LoggedSignals.etiquetas_GT_vector(1,LoggedSignals.conta)=string(LoggedSignals.gestureName_GT); %
    %             %disp(gestureName_GT)
    %             assignin('base','etiquetas_GT_vector',etiquetas_GT_vector);
    %             disp(etiquetas_GT_vector)
    %             %disp(etiquetas_labels_predichas_matrix)
    %
    
    %             %disp(conta)
    %             %disp('etiquetas_labels_predichas_vector_without_NoGesture');
    %             %disp(etiquetas_labels_predichas_vector_without_NoGesture); %[N,1] %vector Full
    %             assignin('base','etiquetas_labels_predichas_vector_without_NoGesture',etiquetas_labels_predichas_vector_without_NoGesture);
    %             %var2=size(etiquetas_labels_predichas_vector_without_NoGesture)
    %             %etiquetas_labels_predichas_matrix_without_NoGesture(:,conta)=etiquetas_labels_predichas_vector_without_NoGesture;
    %
    %
    %
    %             %disp('etiquetas_labels_predichas_vector_simplif');
    %             %disp(etiquetas_labels_predichas_vector_simplif);    % [1,N]  ok listo
    %             assignin('base','etiquetas_labels_predichas_vector_simplif',etiquetas_labels_predichas_vector_simplif);
    %             %size(etiquetas_labels_predichas_vector_simplif)
    %
    %             %disp('ProcessingTimes_vector');
    %             %disp(ProcessingTimes_vector);    %[1,N] ok listo
    %             assignin('base','ProcessingTimes_vector',ProcessingTimes_vector);
    %             %size(ProcessingTimes_vector)
    %
    %             %disp('TimePoints_vector');
    %             %disp(TimePoints_vector);         %[1,N] ok listo
    %             assignin('base','TimePoints_vector',TimePoints_vector);
    %             %size(TimePoints_vector)
    %
    %             %             disp('class_result');
    %             %             disp(class_result);              %[1,1] ok listo
    %             assignin('base','class_result',class_result);
    %             %size(class_result)
    %             %------------------------------------------------------------------
    %
    %             %---  POST - PROCESSING: elimino etiquetas espuria usando la
    %moda diferente de no gesto para crear vector de resultados que
    %va a la etaoa de reconocimiento
    LoggedSignals.post_processing_result_vector_lables=LoggedSignals.etiquetas_labels_predichas_vector_simplif;
    dim_vect=size(LoggedSignals.etiquetas_labels_predichas_vector_simplif);
    for i=1:dim_vect(1,2)
        if LoggedSignals.etiquetas_labels_predichas_vector_simplif(1,i) ~= LoggedSignals.class_result && LoggedSignals.etiquetas_labels_predichas_vector_simplif(1,i) ~= "noGesture"
            LoggedSignals.post_processing_result_vector_lables(1,i)=LoggedSignals.class_result;
        else
        end
    end
    %assignin('base','post_processing_result_vector_lables',post_processing_result_vector_lables);
    %             %-------------------------------------------------------------
    %
    %
    %             disp('Eval Recognition');
    %             % GROUND TRUTH (no depende del modelo)------------
    repInfo.gestureName =  LoggedSignals.gestureName_GT; % OK -----  categorical({'waveIn'});   %CAMBIAR - poner etiqueta de muestra de señal
    %assignin('base','gestureName_GT',gestureName_GT);
    repInfo.groundTruth = LoggedSignals.groundTruth_GT; %   REV -----
    %assignin('base','groundTruth_GT',groundTruth_GT);
    %assignin('base','repInfo',repInfo);
    %             %repInfo.groundTruth = false(1, 1000);   %Each_complete_signal;           %false(1, 1000);            %CAMBIAR
    %             %repInfo.groundTruth(800:1600) = true;   %CAMBIAR (64datos*40ventanas)
    %
    %             %plot(repInfo.groundTruth)
    %
    %             % PREDICCION--------------------------------------
    if post_processing == true
        response.vectorOfLabels = categorical(LoggedSignals.post_processing_result_vector_lables); % OK ----- [1,N] % categorical(etiquetas_labels_predichas_vector_simplif); % %CAMBIAR
%         disp('Post-Processing Vector of labels')
%         disp(categorical(LoggedSignals.post_processing_result_vector_lables))
    else
        response.vectorOfLabels = categorical(LoggedSignals.etiquetas_labels_predichas_vector_simplif); % OK ----- [1,N] % categorical(etiquetas_labels_predichas_vector_simplif); % %CAMBIAR
%         disp('Post-Processing Vector of labels')
%         disp(categorical(LoggedSignals.etiquetas_labels_predichas_vector_simplif))
    end
    %             %response.vectorOfLabels = categorical(etiquetas_labels_predichas_vector_simplif); % OK ----- [1,N] % categorical(etiquetas_labels_predichas_vector_simplif); % %CAMBIAR
    response.vectorOfTimePoints = LoggedSignals.TimePoints_vector; % OK -----  [40 200 400 600 800 999]; %1xw double  TimePoints_vector                %CAMBIAR
    %             % tiempo de procesamiento
    response.vectorOfProcessingTimes = LoggedSignals.ProcessingTimes_vector; % OK -----[0.1 0.1 0.1 0.1 0.1 0.1]; % ProcessingTimes_vector'; % [0.1 0.1 0.1 0.1 0.1 0.1]; % 1xw double                                    %CAMBIAR
    response.class =  categorical(LoggedSignals.class_result); % OK ----- categorical({'waveIn'});                %aqui tengo que usar la moda probablemente           %CAMBIAR
    %             assignin('base','response',response);
    %             %-----------------------------------------------
    %             %r1 = 1;
    %             %-------------SAVE DATA FOR TESTING---------------
    %LoggedSignals.conta2=LoggedSignals.conta-1;
    
    results_test_eval(LoggedSignals.conta).class=categorical(LoggedSignals.class_result);
    results_test_eval(LoggedSignals.conta).vectorOfTimePoints=LoggedSignals.TimePoints_vector;
    results_test_eval(LoggedSignals.conta).vectorOfProcessingTimes=LoggedSignals.ProcessingTimes_vector;
    
    if post_processing == true
        results_test_eval(LoggedSignals.conta).vectorOfLabels = categorical(LoggedSignals.post_processing_result_vector_lables); % OK ----- [1,N] % categorical(etiquetas_labels_predichas_vector_simplif); % %CAMBIAR
    else
        results_test_eval(LoggedSignals.conta).vectorOfLabels = categorical(LoggedSignals.ProcessingTimes_vector); % OK ----- [1,N] % categorical(etiquetas_labels_predichas_vector_simplif); % %CAMBIAR
    end
    cd ..
    cd ..
    cd('newDataTesting\results')
    assignin('base','results_test_evalxxx',results_test_eval);
    save results_test_evalxxx.mat results_test_eval
    %             %-------------------------------------------------
    %
    LoggedSignals.conta=LoggedSignals.conta+1;
    
    
    try
        r1 = evalRecognition(repInfo, response);
        disp(r1)
        LoggedSignals.recog_result=r1;
        fin_del_juego=1;
    catch
        warning('EL vector de predicciones esta compuesto por una misma etiqueta -> Func Eval Recog no funciona')
        r1.recogResult=0; fin_del_juego=1;
        if gestureName_GT==response.class
            r1.classResult=1;
        else
            r1.classResult=0;
        end
        
    end
    %
    %             %assignin('base','r1',r1);
    %
    if isempty(r1.recogResult) && fin_del_juego==1
        %Asigno recompensa en base al resultado de reconocimiento
        %disp('lazo1')
        %esto comentar si se requiere, solo si es no gesture se tiene esto
        if fin_del_juego==1 && LoggedSignals.gestureName_GT==categorical({'noGesture'}) && LoggedSignals.class_result~="noGesture" %numIteration == maxIterationsAllowed % reward == -10  end the game - lose
            %disp('lazo1-lost')
            %resultGame = 'lost';
            %disp('lost')
            %gameOn = false;
            LoggedSignals.Rewards_recog = -10;
            LoggedSignals.number_recog_failed=LoggedSignals.number_recog_failed+1;
            number_recog_failed=LoggedSignals.number_recog_failed;
            assignin('base','number_recog_failed', number_recog_failed);
        end
        % Suma_aciertos >= 30 &&
        if  fin_del_juego==1 && LoggedSignals.gestureName_GT==categorical({'noGesture'}) && LoggedSignals.class_result=="noGesture" % numIteration == maxIterationsAllowed % eward == +10   end the game - win
            %disp('lazo1-won')
            %resultGame = 'won ';
            %disp('won')
            %countWins = countWins + 1;
            %gameOn = false;
            LoggedSignals.Rewards_recog = +10;
            LoggedSignals.number_recog_ok=LoggedSignals.number_recog_ok+1;
            number_recog_ok=LoggedSignals.number_recog_ok;
            assignin('base','number_recog_ok', number_recog_ok);
        end
        
    else
        %disp('lazo2')
        if  r1.recogResult~=1 && fin_del_juego==1 %numIteration == maxIterationsAllowed % reward == -10  end the game - lose
            %                     resultGame = 'lost';
            %                     disp(resultGame)
            %                     gameOn = false;
            %                     countLoses = countLoses +1;
            LoggedSignals.Rewards_recog = -10;
            LoggedSignals.number_recog_failed=LoggedSignals.number_recog_failed+1;
            number_recog_failed=LoggedSignals.number_recog_failed;
            assignin('base','number_recog_failed', number_recog_failed);
            % Suma_aciertos >= 30 &&
        elseif  r1.recogResult==1 && fin_del_juego==1 % numIteration == maxIterationsAllowed % eward == +10   end the game - win
            %                     resultGame = 'won ';
            %                     disp(resultGame)
            %                     countWins = countWins + 1;
            %                     gameOn = false;
            LoggedSignals.Rewards_recog = +10;
            LoggedSignals.number_recog_ok=LoggedSignals.number_recog_ok+1;
            number_recog_ok=LoggedSignals.number_recog_ok;
            assignin('base','number_recog_ok', number_recog_ok);
        end
        %
    end
    %             score = score + reward;
    %             disp(score)
    %
end
%
%         % Cumulative reward
%         cumulativeGameReward = cumulativeGameReward + reward;

% Hasta aqui ------------------------------

%%
%REVISO SI FINALIZO EL JUEGO, Y ASIGNO RECOMPENSA

if Window<Numero_Ventanas_GT
    IsDone=false;
    Reward=LoggedSignals.Rewards_clasif(Window);
else
    IsDone=true;
    Reward=LoggedSignals.Rewards_recog+LoggedSignals.Rewards_clasif(Window);%esto %incluir si uso recog
    
    %Reward=LoggedSignals.Rewards_clasif(Window);
    %pause %ESTP COMENTAR DESPUES
    %[InitialObservation,LoggedSignals] = myResetFunctionTesting;  %ESTP COMENTAR DESPUES
end

% Get reward at the end of the episode.
% if ~IsDone
%     %Reward = RewardForNotFalling;
%     disp('1B')
% else
%     %Reward = PenaltyForFalling;
%     disp('1A')
% end

%%

% n1=size(LoggedSignals.class_result_vector);
%
% for nk=1:n1(1,2)
%     if LoggedSignals.etiquetas_GT_vector(1,nk)==LoggedSignals.class_result_vector(1,nk) % etiquetas_labels_predichas_matrix(1,nk)
%         number_classif_ok=number_classif_ok+1;
%     else
%         number_classif_failed=number_classif_failed+1;
%     end
% end
%disp('TESTING RESULTS')
%fprintf('Cumulative reward = %d/%d\n', score, numEpochs);
%fprintf('Count Wins = %d --- Count Loses = %d \n', countWins, countLoses);
%fprintf('Count Wins Recog = %d --- Count Loses recog = %d --- Total Recog = %d  \n', countWins, countLoses,countWins+countLoses);
%fprintf('Count Wins Classif = %d --- Count Loses classig = %d --- Total Classif = %d \n', number_classif_ok, number_classif_failed,number_classif_ok+number_classif_failed);
%fprintf('Count Wins per window = %d --- Count Loses per window = %d --- Total Classif per window = %d \n', countWins2, countLoses2,countWins2+countLoses2 );

%assignin('base','etiquetas_labels_predichas_matrixTEST',LoggedSignals.etiquetas_labels_predichas_matrix);
%cell2csv('new_cell2csvTEST.csv', etiquetas_labels_predichas_matrix)
%cell2csv('gestureName_GT_TEST.csv', etiquetas_GT_vector)
%Full_test_data=[LoggedSignals.etiquetas_labels_predichas_matrix;LoggedSignals.etiquetas_GT_vector;LoggedSignals.class_result_vector];
% assignin('base','Full_test_data',Full_test_data);
%cell2csv('Full_test_data.csv', Full_test_data)

%       s1 = 'Full_test_dataTRAINING_';
%       %s2   = '2';
%       s3 = '.csv';
%       s = strcat(s1,s2,s3);
%      sa   = evalin('base', 's');
%cell2csv(sa, Full_test_data)



%save results_test_eval.mat results_test_eval


end