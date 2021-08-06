%Arduino Curise Control 

%%
% ThingSpeak IDs
Channel_ID= ;
API_ID= '';
%%
% Initialize Arduino uno
a = arduino('COM11','Uno','Libraries',{'Ultrasonic','ExampleLCD/LCDAddon'},'ForceBuildOn',true);
ultrasonicsensor = ultrasonic(a,'D11','D12','OutputFormat','double');
lcd = addon(a,'ExampleLCD/LCDAddon','RegisterSelectPin','D7','EnablePin','D6','DataPins',{'D5','D4','D3','D2'});
initializeLCD(lcd);

% Intialize values
B1=0; %set cruise button
B2=0; %adaptive cruise control button
B3=0; %cancel button
B4=0; %increase speed button
B5=0; %decrease speed button
speed=0;
trg=0;

% Open GUI panel for data
gui=uicontrol('Style','Pushbutton','String','Stop','Callback','delete(gcf)');
itr=1;
spedp=0;

while 1
    B1 = readVoltage(a,'A1');
    B2 = readVoltage(a,'A2');
    B3 = readVoltage(a,'A3');
    B4 = readVoltage(a,'A4');
    B5 = readVoltage(a,'A5');
    distance = readDistance(ultrasonicsensor);

    if trg==0 % when cruise control button is off
    if B4>=4.5
        speed=speed+2;
    elseif B5>=4.5
        speed=speed-2;
    else
        speed=speed-1;
    end
    
    elseif trg==1 % when cruise control button is on
        speed=speed;
        
    elseif trg==2 % when adaptive cruise control button is on
        if distance<0.2
            speed=speed-1;
        else
            speed=speed+1;
        end
        if speed>spdlim
            speed=spdlim;
        end
    end
    
    if B1>=4.5
        trg=1;
    elseif B2>=4.5
        trg=2;
        spdlim=speed;
    elseif B3>=4.5
        trg=0;
    elseif B4>=4.5 && trg~=2
        speed=speed+1;
    elseif B5>=4.5 && trg~=2
        speed=speed-1;
    end
    
    if speed<0
        speed=0;
    end
    
    % if Stop then break
    if ~ishandle(gui)
        break;
    end
    
% plot data
    data(itr)=speed;
    plot([itr-1 itr],[spedp data(itr)],'-b')
    title(['Speed: ',num2str(data(itr))])
    grid on
    hold on
    spedp=data(itr);
    
% Display Speed on LCD
    if trg==1
        printLCD(lcd,'Cruise On: ');
        printLCD(lcd,[strcat(num2str(round(speed)))]);
        
    elseif trg==2
        printLCD(lcd,'ACC On: ');
        printLCD(lcd,[strcat(num2str(round(speed)))]);
        pause(100/1000)
        clearLCD(lcd)
        pause(100/1000)
        printLCD(lcd,'ACC On: ');
        printLCD(lcd,[strcat(num2str(round(speed)))]);  
        
    else
    printLCD(lcd,'Speed: ');
    printLCD(lcd,[strcat(num2str(round(speed)))]);
    end
    
    itr=itr+1;
    
    if trg==2
        pause(300/1000)
    else
        pause(500/1000)
    end
    
end

%%
%upload to thingspeak channel
disp('Uploading to ThingSpeak...')
fprintf('Takes Approx. : %d min\n',floor(length(data))*15/60)
count=1;
for i=1:floor(length(data))
    response = thingSpeakWrite(Channel_ID,data(count),'WriteKey',API_ID);
    pause(15)
    count=count+1;
end

