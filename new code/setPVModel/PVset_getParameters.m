function Params = PVset_getParameters
% Select PV ID from LongPastData
Params.PV_ID = 1:27;

% Data set
Params.validDays = 30;  % it must be more than 1 day

% LSTM
Params.LSTMvalidDays = 3;

end