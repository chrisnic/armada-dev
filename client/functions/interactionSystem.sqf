INT_ACTIONS_LIST = [  
	["T2_Door_Standard", 
		["OPEN", "B", 0, "Door_1_trigger"], 
		{ [(_this select 0), 1] execVM 'T2_Door_Standard\animateDoor.sqf'; }, 
		0, 
		{ (((_this select 0) animationPhase 'Door_1_slide') < 0.2) }
	],	
	["T2_Door_Standard", 
		["CLOSE", "B", 0, "Door_1_trigger"], 
		{ [(_this select 0), 0] execVM 'T2_Door_Standard\animateDoor.sqf'; }, 
		0, 
		{ (((_this select 0) animationPhase 'Door_1_slide') > 0.8) }
	],

	["T2_HangarDoor_L", 
		["OPEN", "B", 0, "Door_1_trigger"], 
		{ (_this select 0) ANIMATE ['Door_1_slide', 1]; }, 
		0, 
		{ (((_this select 0) animationPhase 'Door_1_slide') < 0.2) }
	],

	["T2_HangarDoor_L", 
		["CLOSE", "B", 0, "Door_1_trigger"], 
		{ (_this select 0) ANIMATE ['Door_1_slide', 0]; }, 
		0, 
		{ (((_this select 0) animationPhase 'Door_1_slide') > 0.8) }
	],

	["T2_Bulkhead_Turret_L", 
		["CLIMB", "B", 0.5, "Ladder_end_trigger"], 
		{  
			player action ['ladderDown', (_this select 0), 0, 1]; 
		}, 
		2.5, 
		{ !(["ladder", animationState player] call inString) }
	],

	["T2_Bulkhead_Turret_L", 
		["CLIMB", "B", 0.5, "Ladder_start_trigger"], 
		{  player action ['ladderUp', (_this select 0), 0, 0]; }, 
		2.5, 
		{ !(["ladder", animationState player] call inString) }
	],

	["T2_Airvent_Entry", 
		["OPEN", "B", 0.5, "Hatch_1_trigger"], 
		{  (_this select 0) animate ['Hatch_1_slide', 1]; (_this select 0) animate ['Hatch_1_rot_Y', random 0.25]; }, 
		0, 
		{ (((_this select 0) animationPhase 'Hatch_1_slide') < 0.2) }
	],

	["T2_Airvent_Entry", 
		["OPEN", "B", 0.5, "Hatch_2_trigger"], 
		{  (_this select 0) animate ['Hatch_2_slide', 1]; (_this select 0) animate ['Hatch_2_rot_Y', random 0.25]; }, 
		0, 
		{ (((_this select 0) animationPhase 'Hatch_2_slide') < 0.2) }
	],


	[["T2_CargoDoor_R", "T2_CargoDoor_L"], 
		["OPEN", "B", 0.5, "Door_1_trigger"], 
		{  [_this select 0, 1] execVM 'T2_CargoDoor\animateDoor.sqf'; }, 
		0, 
		{ (((_this select 0) animationPhase 'Door_1_rot') < 0.2) }
	],

	[["T2_BulkheadMid_Armory_R", "T2_BulkheadMid_Armory_L", "T2_BulkheadMid_Stairs_L", "T2_BulkheadMid_01"], 
		["OPEN", "B", 4, "Shield_1_trigger"], 
		{ (_this select 0) animate ['Shield_1_slide', 1]; }, 
		0, 
		{ (((_this select 0) animationPhase 'Shield_1_slide') < 0.2) }
	],

	[["T2_BulkheadMid_Armory_R", "T2_BulkheadMid_Armory_L", "T2_BulkheadMid_Stairs_L", "T2_BulkheadMid_01"], 
		["CLOSE", "B", 4, "Shield_1_trigger"], 
		{ (_this select 0) animate ['Shield_1_slide', 0]; }, 
		0, 
		{ (((_this select 0) animationPhase 'Shield_1_slide') > 0.8) }
	]



	
	
	// [cursorTarget, 
	// 	["TEST", "E", 3], 
	// 	{ hint 'test'; }, 
	// 	0, 
	// 	{ true }
	// ]
];

if (isNil "INT_ACTIONS_LIST") then {
	INT_ACTIONS_LIST = [];
};

INT_ACTIONS_ACTIVE = [];
INT_ACTIONS_FOCUS = [];
INT_ANIM_STATE = 0;


INT_minUpdateFrequency = 5;
INT_maxUpdateFrequency = 0.25;
INT_updateDistance = 1.5;
INT_updateAimpoint = 0.05;
INT_cooldown = false;

INT_lastUpdate = time - INT_minUpdateFrequency;

INT_lastPosition = [0,0,0];
INT_lastAimpoint = [0,0,0];

inGameUISetEventHandler['PrevAction', '[_this, "scroll"] call triggerUpdateActions; false'];
inGameUISetEventHandler['NextAction', '[_this, "scroll"] call triggerUpdateActions; false'];
inGameUISetEventHandler['Action', '[_this, "scroll"] call triggerUpdateActions; false'];

if (!isNil "DISPLAY_EH") then {	removeMissionEventHandler ["Draw3D", DISPLAY_EH]; DISPLAY_EH = nil; };
DISPLAY_EH = addMissionEventHandler ["Draw3D", {	
	
	if (count INT_ACTIONS_ACTIVE == 0 || INT_cooldown) exitWith { true };

	{	
		_p = (_x select 0) modelToWorldVisual (_x select 1);
		_f = (_x select 3);
		_c = if (_f) then { [0,1,0,1] } else { [1,0,0,1] };

		_tP = [_p, [0,-0.0825]] call screenOffsetPosition;
		_d = [(_p distance player), 0.1, 100] call limitToRange;
		_s = [1.9/_d, 1.4, 1.9] call limitToRange;
		_o = if (INT_ANIM_STATE > 0.5) then { 1 } else { ([(6/_d), 0.1, 1] call limitToRange) };

		_duration = (INT_ACTIONS_FOCUS select 1) select 2;
		_maxFrames = if (_duration > 0) then { 239 } else { 59 };
		_animSet = if (_duration > 0) then { "T2_Data\Animations\Hold\Hold_%1.paa" } else { "T2_Data\Animations\Press\Press_%1.paa" };
		_frameRef = [_maxFrames * INT_ANIM_STATE, 0] call roundTo;
		_animFrame = [ ([_frameRef,0,_maxFrames] call limitToRange), 5] call padZeros;

		drawIcon3D [format[_animSet, _animFrame],[1,1,1,(_o * .6)],_p,_s,_s,2, "", 0, 0.03, "PuristaMedium"];	

		if (_f) then {

			_key = if (_duration > 0 && INT_ANIM_STATE > 0) then { format['%1', [_duration - (INT_ANIM_STATE * _duration), 0] call roundTo] } else { ((INT_ACTIONS_FOCUS select 1) select 1) };
			drawIcon3D ["T2_Data\Images\blank.paa",[1,1,1,_o],_tP,1.8,1.8,2, _key, 0, 0.05, "PuristaMedium"];	

			_aP = [_p, [-0.065,-0.075]] call screenOffsetPosition;

			_text = if (_duration > 0 && INT_ANIM_STATE > 0) then { "HOLD" } else { ((INT_ACTIONS_FOCUS select 1) select 0) };
			drawIcon3D ["T2_Data\Images\blank.paa",[1,1,1,_o],_aP,1.8,1.8,2,_text, 0, 0.04, "PuristaMedium"];	
		};

	} foreach INT_ACTIONS_ACTIVE;

	true
}];


if (!isNil "INT_MM_EH") then { (findDisplay 46) displayRemoveEventHandler ["MouseMoving", INT_MM_EH]; };	
if (!isNil "INT_KD_EH") then { (findDisplay 46) displayRemoveEventHandler ["KeyDown", INT_KD_EH]; };	
if (!isNil "INT_KU_EH") then { (findDisplay 46) displayRemoveEventHandler ["KeyUp", INT_KU_EH]; };	

INT_MM_EH = (findDisplay 46) displayAddEventHandler ["MouseMoving", "[_this, 'mouse'] call triggerUpdateActions; false;"];
INT_KD_EH = (findDisplay 46) displayAddEventHandler ["KeyDown", "_this call onKeyDown; false;"];
INT_KU_EH = (findDisplay 46) displayAddEventHandler ["KeyUp", "_this call onKeyUp; false;"];

INT_KU = false;
INT_KD = false;

INT_LAST_OFFSET_POS = [0,0,0];

onKeyDown = {
	
	[_this, 'key'] call triggerUpdateActions;

	_pressedKey = _this select 1;
	INT_KD = TRUE;
	INT_KU = false;

	if (count INT_ACTIONS_FOCUS > 0) then {	
		
		_key = ((INT_ACTIONS_FOCUS select 1) select 1);
		_keyCode = _key call stringToCode;			

		if (_pressedKey == _keyCode) then {

			if  (INT_ANIM_STATE > 0) exitWith {};

			_duration = ((INT_ACTIONS_FOCUS select 1) select 2);
			if (_duration == 0) exitWith {};

			_obj = (INT_ACTIONS_FOCUS select 0);
			_action = (INT_ACTIONS_FOCUS select 2);
			[_obj, _duration, _action] spawn {
				_timeout = time + (_this select 1);
				_startTime = time;

				waitUntil {
					_timesince = time - _startTime;
					INT_ANIM_STATE = [_timesince / (_this select 1), 0, 1] call limitToRange;
					((time > _timeout) || (INT_KU))
				};		

				// Reset animation if press aborted
				[] spawn {
					Sleep 0.1;
					INT_ANIM_STATE = 0;
				};



				if (!INT_KU && INT_KD && !isNil "INT_ACTIONS_FOCUS" ) exitWith {

					if ((INT_ACTIONS_FOCUS select 0) != (_this select 0)) exitWith {};

					[(_this select 0)] call (_this select 2);

					[] spawn {
						INT_cooldown = true;
						Sleep 1.5;
						[nil, "manual"] call triggerUpdateActions;
						INT_cooldown = false;
						
					};
				};

				INT_ANIM_STATE = 0;
			};

		};

		if (_pressedKey != _keyCode) exitWith { false };
		if (INT_ANIM_STATE > 0 ) exitWith { false };

		[] spawn { 
			waitUntil {
				INT_ANIM_STATE = [(INT_ANIM_STATE + 0.03), 0, 1] call limitToRange;
				(INT_KU || !INT_KD)
			};
		};

	};

	TRUE
};

onKeyUp = {

	_pressedKey = _this select 1;
	INT_KD = false;
	INT_KU = true;

	if (count INT_ACTIONS_FOCUS > 0) then {

		INT_ANIM_STATE = 0;

		_key = ((INT_ACTIONS_FOCUS select 1) select 1);
		_keyCode = _key call stringToCode;
		
		if (_pressedKey == _keyCode) then {

			_duration = ((INT_ACTIONS_FOCUS select 1) select 2);

			if (_duration == 0) exitWith {
				_obj = (INT_ACTIONS_FOCUS select 0);
				_action = (INT_ACTIONS_FOCUS select 2);
				[_obj] call _action;	

				[] spawn {
					INT_cooldown = true;
					Sleep 1.5;
					[nil, "manual"] call triggerUpdateActions;
					INT_cooldown = false;

				};

				TRUE
			};			
		};
		
	};

	TRUE
};

screenOffsetPosition = {
	
	private ['_p', '_o', '_oX', '_oY'];

	_p = [_this, 0, [], [[]]] call filterParam;
	if (count _p == 0) exitWith { [0,0,0] };

	_o = [_this, 1, [0,0], [[]]] call filterParam;

	_oX = [_o, 0, 0, [0]] call filterParam;
	_oY = [_o, 1, 0, [0]] call filterParam;

	_terrain = terrainIntersect [positionCameraToWorld [0,0,2], positionCameraToWorld [0,0,2000]];
	if (!_terrain) exitWith { 
		(positionCameraToWorld [0,0,-10])
	};

	_nP = worldToScreen _p;

	if (count _nP == 0) exitWith { [0,0,0] };

	_nP set [0, (_nP select 0) + _oX];
	_nP set [1, (_nP select 1) + _oY];

	_stw = (screenToWorld _nP);

	INT_LAST_OFFSET_POS = _stw;

	_stw

};

triggerUpdateActions = {

	_timeDiff = time - INT_lastUpdate;

	if (_timeDiff > INT_minUpdateFrequency || (_this select 1) == "manual") exitWith { 
		INT_lastUpdate = time;
		
		[] call updateInteractions; 
		true
	};

	if (_timeDiff < INT_maxUpdateFrequency) exitWith { false };
	INT_lastUpdate = time;		
	
	// Global max update frequency
	_canTrigger = _this call {

		_triggerType = [_this, 1, "manual", [""]] call filterParam;

		// Manual trigger, just do it
		if (_triggerType == "manual") exitWith { true };

		_data = (_this select 0);

		if (_triggerType == "scroll") exitWith { true };

		// With keys, check for physical movement of player
		if (_triggerType == "key") exitWith {
			_key = _data select 1;

			_movementKeys = [];
			{
				_movementKeys append (actionKeys _x);
				false
			} count [
				"MoveForward",
				"MoveBack",
				"MoveLeft",
				"MoveRight",
				"EvasiveLeft",		
				"EvasiveRight",
				"TurnLeft",
				"TurnRight",
				"EvasiveBack"
			];

			// If we're not pressing a movement key, don't bother
			if !(_key in _movementKeys) exitWith { false };

			// Check we've moved a sufficient physical distance to trigger re-check
			_currentPos = (ASLtoATL visiblePositionASL player);
			if ((_currentPos distance INT_lastPosition) < INT_updateDistance) exitWith { false };
			INT_lastPosition = _currentPos;

			true
		};

		// With aim/mouse trigger, check we're aiming somewhere new
		if (_triggerType == "mouse") exitWith {

			_currentAim = [(_data select 1), (_data select 2), 0];
			_distanceMoved = (_currentAim distance INT_lastAimpoint);
			if ((_currentAim distance INT_lastAimpoint) < INT_updateAimpoint) exitWith { false };
			INT_lastAimpoint = _currentAim;

			true
		};

		true
	};


	if (!_canTrigger) exitWith {};

	[] call updateInteractions;

};

addInteraction = {
	
	INT_ACTIONS_LIST pushback _this;
};


findInteractableObjects = {
	
	private ['_nearbyObjects'];

	_nearbyObjects = [];

	// Find intersect from player POV
	_intersectingObjects = lineIntersectsWith [(ATLtoASL positionCameraToWorld [0,0,2]), (ATLtoASL positionCameraToWorld [0,0,15]), objNull, player, true];
	if (count _intersectingObjects > 0) then  { _nearbyObjects append _intersectingObjects; };

	_proximityObjects = nearestObjects [player, ["All"], 10];
	{

		_toDelete = false;
		_toDelete = if (_x == player) then { true } else { 

			if (_x isKindOf "Insect") exitWith { true };
			if (_x in _nearbyObjects) exitWith { true };

			_inScope = [player, _x, 45] call checkScope;
			if (!_inScope) exitWith { true };	
			false			
		};

		if (_toDelete) then { _proximityObjects deleteAt _forEachIndex; };

	} foreach _proximityObjects;
	_nearbyObjects append _proximityObjects;

	if (!isNull cursorTarget) then {
		if (cursorTarget in _nearbyObjects) exitWith {};
		_nearbyObjects pushback cursorTarget;
	};

	_nearbyObjects
};

updateInteractions = {
	
	INT_ACTIONS_ACTIVE = [];
	_maxVisibleTime = 2;
	_aimPointTolerance = 0.25;
	_nearbyObjects = [] call findInteractableObjects;

	_closestDistance = 9999;
	_focusID = 0;
	{
		_object = _x;
		_actionID = -1;
		_validActions = [];

		{
			_entry = _x select 0;
			_match = switch (typename _entry) do {
				case "OBJECT":
				{
					(_entry == _object)
				};

				case "STRING":
				{
					(_entry == (typeOf _object))
				};

				case "ARRAY":
				{
					({ if (_x == (typeOf _object)) exitWith { 1 }; false } count _entry > 0)
				};

				false
			};

			_valid = if (_match) then {

				_minDistance = (INT_ACTIONS_LIST select _forEachIndex) select 3;
				_offsetPosition = [((INT_ACTIONS_LIST select _forEachIndex) select 1), 3, [0,0,0], ["", []]] call filterParam; 
				_offset = switch (typename _offsetPosition) do {
					case "STRING":
					{
						(_object selectionPosition _offsetPosition)
					};
					case "ARRAY":
					{
						_offsetPosition
					};
					(boundingCenter _object)
				};

				_distance = player distance (_object modelToWorldVisual _offset);

				if (_minDistance != 0 && _distance > _minDistance) exitWith { false};

				_condition = (INT_ACTIONS_LIST select _forEachIndex) select 4;
				if !([_object] call _condition) exitWith { false };	

				true

			} else { 
				false 
			};

			if (_valid) then { _validActions pushback _forEachIndex; };
		} foreach INT_ACTIONS_LIST;

		if (count _validActions == 0) then {} else {		

			{
				_actionID = _x;

				_offset = [((INT_ACTIONS_LIST select _actionID) select 1), 3, [0,0,0], ["", []]] call filterParam; 
				_offset = switch (typename _offset) do {
					case "STRING":
					{
						(_object selectionPosition _offset)
					};
					case "ARRAY":
					{
						_offset
					};
					(boundingCenter _object)
				};

				_LOS = lineIntersectsWith [EYEpOS PLAYER, ATLtoASL (_object modelToWorldVisual _offset), _object, player];
				if (count _LOS > 0) then {} else { 			

					_screenPos = worldToScreen (_object modelToWorld _offset);
					_centrePos = worldToScreen (positionCameraToWorld [0,0,2]);

					_screenDist = if (count _screenPos  == 0) then { 9999999 } else { (_screenPos distance _centrePos) };
					if (_screenDist < _closestDistance) then { 
						_closestDistance = _screenDist;
						_focusID = (count INT_ACTIONS_ACTIVE);
					};

					INT_ACTIONS_ACTIVE pushback [_object, _offset, 0, false, _actionID];

				};

			} foreach _validActions;

		};

	} foreach _nearbyObjects;

	// Set the object that's the closest on the screen to focus
	if (count INT_ACTIONS_ACTIVE == 1) THEN { _focusID = 0; };
	(INT_ACTIONS_ACTIVE select _focusID) set [3,true];

	INT_ACTIONS_FOCUS = +(INT_ACTIONS_LIST select ((INT_ACTIONS_ACTIVE select _focusID) select 4));
	if (isNIl "INT_ACTIONS_FOCUS") exitWith {};		
	INT_ACTIONS_FOCUS set [0, (INT_ACTIONS_ACTIVE select _focusID) select 0];

	true 
};
